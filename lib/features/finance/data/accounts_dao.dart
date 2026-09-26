import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';
import '../domain/account_type.dart';
import 'transactions_dao.dart'; // NEW — countTransactionsForAccount + AccountHasTransactionsException

extension AccountsDao on AppDatabase {
  Stream<List<AccountRow>> watchAccounts(String userId) {
    return (select(accounts)
          ..where((a) => a.userId.equals(userId))
          ..orderBy([(a) => OrderingTerm.asc(a.name)]))
        .watch();
  }

  Future<void> insertAccount({
    required String userId,
    required String name,
    required AccountType type,
    required String currency,
    required int startingBalanceCents,
  }) async {
    await into(accounts).insert(
      AccountsCompanion.insert(
        id: generateId(),
        userId: userId,
        name: name,
        type: type.name,
        currency: currency,
        startingBalanceCents: Value(startingBalanceCents),
      ),
    );
  }

  Future<void> updateAccount({
    required String id,
    required String name,
    required AccountType type,
    required String currency,
    required int startingBalanceCents,
  }) {
    return (update(accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        name: Value(name),
        type: Value(type.name),
        currency: Value(currency),
        startingBalanceCents: Value(startingBalanceCents),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Blocks deletion if any transaction still references this account
  /// — throws AccountHasTransactionsException rather than deleting.
  /// See task response for the block-vs-orphan reasoning.
  Future<void> deleteAccount(String id) async {
    final count = await countTransactionsForAccount(id);
    if (count > 0) {
      throw AccountHasTransactionsException(count);
    }
    await (delete(accounts)..where((a) => a.id.equals(id))).go();
  }
}

final accountsProvider = StreamProvider<List<AccountRow>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final userId = await LocalUserId.get();
  yield* db.watchAccounts(userId);
});