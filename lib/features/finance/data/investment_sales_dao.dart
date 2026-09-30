import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';
import '../domain/category_kind.dart';
import 'investment_snapshots_dao.dart'; // NEW — recordInvestmentSnapshot
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

  Future<int> countSalesForTransaction(String transactionId) async {
    final rows = await (select(investmentSales)..where((s) => s.transactionId.equals(transactionId))).get();
    return rows.length;
  }

  Future<int> countSalesForInvestment(String investmentId) async {
    final rows = await (select(investmentSales)..where((s) => s.investmentId.equals(investmentId))).get();
    return rows.length;
  }

  /// BUG FIX this task: previously reduced quantity and costBasisCents
  /// but never touched currentValueCents, so after any sale the tile's
  /// Gain/Loss and portfolio totals were overstated — the sold-off
  /// value stayed counted in current value while the proceeds ALSO
  /// landed in an account, double-counting money on a full sell.
  ///
  /// Fix mirrors the cost-basis reduction exactly: same fraction
  /// (quantitySold / quantity), round the removed amount once, get
  /// the remainder by subtraction (never a second round) — so
  /// currentValueRemovedCents + newCurrentValueCents always sums back
  /// to the original currentValueCents exactly, same guarantee the
  /// cost-basis math already had. Full sell zeroes current value
  /// exactly, same explicit-branch approach as cost basis, rather
  /// than trusting fraction ~= 1.0 to round cleanly.
  ///
  /// lastUpdatedAt is deliberately NOT touched by a sale — price per
  /// unit hasn't changed, so the "as of" date of the valuation isn't
  /// new information (task response). realizedGainCents math is
  /// unchanged: proceeds minus cost basis removed, nothing to do with
  /// current value.
  ///
  /// Also new this task: records a post-sale snapshot of the
  /// investment's new current value, ALWAYS at DateTime.now() (see
  /// InvestmentValueSnapshots.recordedAt's doc comment in
  /// app_database.dart for the backdated-sale limitation this
  /// implies) — inside this same db.transaction, so the sale, the
  /// investment update, and the snapshot all commit or fail together.
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
    if (quantitySold > investment.quantity + investmentQuantityEpsilon) {
      throw ArgumentError('quantitySold exceeds remaining quantity');
    }

    final remaining = investment.quantity - quantitySold;
    final isFullSell = remaining <= investmentQuantityEpsilon;

    final int costBasisRemovedCents;
    final int currentValueRemovedCents; // NEW
    final double newQuantity;
    final int newCostBasisCents;
    final int newCurrentValueCents; // NEW

    if (isFullSell) {
      costBasisRemovedCents = investment.costBasisCents;
      currentValueRemovedCents = investment.currentValueCents; // NEW
      newQuantity = 0;
      newCostBasisCents = 0;
      newCurrentValueCents = 0; // NEW
    } else {
      final fraction = quantitySold / investment.quantity;
      costBasisRemovedCents = (investment.costBasisCents * fraction).round();
      currentValueRemovedCents = (investment.currentValueCents * fraction).round(); // NEW — same fraction, own rounding
      newQuantity = remaining;
      newCostBasisCents = investment.costBasisCents - costBasisRemovedCents;
      newCurrentValueCents = investment.currentValueCents - currentValueRemovedCents; // NEW — subtraction, not a second round
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
          currentValueCents: Value(newCurrentValueCents), // NEW — the actual bug fix
          // lastUpdatedAt deliberately NOT written here — a sale isn't
          // a new valuation, per task response.
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

      // NEW — post-sale snapshot, same transaction, always "now".
      await recordInvestmentSnapshot(
        userId: userId,
        investmentId: investment.id,
        valueCents: newCurrentValueCents,
        recordedAt: now,
      );
    });
  }
}

class InvestmentHasSalesException implements Exception {
  InvestmentHasSalesException(this.count);
  final int count;
}

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