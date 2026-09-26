import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';
import '../domain/category_kind.dart';

extension TransactionsDao on AppDatabase {
  /// All of userId's transactions, optionally narrowed to one
  /// account, newest occurred_at first.
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

  /// Used by AccountsDao.deleteAccount to enforce the deletion-block
  /// decision (task response) — app-layer referential integrity, no
  /// DB-level FK.
  Future<int> countTransactionsForAccount(String accountId) async {
    final rows = await (select(transactions)..where((t) => t.accountId.equals(accountId))).get();
    return rows.length;
  }

  /// Used by CategoriesDao.deleteCategory, same reasoning.
  Future<int> countTransactionsForCategory(String categoryId) async {
    final rows = await (select(transactions)..where((t) => t.categoryId.equals(categoryId))).get();
    return rows.length;
  }
}

/// Thrown by AccountsDao.deleteAccount (accounts_dao.dart) when the
/// account still has transactions referencing it.
class AccountHasTransactionsException implements Exception {
  AccountHasTransactionsException(this.count);
  final int count;
}

/// Thrown by CategoriesDao.deleteCategory (categories_dao.dart) when
/// the category still has transactions referencing it.
class CategoryHasTransactionsException implements Exception {
  CategoryHasTransactionsException(this.count);
  final int count;
}

/// accountId == null -> all accounts, newest first.
final transactionsProvider =
    StreamProvider.family<List<TransactionRow>, String?>((ref, accountId) async* {
  final db = ref.watch(appDatabaseProvider);
  final userId = await LocalUserId.get();
  yield* db.watchTransactions(userId, accountId: accountId);
});

/// account_id -> net signed cents from that account's transactions
/// (+amount for income, -amount for expense). Combined with
/// Accounts.startingBalanceCents at render time — see task response
/// for why this folds in Dart rather than a SQL SUM.
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