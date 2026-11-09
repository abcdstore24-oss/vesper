import '../../../core/utils/money.dart';
import '../data/accounts_table.dart';
import '../data/transactions_table.dart';

/// An account as the delete confirmation describes it.
class DeleteImpactAccount {
  const DeleteImpactAccount(this.name, this.type);

  final String name;
  final AccountType type;
}

/// One line per affected account, describing how its balance changes when a
/// transaction is DELETED (the opposite of what the transaction did):
///
/// - expense: the account's balance goes up by the amount;
/// - income: the account's balance goes down by the amount;
/// - transfer: the From account goes up, the To account goes down.
///
/// A credit card shows what is owed, so its lines talk about the amount due:
/// a balance that goes up means the amount due goes down, and the other way
/// round. Names are passed through unchanged (the UI wraps long ones).
/// Amounts are formatted only by [Money]. A transfer without a [to] account
/// gives only the From line.
///
/// Pure: no BuildContext, no providers.
List<String> deleteImpactLines({
  required TransactionType type,
  required int amountPaise,
  required DeleteImpactAccount from,
  DeleteImpactAccount? to,
}) {
  final amount = Money.format(amountPaise);

  String line(DeleteImpactAccount account, {required bool balanceUp}) {
    if (account.type == AccountType.creditCard) {
      return '${account.name}: amount due goes ${balanceUp ? 'down' : 'up'} '
          'by $amount';
    }
    return '${account.name}: balance goes ${balanceUp ? 'up' : 'down'} '
        'by $amount';
  }

  return switch (type) {
    TransactionType.expense => [line(from, balanceUp: true)],
    TransactionType.income => [line(from, balanceUp: false)],
    TransactionType.transfer => [
      line(from, balanceUp: true),
      if (to != null) line(to, balanceUp: false),
    ],
  };
}
