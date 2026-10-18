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
// starting_balance + income - expense + transfers in - transfers out).
//
// The per-account sums come from SQL (balance_queries.dart); this function
// is the only place they are combined. Nothing else in the app should
// compute a balance.
// ===========================================================================

/// The balance of one account, in paise:
/// starting + income - expense + transfersIn - transfersOut.
///
/// All sums are non-negative integer paise of that account's transactions
/// (a transfer counts as "out" for its FROM account and "in" for its TO
/// account). Integer arithmetic only.
int computeBalancePaise({
  required int startingBalancePaise,
  int incomePaise = 0,
  int expensePaise = 0,
  int transfersInPaise = 0,
  int transfersOutPaise = 0,
}) {
  return startingBalancePaise +
      incomePaise -
      expensePaise +
      transfersInPaise -
      transfersOutPaise;
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