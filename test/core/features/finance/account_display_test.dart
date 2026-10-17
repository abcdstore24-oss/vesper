import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/presentation/account_display.dart';
import 'package:vesper/shared/widgets/amount_text.dart';

void main() {
  test('icon per account type', () {
    expect(accountTypeIcon(AccountType.cash), PhosphorIconsRegular.money);
    expect(accountTypeIcon(AccountType.bank), PhosphorIconsRegular.bank);
    expect(accountTypeIcon(AccountType.wallet), PhosphorIconsRegular.wallet);
    expect(
      accountTypeIcon(AccountType.creditCard),
      PhosphorIconsRegular.creditCard,
    );
    expect(accountTypeIcon(AccountType.other), PhosphorIconsRegular.coins);
  });

  test('every type has a distinct icon and a label', () {
    final icons = AccountType.values.map(accountTypeIcon).toSet();
    final labels = AccountType.values.map(accountTypeLabel).toSet();
    expect(icons, hasLength(AccountType.values.length));
    expect(labels, hasLength(AccountType.values.length));
    expect(accountTypeLabel(AccountType.creditCard), 'Credit card');
  });

  group('accountBalanceDisplay', () {
    test('card owing money shows a positive amount, danger, "due"', () {
      final d = accountBalanceDisplay(AccountType.creditCard, -120050);
      expect(d.paise, 120050);
      expect(d.tone, AmountTone.negative);
      expect(d.caption, 'due');
    });

    test('overpaid card shows positive, success, "credit"', () {
      final d = accountBalanceDisplay(AccountType.creditCard, 5000);
      expect(d.paise, 5000);
      expect(d.tone, AmountTone.positive);
      expect(d.caption, 'credit');
    });

    test('card at zero is neutral with no caption', () {
      final d = accountBalanceDisplay(AccountType.creditCard, 0);
      expect(d.paise, 0);
      expect(d.tone, AmountTone.neutral);
      expect(d.caption, isNull);
    });

    test('other types: neutral, negative keeps its sign in danger', () {
      for (final type in [
        AccountType.cash,
        AccountType.bank,
        AccountType.wallet,
        AccountType.other,
      ]) {
        final positive = accountBalanceDisplay(type, 125050);
        expect(positive.paise, 125050);
        expect(positive.tone, AmountTone.neutral);
        expect(positive.caption, isNull);

        final zero = accountBalanceDisplay(type, 0);
        expect(zero.tone, AmountTone.neutral);

        final negative = accountBalanceDisplay(type, -50000);
        expect(negative.paise, -50000);
        expect(negative.tone, AmountTone.negative);
        expect(negative.caption, isNull);
      }
    });
  });
}
