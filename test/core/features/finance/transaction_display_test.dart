import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:vesper/features/finance/data/transactions_table.dart';
import 'package:vesper/features/finance/presentation/category_display.dart';
import 'package:vesper/features/finance/presentation/transaction_display.dart';
import 'package:vesper/shared/widgets/amount_text.dart';

import '../../../support/ui_test_helpers.dart';

void main() {
  final now = DateTime(2026, 10, 17, 18);
  final today = DateTime(2026, 10, 17, 9);
  final yesterday = DateTime(2026, 10, 16, 12);

  group('title and subtitle', () {
    test('a note is the title; the category stays in the subtitle', () {
      final d = transactionDisplay(
        makeTransactionItem(
          note: 'Electricity bill',
          categoryName: 'Bills & Utilities',
          accountName: 'Bank',
          occurredAt: today,
        ),
        now: now,
      );
      expect(d.title, 'Electricity bill');
      expect(d.subtitle, 'Bills & Utilities \u00B7 Bank');
      expect(d.dateLabel, 'Today');
    });

    test('no note: the category is the title and is dropped from the subtitle', () {
      final d = transactionDisplay(
        makeTransactionItem(
          categoryName: 'Groceries',
          accountName: 'Cash',
          occurredAt: yesterday,
        ),
        now: now,
      );
      expect(d.title, 'Groceries');
      expect(d.subtitle, 'Cash');
      expect(d.dateLabel, 'Yesterday');
    });

    test('a blank note counts as no note', () {
      final d = transactionDisplay(
        makeTransactionItem(
          note: '   ',
          categoryName: 'Groceries',
          occurredAt: today,
        ),
        now: now,
      );
      expect(d.title, 'Groceries');
      expect(d.subtitle, 'Bank');
      expect(d.dateLabel, 'Today');
    });

    test('a note equal to the category name does not repeat it', () {
      final d = transactionDisplay(
        makeTransactionItem(
          note: 'Groceries',
          categoryName: 'Groceries',
          occurredAt: today,
        ),
        now: now,
      );
      expect(d.title, 'Groceries');
      expect(d.subtitle, 'Bank');
      expect(d.dateLabel, 'Today');
    });

    test('transfer without a note: "Transfer" and from \u2192 to', () {
      final d = transactionDisplay(
        makeTransactionItem(
          type: TransactionType.transfer,
          accountName: 'Bank',
          toAccountName: 'Visa',
          occurredAt: yesterday,
        ),
        now: now,
      );
      expect(d.title, 'Transfer');
      expect(d.subtitle, 'Bank \u2192 Visa');
      expect(d.dateLabel, 'Yesterday');
    });

    test('transfer with a note uses the note as the title', () {
      final d = transactionDisplay(
        makeTransactionItem(
          type: TransactionType.transfer,
          note: 'Card payment',
          accountName: 'Bank',
          toAccountName: 'Visa',
          occurredAt: today,
        ),
        now: now,
      );
      expect(d.title, 'Card payment');
      expect(d.subtitle, 'Bank \u2192 Visa');
      expect(d.dateLabel, 'Today');
    });

    test('no category name at all: "Uncategorised"', () {
      final d = transactionDisplay(
        makeTransactionItem(categoryName: null, occurredAt: today),
        now: now,
      );
      expect(d.title, 'Uncategorised');
      expect(d.subtitle, 'Bank');
      expect(d.dateLabel, 'Today');

      final withNote = transactionDisplay(
        makeTransactionItem(
          categoryName: null,
          note: 'Mystery',
          occurredAt: today,
        ),
        now: now,
      );
      expect(withNote.title, 'Mystery');
      expect(withNote.subtitle, 'Bank');
      expect(withNote.dateLabel, 'Today');
    });

    test('dates from another year include the year', () {
      final d = transactionDisplay(
        makeTransactionItem(occurredAt: DateTime(2025, 10, 5, 12)),
        now: now,
      );
      expect(d.dateLabel, '5 Oct 2025');
      expect(d.subtitle, isNot(contains('2025')));
    });
  });

  group('amount and icon', () {
    test('expense: negative paise, negative tone, category icon', () {
      final d = transactionDisplay(
        makeTransactionItem(amount: 125050, categoryIcon: 'fork_knife'),
        now: now,
      );
      expect(d.paise, -125050);
      expect(d.tone, AmountTone.negative);
      expect(d.icon, categoryIcon('fork_knife'));
    });

    test('income: positive paise, positive tone, category icon', () {
      final d = transactionDisplay(
        makeTransactionItem(
          type: TransactionType.income,
          amount: 5000000,
          categoryName: 'Salary',
          categoryIcon: 'briefcase',
        ),
        now: now,
      );
      expect(d.paise, 5000000);
      expect(d.tone, AmountTone.positive);
      expect(d.icon, PhosphorIconsRegular.briefcase);
    });

    test('transfer: plain paise, neutral tone, swap icon', () {
      final d = transactionDisplay(
        makeTransactionItem(type: TransactionType.transfer, amount: 30000),
        now: now,
      );
      expect(d.paise, 30000);
      expect(d.tone, AmountTone.neutral);
      expect(d.icon, PhosphorIconsRegular.arrowsLeftRight);
    });

    test('an unknown icon key falls back', () {
      final d = transactionDisplay(
        makeTransactionItem(categoryIcon: 'made_up'),
        now: now,
      );
      expect(d.icon, categoryFallbackIcon);
    });
  });

  test('the date is never part of the subtitle', () {
    for (final item in [
      makeTransactionItem(note: 'n', occurredAt: today),
      makeTransactionItem(occurredAt: yesterday),
      makeTransactionItem(
        type: TransactionType.transfer,
        occurredAt: DateTime(2025, 1, 2, 12),
      ),
    ]) {
      final d = transactionDisplay(item, now: now);
      expect(d.subtitle, isNot(contains(d.dateLabel)));
      expect(d.subtitle, isNot(contains('Today')));
      expect(d.subtitle, isNot(contains('Yesterday')));
    }
  });
}