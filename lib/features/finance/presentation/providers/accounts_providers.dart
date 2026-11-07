import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/db_provider.dart';
import '../../../../core/db/local_user_provider.dart';
import '../../data/account_balance.dart';
import '../../data/accounts_dao.dart';

/// The current user's accounts with computed balances, oldest first.
///
/// The stream is built from the AWAITED local user id and then re-emitted
/// with `yield*`, so it keeps emitting after later inserts and updates
/// (it is not a one-off read taken before the user id is known).
final accountsWithBalanceProvider = StreamProvider<List<AccountWithBalance>>((
  ref,
) async* {
  final db = ref.watch(appDatabaseProvider);
  final userId = await ref.watch(localUserIdProvider.future);
  yield* AccountsDao(db).watchAccountsWithBalance(userId);
});

/// Total Balance in paise: non-archived cash, bank, wallet and other
/// accounts only. Credit cards are excluded; see [creditCardDuesProvider].
final totalBalanceProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(accountsWithBalanceProvider).whenData(totalBalancePaise);
});

/// Credit-card dues in paise: what is owed, never negative. Non-archived
/// credit-card accounts only; an overpaid card adds nothing and never
/// offsets another card's debt. Shown separately from Total Balance.
final creditCardDuesProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(accountsWithBalanceProvider).whenData(creditCardDuesPaise);
});
