import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';
import '../domain/investment_type.dart';
import 'investment_sales_dao.dart'; // NEW — countSalesForInvestment + InvestmentHasSalesException

extension InvestmentsDao on AppDatabase {
  Stream<List<InvestmentRow>> watchInvestments(String userId) {
    return (select(investments)
          ..where((i) => i.userId.equals(userId))
          ..orderBy([(i) => OrderingTerm.asc(i.name)]))
        .watch();
  }

  Future<void> insertInvestment({
    required String userId,
    required String name,
    required InvestmentType type,
    required double quantity,
    required int costBasisCents,
  }) async {
    final now = DateTime.now();
    await into(investments).insert(
      InvestmentsCompanion.insert(
        id: generateId(),
        userId: userId,
        name: name,
        type: type.name,
        quantity: quantity,
        costBasisCents: costBasisCents,
        currentValueCents: costBasisCents,
        lastUpdatedAt: now,
      ),
    );
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

  Future<void> updateCurrentValue({required String id, required int currentValueCents}) {
    final now = DateTime.now();
    return (update(investments)..where((i) => i.id.equals(id))).write(
      InvestmentsCompanion(
        currentValueCents: Value(currentValueCents),
        lastUpdatedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// Blocks deletion if sale history exists — required addition this
  /// task, same pattern as every other deletion rule.
  Future<void> deleteInvestment(String id) async {
    final saleCount = await countSalesForInvestment(id);
    if (saleCount > 0) {
      throw InvestmentHasSalesException(saleCount);
    }
    await (delete(investments)..where((i) => i.id.equals(id))).go();
  }
}

final investmentsProvider = StreamProvider<List<InvestmentRow>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final userId = await LocalUserId.get();
  yield* db.watchInvestments(userId);
});