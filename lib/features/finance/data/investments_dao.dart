import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';
import '../domain/category_kind.dart';
import '../domain/investment_type.dart';
import 'investment_sales_dao.dart';
import 'investment_snapshots_dao.dart';
import 'transactions_dao.dart';

extension InvestmentsDao on AppDatabase {
  Stream<List<InvestmentRow>> watchInvestments(String userId) {
    return (select(investments)
          ..where((i) => i.userId.equals(userId))
          ..orderBy([(i) => OrderingTerm.asc(i.name)]))
        .watch();
  }

  /// Shared by insertInvestment and buyMoreInvestment — creates an
  /// expense Transaction for a purchase iff both funding ids are
  /// provided; a no-op otherwise. Extracted this task so the two
  /// call sites don't duplicate the same branch (task response).
  Future<void> _maybeRecordFundingTransaction({
    required String userId,
    required String investmentName,
    required int amountCents,
    required String? fundingAccountId,
    required String? fundingCategoryId,
    required DateTime? fundingDate,
    required DateTime now,
  }) async {
    if (fundingAccountId == null || fundingCategoryId == null) return;
    await insertTransaction(
      userId: userId,
      accountId: fundingAccountId,
      categoryId: fundingCategoryId,
      amountCents: amountCents,
      type: CategoryKind.expense,
      note: 'Purchase: $investmentName',
      occurredAt: fundingDate ?? now,
      isRecurring: false,
    );
  }

  Future<void> insertInvestment({
    required String userId,
    required String name,
    required InvestmentType type,
    required double quantity,
    required int costBasisCents,
    String? fundingAccountId,
    String? fundingCategoryId,
    DateTime? fundingDate,
  }) async {
    final id = generateId();
    final now = DateTime.now();
    await transaction(() async {
      await into(investments).insert(
        InvestmentsCompanion.insert(
          id: id,
          userId: userId,
          name: name,
          type: type.name,
          quantity: quantity,
          costBasisCents: costBasisCents,
          currentValueCents: costBasisCents,
          lastUpdatedAt: now,
        ),
      );

      await _maybeRecordFundingTransaction(
        userId: userId,
        investmentName: name,
        amountCents: costBasisCents,
        fundingAccountId: fundingAccountId,
        fundingCategoryId: fundingCategoryId,
        fundingDate: fundingDate,
        now: now,
      );

      await recordInvestmentSnapshot(
        userId: userId,
        investmentId: id,
        valueCents: costBasisCents,
        recordedAt: now,
      );
    });
  }

  /// NEW this task — adds to an existing holding. Unlike Edit (which
  /// never touches current value, and would manufacture a fake loss
  /// if used for this — confirmed via on-device testing, per the task
  /// brief), the newly-bought portion is treated the same way a
  /// brand-new investment is: worth exactly what was paid for it
  /// until Update Value says otherwise. lastUpdatedAt DOES advance
  /// here (unlike a sale) — this is a genuine new valuation data
  /// point, since current value just changed.
  ///
  /// No quantity ceiling (unlike sellInvestment) — buying has no
  /// "remaining" resource to cap against, confirmed in plan.
  Future<void> buyMoreInvestment({
    required String userId,
    required InvestmentRow investment,
    required double quantityAdded,
    required int amountPaidCents,
    String? fundingAccountId,
    String? fundingCategoryId,
    DateTime? fundingDate,
  }) async {
    if (quantityAdded <= 0) {
      throw ArgumentError('quantityAdded must be greater than 0');
    }
    if (amountPaidCents < 0) {
      throw ArgumentError('amountPaidCents cannot be negative');
    }

    final now = DateTime.now();
    final newQuantity = investment.quantity + quantityAdded;
    final newCostBasisCents = investment.costBasisCents + amountPaidCents;
    final newCurrentValueCents = investment.currentValueCents + amountPaidCents;

    await transaction(() async {
      await (update(investments)..where((i) => i.id.equals(investment.id))).write(
        InvestmentsCompanion(
          quantity: Value(newQuantity),
          costBasisCents: Value(newCostBasisCents),
          currentValueCents: Value(newCurrentValueCents),
          lastUpdatedAt: Value(now), // ADVANCES here, unlike sellInvestment.
          updatedAt: Value(now),
        ),
      );

      await _maybeRecordFundingTransaction(
        userId: userId,
        investmentName: investment.name,
        amountCents: amountPaidCents,
        fundingAccountId: fundingAccountId,
        fundingCategoryId: fundingCategoryId,
        fundingDate: fundingDate,
        now: now,
      );

      await recordInvestmentSnapshot(
        userId: userId,
        investmentId: investment.id,
        valueCents: newCurrentValueCents,
        recordedAt: now,
      );
    });
  }

  Future<void> updateInvestmentDetails({
    required String id,
    required String name,
    required InvestmentType type,
    required double quantity,
    required int costBasisCents,
  }) {
    return (update(investments)..where((i) => i.id.equals(id))).write(
      InvestmentsCompanion(
        name: Value(name),
        type: Value(type.name),
        quantity: Value(quantity),
        costBasisCents: Value(costBasisCents),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateCurrentValue({
    required String userId,
    required String id,
    required int currentValueCents,
  }) async {
    final now = DateTime.now();
    await transaction(() async {
      await (update(investments)..where((i) => i.id.equals(id))).write(
        InvestmentsCompanion(
          currentValueCents: Value(currentValueCents),
          lastUpdatedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await recordInvestmentSnapshot(
        userId: userId,
        investmentId: id,
        valueCents: currentValueCents,
        recordedAt: now,
      );
    });
  }

  Future<void> deleteInvestment(String id) async {
    await transaction(() async {
      final saleCount = await countSalesForInvestment(id);
      if (saleCount > 0) {
        throw InvestmentHasSalesException(saleCount);
      }
      await (delete(investmentValueSnapshots)..where((s) => s.investmentId.equals(id))).go();
      await (delete(investments)..where((i) => i.id.equals(id))).go();
    });
  }
}

final investmentsProvider = StreamProvider<List<InvestmentRow>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final userId = await LocalUserId.get();
  yield* db.watchInvestments(userId);
});