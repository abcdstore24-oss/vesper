import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/features/finance/data/categories_table.dart';
import 'package:vesper/features/finance/data/transaction_queries.dart';
import 'package:vesper/features/finance/data/transactions_table.dart';
import 'package:vesper/features/finance/presentation/finance_home_screen.dart';
import 'package:vesper/features/finance/presentation/providers/transactions_providers.dart';
import 'package:vesper/features/finance/presentation/transactions_screen.dart';
import 'package:vesper/features/finance/presentation/widgets/locked_transaction_sheet.dart';
import 'package:vesper/features/finance/presentation/widgets/transaction_form_sheet.dart';
import 'package:vesper/shared/widgets/amount_text.dart';

import '../../../support/transaction_item_helpers.dart';
import '../../../support/ui_test_helpers.dart';

Finder _tile(String id) => find.byKey(ValueKey('transaction-tile-$id'));

CategoryRow _food() => CategoryRow(
  id: 'c1',
  userId: 'user-1',
  name: 'Food & Dining',
  icon: 'fork_knife',
  color: 0xFFC97B84,
  kind: CategoryKind.expense,
  isArchived: false,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);

/// Overrides everything the edit sheet reads, so no database is needed.
List<Override> _sheetOverrides() => [
  accountsOverride([
    makeAccount(id: 'a1', name: 'Bank', balance: 100000),
    makeAccount(id: 'a2', name: 'Visa', balance: 0),
  ]),
  categoriesByKindProvider.overrideWith(
    (ref, kind) => Stream.value(
      kind == CategoryKind.expense ? [_food()] : const <CategoryRow>[],
    ),
  ),
  recentCategoriesProvider.overrideWith(
    (ref, kind) => Stream.value(const <CategoryRow>[]),
  ),
];

Override _allOverride(List<TransactionListItem> items) {
  return allTransactionsProvider.overrideWith(
    (ref, type) => Stream.value([
      for (final i in items)
        if (type == null || i.transaction.type == type) i,
    ]),
  );
}

void main() {
  setUpAll(disableFontFetching);

  final plain = makeTransactionItem(id: 'p', note: 'Lunch', amount: 12000);
  final loan = withSource(
    makeTransactionItem(
      id: 'l',
      note: 'Lent to Sam',
      amount: 500000,
      categoryName: 'Loan given',
      accountName: 'Bank',
    ),
    TransactionSource.loan,
  );
  final trade = withSource(
    makeTransactionItem(
      id: 'i',
      type: TransactionType.income,
      note: 'Sold units',
      amount: 750000,
      categoryName: 'Investment sale',
    ),
    TransactionSource.investment,
  );

  Future<void> pumpList(WidgetTester tester) => pumpUi(
    tester,
    const TransactionsScreen(),
    size: const Size(800, 1600),
    overrides: [
      _allOverride([plain, loan, trade]),
      ..._sheetOverrides(),
    ],
  );

  group('Transactions list', () {
    testWidgets('tapping an ordinary row opens the edit sheet', (tester) async {
      await pumpList(tester);

      await tester.tap(_tile('p'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionFormSheet), findsOneWidget);
      expect(find.text('Edit transaction'), findsOneWidget);
      expect(find.byType(LockedTransactionSheet), findsNothing);
    });

    testWidgets('a loan row opens the read-only explanation', (tester) async {
      await pumpList(tester);

      await tester.tap(_tile('l'));
      await tester.pumpAndSettle();

      expect(find.byType(LockedTransactionSheet), findsOneWidget);
      expect(find.byType(TransactionFormSheet), findsNothing);
      expect(find.text('Edit it from Loans'), findsOneWidget);
      expect(find.text('Edit it from Investments'), findsNothing);

      final sheet = find.byType(LockedTransactionSheet);
      Finder inSheet(Finder f) => find.descendant(of: sheet, matching: f);
      // The details are shown (amount through AmountText)...
      expect(inSheet(find.text('Expense')), findsOneWidget);
      expect(inSheet(find.byType(AmountText)), findsOneWidget);
      expect(inSheet(find.text('-\u20B95,000.00')), findsOneWidget);
      expect(inSheet(find.text('Loan given')), findsOneWidget);
      expect(inSheet(find.text('Bank')), findsOneWidget);
      expect(inSheet(find.text('Lent to Sam')), findsOneWidget);
      expect(inSheet(find.text('Today')), findsOneWidget);
      // ...and there is nothing to edit, save or delete.
      expect(inSheet(find.byType(TextField)), findsNothing);
      expect(inSheet(find.byType(ElevatedButton)), findsNothing);
      expect(inSheet(find.byType(TextButton)), findsNothing);
      expect(inSheet(find.textContaining('Delete')), findsNothing);
      expect(inSheet(find.textContaining('Save')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an investment row says to edit it from Investments', (
      tester,
    ) async {
      await pumpList(tester);

      await tester.tap(_tile('i'));
      await tester.pumpAndSettle();

      expect(find.byType(LockedTransactionSheet), findsOneWidget);
      expect(find.text('Edit it from Investments'), findsOneWidget);
      expect(find.text('Edit it from Loans'), findsNothing);
      expect(find.byType(TransactionFormSheet), findsNothing);
      final sheet = find.byType(LockedTransactionSheet);
      expect(
        find.descendant(of: sheet, matching: find.text('Income')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('\u20B97,500.00')),
        findsOneWidget,
      );
    });

    for (final brightness in Brightness.values) {
      testWidgets(
        'the locked sheet fits at 320dp, text scale 2.0 ($brightness)',
        (tester) async {
          await pumpUi(
            tester,
            const TransactionsScreen(),
            size: const Size(320, 640),
            textScale: 2.0,
            brightness: brightness,
            overrides: [
              _allOverride([
                withSource(
                  makeTransactionItem(
                    id: 'w',
                    type: TransactionType.transfer,
                    amount: 100000000000000,
                    note: 'n' * 100,
                    accountName: 'A' * 40,
                    toAccountName: 'B' * 40,
                  ),
                  TransactionSource.loan,
                ),
              ]),
              ..._sheetOverrides(),
            ],
          );
          await tester.tap(_tile('w'));
          await tester.pumpAndSettle();
          expect(find.byType(LockedTransactionSheet), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('Recent transactions on the Finance home', () {
    Future<void> pumpHome(WidgetTester tester) => pumpUi(
      tester,
      const FinanceHomeScreen(),
      size: const Size(800, 1600),
      overrides: [
        recentTransactionsOverride([plain, loan]),
        ..._sheetOverrides(),
      ],
    );

    testWidgets('an ordinary row opens the edit sheet', (tester) async {
      await pumpHome(tester);

      await tester.tap(_tile('p'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionFormSheet), findsOneWidget);
      expect(find.text('Edit transaction'), findsOneWidget);
    });

    testWidgets('a locked row opens the explanation', (tester) async {
      await pumpHome(tester);

      await tester.tap(_tile('l'));
      await tester.pumpAndSettle();

      expect(find.byType(LockedTransactionSheet), findsOneWidget);
      expect(find.text('Edit it from Loans'), findsOneWidget);
      expect(find.byType(TransactionFormSheet), findsNothing);
    });
  });
}
