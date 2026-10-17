import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../shared/widgets/amount_text.dart';
import '../data/accounts_table.dart';

/// Pure display helpers for accounts (no BuildContext, no providers).

/// Phosphor (regular) icon for an account type.
IconData accountTypeIcon(AccountType type) {
  return switch (type) {
    AccountType.cash => PhosphorIconsRegular.money,
    AccountType.bank => PhosphorIconsRegular.bank,
    AccountType.wallet => PhosphorIconsRegular.wallet,
    AccountType.creditCard => PhosphorIconsRegular.creditCard,
    AccountType.other => PhosphorIconsRegular.coins,
  };
}

/// Human label for an account type.
String accountTypeLabel(AccountType type) {
  return switch (type) {
    AccountType.cash => 'Cash',
    AccountType.bank => 'Bank',
    AccountType.wallet => 'Wallet',
    AccountType.creditCard => 'Credit card',
    AccountType.other => 'Other',
  };
}

/// What an account row shows for its balance.
class AccountBalanceDisplay {
  const AccountBalanceDisplay({
    required this.paise,
    required this.tone,
    this.caption,
  });

  /// The amount to pass to AmountText.
  final int paise;
  final AmountTone tone;

  /// Small line under the amount ('due' / 'credit'); null for none.
  final String? caption;
}

/// Balance text/tone/caption for an account row.
///
/// Credit card: a negative balance is money owed, shown POSITIVE in the
/// danger tone with the caption 'due'; a positive balance is 'credit'
/// (success tone); zero is neutral with no caption.
/// Every other type: neutral, except a negative balance, which keeps its
/// minus sign in the danger tone.
AccountBalanceDisplay accountBalanceDisplay(
  AccountType type,
  int balancePaise,
) {
  if (type == AccountType.creditCard) {
    if (balancePaise < 0) {
      return AccountBalanceDisplay(
        paise: -balancePaise,
        tone: AmountTone.negative,
        caption: 'due',
      );
    }
    if (balancePaise > 0) {
      return AccountBalanceDisplay(
        paise: balancePaise,
        tone: AmountTone.positive,
        caption: 'credit',
      );
    }
    return const AccountBalanceDisplay(paise: 0, tone: AmountTone.neutral);
  }
  return AccountBalanceDisplay(
    paise: balancePaise,
    tone: balancePaise < 0 ? AmountTone.negative : AmountTone.neutral,
  );
}
