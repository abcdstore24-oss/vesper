import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/utils/money.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/data/transactions_table.dart';
import 'package:vesper/features/finance/presentation/transaction_delete_impact.dart';

void main() {
  const bank = DeleteImpactAccount('Main bank', AccountType.bank);
  const cash = DeleteImpactAccount('Wallet cash', AccountType.cash);
  const card = DeleteImpactAccount('Visa', AccountType.creditCard);

  List<String> lines(
    TransactionType type,
    DeleteImpactAccount from, {
    DeleteImpactAccount? to,
    int paise = 125050,
  }) => deleteImpactLines(type: type, amountPaise: paise, from: from, to: to);

  group('normal accounts', () {
    test('deleting an expense raises the balance', () {
      expect(lines(TransactionType.expense, bank), [
        'Main bank: balance goes up by \u20B91,250.50',
      ]);
    });

    test('deleting an income lowers the balance', () {
      expect(lines(TransactionType.income, bank), [
        'Main bank: balance goes down by \u20B91,250.50',
      ]);
    });

    test('deleting a transfer: From goes up, To goes down', () {
      expect(lines(TransactionType.transfer, bank, to: cash), [
        'Main bank: balance goes up by \u20B91,250.50',
        'Wallet cash: balance goes down by \u20B91,250.50',
      ]);
    });

    test('every non-card type uses the "balance" wording', () {
      for (final type in [
        AccountType.cash,
        AccountType.bank,
        AccountType.wallet,
        AccountType.other,
      ]) {
        final text = lines(
          TransactionType.expense,
          DeleteImpactAccount('A', type),
        ).single;
        expect(text, 'A: balance goes up by \u20B91,250.50');
      }
    });
  });

  group('credit card accounts (amount due)', () {
    test('deleting an expense on a card lowers the amount due', () {
      expect(lines(TransactionType.expense, card), [
        'Visa: amount due goes down by \u20B91,250.50',
      ]);
    });

    test('deleting an income on a card raises the amount due', () {
      expect(lines(TransactionType.income, card), [
        'Visa: amount due goes up by \u20B91,250.50',
      ]);
    });

    test('a transfer FROM a card: the amount due goes down', () {
      expect(lines(TransactionType.transfer, card, to: bank), [
        'Visa: amount due goes down by \u20B91,250.50',
        'Main bank: balance goes down by \u20B91,250.50',
      ]);
    });

    test('a transfer TO a card: the amount due goes up', () {
      expect(lines(TransactionType.transfer, bank, to: card), [
        'Main bank: balance goes up by \u20B91,250.50',
        'Visa: amount due goes up by \u20B91,250.50',
      ]);
    });

    test('a transfer between two cards uses due wording on both', () {
      const other = DeleteImpactAccount('Amex', AccountType.creditCard);
      expect(lines(TransactionType.transfer, card, to: other), [
        'Visa: amount due goes down by \u20B91,250.50',
        'Amex: amount due goes up by \u20B91,250.50',
      ]);
    });
  });

  group('details', () {
    test('long names are passed through unchanged', () {
      final long = 'A' * 40;
      final other = 'B' * 40;
      final result = lines(
        TransactionType.transfer,
        DeleteImpactAccount(long, AccountType.bank),
        to: DeleteImpactAccount(other, AccountType.creditCard),
      );
      expect(result[0], startsWith('$long: balance goes up'));
      expect(result[1], startsWith('$other: amount due goes up'));
    });

    test('amounts come from Money, including a large one', () {
      final text = lines(
        TransactionType.income,
        bank,
        paise: Money.maxPaise,
      ).single;
      expect(
        text,
        'Main bank: balance goes down by ${Money.format(Money.maxPaise)}',
      );
      expect(text, contains('\u20B910,00,00,00,00,000.00'));

      expect(
        lines(TransactionType.expense, bank, paise: 5).single,
        'Main bank: balance goes up by \u20B90.05',
      );
    });

    test('a transfer without a To account gives only the From line', () {
      expect(lines(TransactionType.transfer, bank), hasLength(1));
    });
  });
}
