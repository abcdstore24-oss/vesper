import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';
import '../domain/category_kind.dart';
import 'transactions_dao.dart'; // db.insertTransaction — see note below on the resulting circular import

// NOTE on the circular import: this file imports transactions_dao.dart
// (to call insertTransaction), and transactions_dao.dart imports this
// file back (for countSalesForTransaction + TransactionHasSaleException,
// to block deleteTransaction). Dart allows this — unlike some compiled
// languages, cross-file imports within one package don't need to be
// acyclic, since there's no top-level const evaluation depending on
// the cycle here, just extension methods and classes. Flagging
// explicitly rather than leaving it silently in place, since every
// other cross-DAO dependency in this project so far has been
// one-directional.

/// Tolerance for float-noise comparisons on Investments.quantity
/// (a double) — used for both "is this effectively a full sell"
/// (sellInvestment below) and "does quantitySold exceed remaining,
/// allowing for float noise at the exact boundary"
/// (sell_investment_sheet.dart's validator). Single shared constant
/// rather than the literal repeated in multiple files.
const investmentQuantityEpsilon = 1e-9;

extension InvestmentSalesDao on AppDatabase {
  Stream<List<InvestmentSaleRow>> watchSalesForInvestment(String userId, String investmentId) {
    return (select(investmentSales)
          ..where((s) => s.userId.equals(userId) & s.investmentId.equals(investmentId))
          ..orderBy([(s) => OrderingTerm.desc(s.soldAt)]))
        .watch();
  }

  /// Used by TransactionsDao.deleteTransaction (transactions_dao.dart)
  /// — required addition this task.
  Future<int> countSalesForTransaction(String transactionId) async {
    final rows = await (select(investmentSales)..where((s) => s.transactionId.equals(transactionId))).get();
    return rows.length;
  }

  /// Used by InvestmentsDao.deleteInvestment (investments_dao.dart).
  Future<int> countSalesForInvestment(String investmentId) async {
    final rows = await (select(investmentSales)..where((s) => s.investmentId.equals(investmentId))).get();
    return rows.length;
  }

  /// Sells [quantitySold] of [investment] for [proceedsCents], against
  /// [accountId]/[categoryId] (categoryId must be income-kind —
  /// enforced by sell_investment_sheet.dart's picker, not here).
  ///
  /// Rounding rule (task response, worked examples given in plan):
  /// round costBasisRemovedCents exactly once (nearest cent via a
  /// fraction of the pre-sale cost basis); the remaining cost basis is
  /// the ORIGINAL minus that already-rounded value, never a second
  /// independent round() — guarantees the two halves always sum back
  /// to the original exactly. A full sell (remaining quantity within
  /// epsilon of zero) is handled as an explicit special case that
  /// zeroes out exactly, rather than relying on fraction ≈ 1.0 to
  /// round cleanly.
  ///
  /// All three writes run inside db.transaction() — atomic, no
  /// partial application if any step fails.
  Future<void> sellInvestment({
    required String userId,
    required InvestmentRow investment,
    required double quantitySold,
    required int proceedsCents,
    required String accountId,
    required String categoryId,
    required DateTime soldAt,
  }) async {
    if (quantitySold <= 0) {
      throw ArgumentError('quantitySold must be greater than 0');
    }
    // Required addition #2: epsilon tolerance, not a strict <=.
    if (quantitySold > investment.quantity + investmentQuantityEpsilon) {
      throw ArgumentError('quantitySold exceeds remaining quantity');
    }

    final remaining = investment.quantity - quantitySold;
    final isFullSell = remaining <= investmentQuantityEpsilon;

    final int costBasisRemovedCents;
    final double newQuantity;
    final int newCostBasisCents;

    if (isFullSell) {
      costBasisRemovedCents = investment.costBasisCents;
      newQuantity = 0;
      newCostBasisCents = 0;
    } else {
      final fraction = quantitySold / investment.quantity;
      costBasisRemovedCents = (investment.costBasisCents * fraction).round();
      newQuantity = remaining;
      newCostBasisCents = investment.costBasisCents - costBasisRemovedCents;
    }

    final realizedGainCents = proceedsCents - costBasisRemovedCents;

    await transaction(() async {
      final transactionId = await insertTransaction(
        userId: userId,
        accountId: accountId,
        categoryId: categoryId,
        amountCents: proceedsCents,
        type: CategoryKind.income,
        note: 'Sale: ${investment.name}',
        occurredAt: soldAt,
        isRecurring: false,
      );

      final now = DateTime.now();
      await (update(investments)..where((i) => i.id.equals(investment.id))).write(
        InvestmentsCompanion(
          quantity: Value(newQuantity),
          costBasisCents: Value(newCostBasisCents),
          updatedAt: Value(now),
        ),
      );

      await into(investmentSales).insert(
        InvestmentSalesCompanion.insert(
          id: generateId(),
          userId: userId,
          investmentId: investment.id,
          quantitySold: quantitySold,
          proceedsCents: proceedsCents,
          realizedGainCents: realizedGainCents,
          soldAt: soldAt,
          transactionId: transactionId,
        ),
      );
    });
  }
}

/// Thrown by InvestmentsDao.deleteInvestment when sale history exists.
class InvestmentHasSalesException implements Exception {
  InvestmentHasSalesException(this.count);
  final int count;
}

/// Thrown by TransactionsDao.deleteTransaction when a sale still
/// references this transaction as its proceeds record — required
/// addition this task; nothing referenced a transaction before now.
class TransactionHasSaleException implements Exception {
  TransactionHasSaleException(this.count);
  final int count;
}

final investmentSalesProvider =
    StreamProvider.family<List<InvestmentSaleRow>, String>((ref, investmentId) async* {
  final db = ref.watch(appDatabaseProvider);
  final userId = await LocalUserId.get();
  yield* db.watchSalesForInvestment(userId, investmentId);
});