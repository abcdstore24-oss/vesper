import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';
import '../domain/category_kind.dart';
import '../domain/month_key.dart';
import 'transactions_dao.dart'; // NEW cross-DAO dependency — categorySpentProvider calls db.watchTransactions

extension BudgetsDao on AppDatabase {
  Stream<List<BudgetRow>> watchBudgets(String userId, String monthKey) {
    return (select(budgets)
          ..where((b) => b.userId.equals(userId) & b.month.equals(monthKey)))
        .watch();
  }

  Future<void> insertBudget({
    required String userId,
    required String categoryId,
    required String monthKey,
    required int limitAmountCents,
  }) async {
    await into(budgets).insert(
      BudgetsCompanion.insert(
        id: generateId(),
        userId: userId,
        categoryId: categoryId,
        month: monthKey,
        limitAmountCents: limitAmountCents,
      ),
    );
  }

  /// Only the limit is editable — category and month are locked after
  /// creation (task response: reassigning either mid-edit is a
  /// confusing operation, not exposed in the UI).
  Future<void> updateBudgetLimit({required String id, required int limitAmountCents}) {
    return (update(budgets)..where((b) => b.id.equals(id))).write(
      BudgetsCompanion(
        limitAmountCents: Value(limitAmountCents),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteBudget(String id) {
    return (delete(budgets)..where((b) => b.id.equals(id))).go();
  }

  /// Used by CategoriesDao.deleteCategory to extend the Task 2.2
  /// deletion-block pattern to budgets (task response — required
  /// addition this task).
  Future<int> countBudgetsForCategory(String categoryId) async {
    final rows = await (select(budgets)..where((b) => b.categoryId.equals(categoryId))).get();
    return rows.length;
  }

  /// If [monthKey] currently has zero budgets and the previous month
  /// has any, copies them forward as new rows (new id, new month,
  /// same category + limit) and returns the count copied — 0 if
  /// nothing was copied. A later call for the same now-populated
  /// month naturally returns 0, which is what prevents the UI's
  /// one-time SnackBar from repeating.
  Future<int> rolloverBudgetsIfEmpty(String userId, String monthKey) async {
    final current = await (select(budgets)
          ..where((b) => b.userId.equals(userId) & b.month.equals(monthKey)))
        .get();
    if (current.isNotEmpty) return 0;

    final prevKey = previousMonthKey(monthKey);
    final previous = await (select(budgets)
          ..where((b) => b.userId.equals(userId) & b.month.equals(prevKey)))
        .get();
    if (previous.isEmpty) return 0;

    await batch((b) {
      b.insertAll(budgets, [
        for (final row in previous)
          BudgetsCompanion.insert(
            id: generateId(),
            userId: userId,
            categoryId: row.categoryId,
            month: monthKey,
            limitAmountCents: row.limitAmountCents,
          ),
      ]);
    });

    return previous.length;
  }
}

/// Thrown by CategoriesDao.deleteCategory when the category still has
/// budgets referencing it — extends AccountHasTransactionsException /
/// CategoryHasTransactionsException's pattern (transactions_dao.dart)
/// to budgets.
class CategoryHasBudgetsException implements Exception {
  CategoryHasBudgetsException(this.count);
  final int count;
}

final budgetsProvider =
    StreamProvider.family<List<BudgetRow>, String>((ref, monthKey) async* {
  final db = ref.watch(appDatabaseProvider);
  final userId = await LocalUserId.get();
  yield* db.watchBudgets(userId, monthKey);
});

/// category_id -> total EXPENSE-type cents spent in [monthKey].
/// Deliberately NOT reusing MonthSummary.categoryTotals (Task 2.3) —
/// that nets income against expense per category, which is wrong for
/// "spent against a budget" (a budget only ever tracks expense-kind
/// categories). Same watch-and-fold-in-Dart approach, purpose-built
/// filter (task response).
final categorySpentProvider =
    StreamProvider.family<Map<String, int>, String>((ref, monthKey) async* {
  final db = ref.watch(appDatabaseProvider);
  final userId = await LocalUserId.get();
  final (year, month) = parseMonthKey(monthKey);
  final start = DateTime(year, month, 1);
  final end = DateTime(year, month + 1, 1); // auto-normalizes Dec -> Jan, same as MonthSummary

  await for (final txns in db.watchTransactions(userId)) {
    final sums = <String, int>{};
    for (final t in txns) {
      if (t.type != CategoryKind.expense.name) continue;
      if (t.occurredAt.isBefore(start) || !t.occurredAt.isBefore(end)) continue;
      sums[t.categoryId] = (sums[t.categoryId] ?? 0) + t.amountCents;
    }
    yield sums;
  }
});

/// Triggers rolloverBudgetsIfEmpty for [monthKey] and exposes the
/// copied count, so budgets_list_screen.dart can show a one-time
/// SnackBar via ref.listen without duplicating the rollover logic.
final budgetsRolloverProvider = FutureProvider.family<int, String>((ref, monthKey) async {
  final db = ref.watch(appDatabaseProvider);
  final userId = await LocalUserId.get();
  return db.rolloverBudgetsIfEmpty(userId, monthKey);
});