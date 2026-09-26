import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';
import '../domain/category_kind.dart';
import '../domain/month_summary.dart'; // NEW

extension TransactionsDao on AppDatabase {
  Stream<List<TransactionRow>> watchTransactions(String userId, {String? accountId}) {
    final query = select(transactions)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]);
    if (accountId != null) {
      query.where((t) => t.accountId.equals(accountId));
    }
    return query.watch();
  }

  Future<void> insertTransaction({
    required String userId,
    required String accountId,
    required String categoryId,
    required int amountCents,
    required CategoryKind type,
    required String note,
    required DateTime occurredAt,
    required bool isRecurring,
  }) async {
    await into(transactions).insert(
      TransactionsCompanion.insert(
        id: generateId(),
        userId: userId,
        accountId: accountId,
        categoryId: categoryId,
        amountCents: amountCents,
        type: type.name,
        note: Value(note),
        occurredAt: occurredAt,
        isRecurring: Value(isRecurring),
      ),
    );
  }

  Future<void> updateTransaction({
    required String id,
    required String accountId,
    required String categoryId,
    required int amountCents,
    required CategoryKind type,
    required String note,
    required DateTime occurredAt,
    required bool isRecurring,
  }) {
    return (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        accountId: Value(accountId),
        categoryId: Value(categoryId),
        amountCents: Value(amountCents),
        type: Value(type.name),
        note: Value(note),
        occurredAt: Value(occurredAt),
        isRecurring: Value(isRecurring),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteTransaction(String id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  Future<int> countTransactionsForAccount(String accountId) async {
    final rows = await (select(transactions)..where((t) => t.accountId.equals(accountId))).get();
    return rows.length;
  }

  Future<int> countTransactionsForCategory(String categoryId) async {
    final rows = await (select(transactions)..where((t) => t.categoryId.equals(categoryId))).get();
    return rows.length;
  }
}

class AccountHasTransactionsException implements Exception {
  AccountHasTransactionsException(this.count);
  final int count;
}

class CategoryHasTransactionsException implements Exception {
  CategoryHasTransactionsException(this.count);
  final int count;
}

final transactionsProvider =
    StreamProvider.family<List<TransactionRow>, String?>((ref, accountId) async* {
  final db = ref.watch(appDatabaseProvider);
  final userId = await LocalUserId.get();
  yield* db.watchTransactions(userId, accountId: accountId);
});

final accountBalancesProvider = StreamProvider<Map<String, int>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final userId = await LocalUserId.get();
  await for (final txns in db.watchTransactions(userId)) {
    final sums = <String, int>{};
    for (final t in txns) {
      final signed = t.type == CategoryKind.income.name ? t.amountCents : -t.amountCents;
      sums[t.accountId] = (sums[t.accountId] ?? 0) + signed;
    }
    yield sums;
  }
});

/// NEW (Task 2.3). Key is (year, month) — a Dart record, which has
/// built-in structural equality, so Riverpod's `family` correctly
/// caches per-month rather than rebuilding every month's subscription
/// on every unrelated transaction change. Folds in Dart via
/// MonthSummary.fromTransactions, same "sum in Dart" convention as
/// accountBalancesProvider above.
final monthSummaryProvider =
    StreamProvider.family<MonthSummary, (int year, int month)>((ref, key) async* {
  final db = ref.watch(appDatabaseProvider);
  final userId = await LocalUserId.get();
  await for (final txns in db.watchTransactions(userId)) {
    yield MonthSummary.fromTransactions(txns, year: key.$1, month: key.$2);
  }
});