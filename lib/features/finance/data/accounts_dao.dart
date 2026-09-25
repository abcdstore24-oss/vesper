import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';
import '../domain/account_type.dart';

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

  Future<void> deleteAccount(String id) {
    return (delete(accounts)..where((a) => a.id.equals(id))).go();
  }
}

final accountsProvider = StreamProvider<List<AccountRow>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final userId = await LocalUserId.get();
  yield* db.watchAccounts(userId);
});