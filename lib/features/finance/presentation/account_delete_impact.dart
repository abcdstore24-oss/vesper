import '../../../core/utils/money.dart';
import '../data/accounts_table.dart';

/// What deleting an account (one that has no transactions) makes disappear,
/// as lines for the confirmation dialog. [startingBalancePaise] is the
/// account's stored starting balance.
///
/// - zero: "It has no transactions and a zero starting balance."
/// - a normal account (cash, bank, wallet, other): its starting balance will
///   no longer count in Total balance (a negative one keeps its minus sign).
/// - a credit card: a negative start is an amount due that will no longer
///   count in Card dues; a positive one is a starting credit that will no
///   longer be counted (credit never counted in Card dues itself).
///
/// Amounts come only from [Money]. Pure: no BuildContext, no providers.
List<String> deleteAccountImpactLines({
  required AccountType type,
  required int startingBalancePaise,
}) {
  if (startingBalancePaise == 0) {
    return const ['It has no transactions and a zero starting balance.'];
  }

  final String effect;
  if (type == AccountType.creditCard) {
    effect = startingBalancePaise < 0
        ? 'Its starting amount due of '
              '${Money.format(-startingBalancePaise)} will no longer count in '
              'Card dues.'
        : 'Its starting credit of ${Money.format(startingBalancePaise)} will '
              'no longer be counted.';
  } else {
    effect =
        'Its starting balance of ${Money.format(startingBalancePaise)} will '
        'no longer count in Total balance.';
  }
  return ['It has no transactions.', effect];
}
