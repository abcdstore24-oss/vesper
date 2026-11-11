import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/db/db_provider.dart';
import '../../../../core/db/local_user_provider.dart';
import '../../data/categories_dao.dart';
import '../../data/categories_table.dart';
import '../../data/category_queries.dart';
import '../../data/transaction_queries.dart';
import '../../data/transactions_dao.dart';
import '../../data/transactions_table.dart';
import 'accounts_providers.dart';

/// The current user's most recent transactions (5), newest first, with the
/// names needed to describe them.
///
/// Built from the AWAITED local user id and then re-emitted with `yield*`,
/// exactly like accountsWithBalanceProvider, so it keeps emitting after
/// later inserts.
final recentTransactionsProvider = StreamProvider<List<TransactionListItem>>((
  ref,
) async* {
  final db = ref.watch(appDatabaseProvider);
  final userId = await ref.watch(localUserIdProvider.future);
  yield* TransactionsDao(db).watchRecent(userId);
});

/// ALL of the current user's transactions, newest first, optionally only one
/// [TransactionType] (the family key; null = All). The filter runs in SQL.
///
/// autoDispose: a stream over every row should not stay alive after the
/// Transactions screen (or the chip) is left. Same awaited-user pattern as
/// recentTransactionsProvider.
final allTransactionsProvider = StreamProvider.autoDispose
    .family<List<TransactionListItem>, TransactionType?>((ref, type) async* {
      final db = ref.watch(appDatabaseProvider);
      final userId = await ref.watch(localUserIdProvider.future);
      yield* TransactionsDao(db).watchAll(userId, type: type);
    });

/// The user's ACTIVE (non-archived) categories of a kind, A-Z by name.
final categoriesByKindProvider =
    StreamProvider.family<List<CategoryRow>, CategoryKind>((ref, kind) async* {
      final db = ref.watch(appDatabaseProvider);
      final userId = await ref.watch(localUserIdProvider.future);
      yield* CategoriesDao(db).watchByKind(userId, kind);
    });

/// ALL of the user's categories of a kind (expense or income), archived ones
/// included, for the Categories management screen. autoDispose: it lives only
/// while that screen is open. The active-only [categoriesByKindProvider] is
/// unchanged.
final manageCategoriesProvider = StreamProvider.autoDispose
    .family<List<CategoryRow>, CategoryKind>((ref, kind) async* {
      assert(kind != CategoryKind.system, 'system categories are not managed');
      final db = ref.watch(appDatabaseProvider);
      final userId = await ref.watch(localUserIdProvider.future);
      yield* CategoriesDao(db).watchByKind(userId, kind, includeArchived: true);
    });

/// Up to 5 of the user's most recently USED active categories of a kind
/// (newest use first), for the one-tap "Recent" chips in the add sheet.
/// Re-emits when transactions or categories change.
final recentCategoriesProvider =
    StreamProvider.family<List<CategoryRow>, CategoryKind>((ref, kind) async* {
      final db = ref.watch(appDatabaseProvider);
      final userId = await ref.watch(localUserIdProvider.future);
      yield* selectRecentCategories(db, userId: userId, kind: kind).watch();
    });

/// The user's non-archived accounts, oldest first, then by name.
final activeAccountsProvider = Provider<AsyncValue<List<AccountRow>>>((ref) {
  return ref
      .watch(accountsWithBalanceProvider)
      .whenData(
        (list) => [
          for (final a in list)
            if (!a.account.isArchived) a.account,
        ],
      );
});
