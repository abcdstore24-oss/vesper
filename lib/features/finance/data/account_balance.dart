import '../../../core/db/app_database.dart';
import 'accounts_table.dart';

/// An account together with its computed balance, in paise.
class AccountWithBalance {
  const AccountWithBalance({required this.account, required this.balancePaise});

  final AccountRow account;
  final int balancePaise;
}

// ===========================================================================
// BALANCE CALCULATION — the ONE place an account balance is computed.
//
// A balance is ALWAYS computed, never stored (DECISIONS.md: balance =
// starting_balance + income - expense +/- transfers).
//
// TODO(Task 4): transactions don't exist yet, so today the balance is just
// the starting balance. When the transactions table lands, add the
// per-account sums (income, expense, transfers in/out) as extra named
// parameters HERE and fold them into the result. Nothing else in the app
// should compute a balance.
// ===========================================================================
int computeBalancePaise({required int startingBalancePaise}) {
  return startingBalancePaise;
}

/// TOTAL BALANCE: the sum of the balances of every NON-archived account
/// of type cash, bank, wallet or other, in paise.
///
/// Credit-card accounts are NOT part of Total Balance (owner decision);
/// they are reported separately as card dues, see [creditCardDuesPaise].
/// Archived accounts never count. An empty list gives 0. Integer
/// arithmetic only.
int totalBalancePaise(Iterable<AccountWithBalance> accounts) {
  var total = 0;
  for (final a in accounts) {
    if (a.account.isArchived) continue;
    if (a.account.type == AccountType.creditCard) continue;
    total += a.balancePaise;
  }
  return total;
}

/// CARD DUES: what is owed on credit cards, in paise. Never negative.
///
/// For every NON-archived credit-card account, add what is owed on it,
/// max(0, -balance). A card's balance is negative when money is owed. A
/// card that is paid up or overpaid (balance >= 0) adds nothing, and its
/// credit does NOT reduce what other cards owe: dues are never netted
/// across cards. An overpaid card's credit belongs on that card's own row,
/// not here. An empty list, or no active card, gives 0. Integer
/// arithmetic only.
int creditCardDuesPaise(Iterable<AccountWithBalance> accounts) {
  var dues = 0;
  for (final a in accounts) {
    if (a.account.isArchived) continue;
    if (a.account.type != AccountType.creditCard) continue;
    if (a.balancePaise < 0) dues += -a.balancePaise;
  }
  return dues;
}