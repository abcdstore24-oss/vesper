import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/utils/money.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/presentation/account_delete_impact.dart';

void main() {
  List<String> lines(AccountType type, int start) =>
      deleteAccountImpactLines(type: type, startingBalancePaise: start);

  group('a zero starting balance', () {
    test('one line, for every type', () {
      for (final type in AccountType.values) {
        expect(lines(type, 0), [
          'It has no transactions and a zero starting balance.',
        ], reason: type.name);
      }
    });
  });

  group('a normal account with a starting balance', () {
    test('cash, bank, wallet and other: no longer counts in Total balance', () {
      for (final type in [
        AccountType.cash,
        AccountType.bank,
        AccountType.wallet,
        AccountType.other,
      ]) {
        expect(lines(type, 125050), [
          'It has no transactions.',
          'Its starting balance of \u20B91,250.50 will no longer count in '
              'Total balance.',
        ], reason: type.name);
      }
    });

    test('a negative starting balance keeps its minus sign', () {
      expect(lines(AccountType.bank, -5000), [
        'It has no transactions.',
        'Its starting balance of -\u20B950.00 will no longer count in '
            'Total balance.',
      ]);
    });
  });

  group('a credit card', () {
    test('a starting amount due no longer counts in Card dues', () {
      expect(lines(AccountType.creditCard, -125050), [
        'It has no transactions.',
        'Its starting amount due of \u20B91,250.50 will no longer count in '
            'Card dues.',
      ]);
    });

    test('a starting credit will no longer be counted', () {
      expect(lines(AccountType.creditCard, 5000), [
        'It has no transactions.',
        'Its starting credit of \u20B950.00 will no longer be counted.',
      ]);
    });
  });

  test('large amounts are formatted by Money', () {
    final big = lines(AccountType.bank, Money.maxPaise);
    expect(big.last, contains(Money.format(Money.maxPaise)));
    expect(big.last, contains('\u20B910,00,00,00,00,000.00'));

    final due = lines(AccountType.creditCard, -Money.maxPaise);
    expect(due.last, contains(Money.format(Money.maxPaise)));
  });
}
