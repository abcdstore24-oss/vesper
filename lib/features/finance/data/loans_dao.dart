import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';
import '../domain/category_kind.dart';
import '../domain/loan_activity_type.dart';
import '../domain/loan_direction.dart';
import 'transactions_dao.dart'; // insertTransaction

extension LoansDao on AppDatabase {
  Stream<List<LoanRow>> watchLoans(String userId) {
    return (select(loans)
          ..where((l) => l.userId.equals(userId))
          ..orderBy([
            (l) => OrderingTerm.asc(l.isSettled),
            (l) => OrderingTerm.desc(l.date),
          ]))
        .watch();
  }

    /// CHANGED this task: gains optional funding (mirrors
  /// insertInvestment exactly) and a required includeInNetWorth flag.
  /// Funding transaction type comes from the CHOSEN category's kind,
  /// never assumed from direction. Deliberately creates NO
  /// loan_activities row — this is the starting baseline, same as
  /// insertInvestment's funding transaction never touching
  /// investment_sales (task response).
  Future<void> insertLoan({
    required String userId,
    required String personName,
    required LoanDirection direction,
    required int principalCents,
    required String note,
    required DateTime date,
    required bool includeInNetWorth,
    String? fundingAccountId,
    String? fundingCategoryId,
    DateTime? fundingDate,
  }) async {
    final id = generateId();

    await transaction(() async {
      await into(loans).insert(
        LoansCompanion.insert(
          id: id,
          userId: userId,
          personName: personName,
          direction: direction.name,
          principalCents: principalCents,
          outstandingCents: principalCents,
          note: Value(note),
          date: date,
          includeInNetWorth: Value(includeInNetWorth),
        ),
      );

      if (fundingAccountId != null && fundingCategoryId != null) {
        final category = await (select(categories)..where((c) => c.id.equals(fundingCategoryId))).getSingle();
        final kind = CategoryKind.values.byName(category.kind);
        await insertTransaction(
          userId: userId,
          accountId: fundingAccountId,
          categoryId: fundingCategoryId,
          amountCents: principalCents,
          type: kind,
          note: '${direction == LoanDirection.lent ? 'Loan to' : 'Loan from'} $personName',
          occurredAt: fundingDate ?? date,
          isRecurring: false,
        );
      }
    });
  }

  /// CHANGED this task. The UI lock is no longer the only guard:
  /// everything is re-read inside ONE transaction, so a stale sheet
  /// can't write past a lock that has since engaged.
  ///
  /// - Direction is immutable: the parameter is removed and it is
  ///   never written.
  /// - principal/outstanding are written only when the loan has ZERO
  ///   loan_activities rows (outstanding is reset to the new principal,
  ///   as before). With any activity both are left untouched
  ///   (Value.absent()), whatever the caller passed.
  /// - includeInNetWorth is forced true when the stored direction is
  ///   borrowed, read from the freshly re-selected row, not from
  ///   anything the form passed.
  Future<void> updateLoan({
    required String id,
    required String personName,
    required int principalCents,
    required String note,
    required DateTime date,
    required bool includeInNetWorth,
  }) async {
    await transaction(() async {
      final current = await (select(loans)..where((l) => l.id.equals(id))).getSingleOrNull();
      if (current == null) return;

      final hasActivity = (await countActivitiesForLoan(id)) > 0;
      final isBorrowed = current.direction == LoanDirection.borrowed.name;

      await (update(loans)..where((l) => l.id.equals(id))).write(
        LoansCompanion(
          personName: Value(personName),
          principalCents: hasActivity ? const Value.absent() : Value(principalCents),
          outstandingCents: hasActivity ? const Value.absent() : Value(principalCents),
          note: Value(note),
          date: Value(date),
          includeInNetWorth: Value(isBorrowed ? true : includeInNetWorth),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

    Future<void> addToLoan({
    required String userId,
    required LoanRow loan,
    required int amountCents,
    String? fundingAccountId,
    String? fundingCategoryId,
    DateTime? fundingDate,
  }) async {
    if (amountCents <= 0) {
      throw ArgumentError('amountCents must be greater than 0');
    }

    final now = DateTime.now();

    await transaction(() async {
      // First statement: re-select. The `loan` argument may be stale
      // (captured when the sheet opened), same class of bug as the
      // Recurring race fix.
      final fresh = await (select(loans)..where((l) => l.id.equals(loan.id))).getSingleOrNull();
      if (fresh == null) return;

      final direction = LoanDirection.values.byName(fresh.direction);
      final newOutstanding = fresh.outstandingCents + amountCents;

      await (update(loans)..where((l) => l.id.equals(fresh.id))).write(
        LoansCompanion(
          outstandingCents: Value(newOutstanding),
          isSettled: const Value(false), // NEW: Add more reopens a settled loan (newOutstanding is always > 0 here)
          updatedAt: Value(now),
        ),
      );

      String? transactionId;
      if (fundingAccountId != null && fundingCategoryId != null) {
        final category = await (select(categories)..where((c) => c.id.equals(fundingCategoryId))).getSingle();
        final kind = CategoryKind.values.byName(category.kind);
        transactionId = await insertTransaction(
          userId: userId,
          accountId: fundingAccountId,
          categoryId: fundingCategoryId,
          amountCents: amountCents,
          type: kind,
          note: '${direction == LoanDirection.lent ? 'Loan to' : 'Loan from'} ${fresh.personName}',
          occurredAt: fundingDate ?? now,
          isRecurring: false,
        );
      }

      await into(loanActivities).insert(
        LoanActivitiesCompanion.insert(
          id: generateId(),
          userId: userId,
          loanId: fresh.id,
          activityType: LoanActivityType.increase.name,
          amountCents: amountCents,
          date: fundingDate ?? now,
          transactionId: Value(transactionId),
        ),
      );
    });
  }

  Future<void> repayLoan({
    required String userId,
    required LoanRow loan,
    required int amountCents,
    String? fundingAccountId,
    String? fundingCategoryId,
    DateTime? fundingDate,
  }) async {
    if (amountCents <= 0) {
      throw ArgumentError('amountCents must be greater than 0');
    }

    final now = DateTime.now();

    await transaction(() async {
      final fresh = await (select(loans)..where((l) => l.id.equals(loan.id))).getSingleOrNull();
      if (fresh == null) return;

      // Ceiling check against the FRESH outstanding, not the row the
      // sheet captured. Still a hard rejection, never a clamp. The
      // throw rolls the transaction back; callers see the same
      // ArgumentError as before.
      if (amountCents > fresh.outstandingCents) {
        throw ArgumentError('amountCents exceeds outstanding balance');
      }

      final direction = LoanDirection.values.byName(fresh.direction);
      final newOutstanding = fresh.outstandingCents - amountCents;
      final settled = newOutstanding == 0;

      await (update(loans)..where((l) => l.id.equals(fresh.id))).write(
        LoansCompanion(
          outstandingCents: Value(newOutstanding),
          isSettled: Value(settled),
          updatedAt: Value(now),
        ),
      );

      String? transactionId;
      if (fundingAccountId != null && fundingCategoryId != null) {
        final category = await (select(categories)..where((c) => c.id.equals(fundingCategoryId))).getSingle();
        final kind = CategoryKind.values.byName(category.kind);
        transactionId = await insertTransaction(
          userId: userId,
          accountId: fundingAccountId,
          categoryId: fundingCategoryId,
          amountCents: amountCents,
          type: kind,
          note: '${direction == LoanDirection.lent ? 'Repayment from' : 'Repayment to'} ${fresh.personName}',
          occurredAt: fundingDate ?? now,
          isRecurring: false,
        );
      }

      await into(loanActivities).insert(
        LoanActivitiesCompanion.insert(
          id: generateId(),
          userId: userId,
          loanId: fresh.id,
          activityType: LoanActivityType.repayment.name,
          amountCents: amountCents,
          date: fundingDate ?? now,
          transactionId: Value(transactionId),
        ),
      );
    });
  }

  /// NEW this task — the authoritative "does this loan have real
  /// activity" source of truth, replacing Part 1's state-based
  /// inference everywhere it was used (task response: a count is
  /// strictly more robust than inferring from field state).
  Future<int> countActivitiesForLoan(String loanId) async {
    final rows = await (select(loanActivities)..where((a) => a.loanId.equals(loanId))).get();
    return rows.length;
  }

  /// CHANGED this task: switched from the Part 1 state-based check
  /// (outstanding != principal || isSettled) to a real count against
  /// loan_activities — same pattern every other deletion-blocking
  /// check in this project already uses (task response).
  Future<void> deleteLoan(String id) async {
    final loan = await (select(loans)..where((l) => l.id.equals(id))).getSingleOrNull();
    if (loan == null) return;
    final activityCount = await countActivitiesForLoan(id);
    if (activityCount > 0) {
      throw LoanHasActivityException(activityCount);
    }
    await (delete(loans)..where((l) => l.id.equals(id))).go();
  }
}

/// CHANGED this task: now carries a count, matching every other
/// deletion-blocking exception in this project (was count-less in
/// Part 1, since nothing was countable yet).
class LoanHasActivityException implements Exception {
  LoanHasActivityException(this.count);
  final int count;
}

final loansProvider = StreamProvider<List<LoanRow>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final userId = await LocalUserId.get();
  yield* db.watchLoans(userId);
});

/// CHANGED this task: autoDispose, so the count is recomputed each
/// time a sheet watching it opens. Previously a plain
/// FutureProvider.family cached the first result for the whole
/// session: Edit opened before any activity cached 0, and the
/// principal stayed editable after a repayment.
final loanActivityCountProvider = FutureProvider.autoDispose.family<int, String>((ref, loanId) async {
  final db = ref.watch(appDatabaseProvider);
  return db.countActivitiesForLoan(loanId);
});