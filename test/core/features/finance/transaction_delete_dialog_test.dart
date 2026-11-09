import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/core/theme/app_colors.dart';
import 'package:vesper/core/utils/money.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/data/account_balance.dart';
import 'package:vesper/features/finance/data/categories_table.dart';
import 'package:vesper/features/finance/data/transaction_queries.dart';
import 'package:vesper/features/finance/data/transactions_table.dart';
import 'package:vesper/features/finance/presentation/providers/transactions_providers.dart';
import 'package:vesper/features/finance/presentation/widgets/locked_transaction_sheet.dart';
import 'package:vesper/features/finance/presentation/widgets/transaction_form_sheet.dart';

import '../../../support/transaction_item_helpers.dart';
import '../../../support/ui_test_helpers.dart';

CategoryRow _category(String id, String name, CategoryKind kind) => CategoryRow(
  id: id,
  userId: 'user-1',
  name: name,
  icon: 'fork_knife',
  color: 0xFFC97B84,
  kind: kind,
  isArchived: false,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);

final _deleteButton = find.byKey(const ValueKey('tx_delete_button'));
final _dialog = find.byType(AlertDialog);
final _sheet = find.byType(TransactionFormSheet);

void main() {
  setUpAll(disableFontFetching);

  List<Override> overrides(List<AccountWithBalance> accounts) => [
    accountsOverride(accounts),
    categoriesByKindProvider.overrideWith(
      (ref, kind) => Stream.value(
        [
          _category('c1', 'Food & Dining', CategoryKind.expense),
          _category('c3', 'Salary', CategoryKind.income),
        ].where((c) => c.kind == kind).toList(),
      ),
    ),
    recentCategoriesProvider.overrideWith(
      (ref, kind) => Stream.value(const <CategoryRow>[]),
    ),
  ];

  List<AccountWithBalance> defaultAccounts() => [
    makeAccount(id: 'a1', name: 'Bank', balance: 100000),
    makeAccount(id: 'a2', name: 'Visa', type: AccountType.creditCard),
  ];

  Future<void> pumpEdit(
    WidgetTester tester,
    TransactionListItem item, {
    List<AccountWithBalance>? accounts,
    Size size = const Size(800, 1600),
    double textScale = 1.0,
    Brightness brightness = Brightness.light,
  }) {
    return pumpUi(
      tester,
      Scaffold(
        body: TransactionFormSheet(key: UniqueKey(), existing: item),
      ),
      size: size,
      textScale: textScale,
      brightness: brightness,
      overrides: overrides(accounts ?? defaultAccounts()),
    );
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tapChip(tester, _deleteButton);
    await tester.pumpAndSettle();
    expect(_dialog, findsOneWidget);
  }

  group('the Delete action', () {
    testWidgets('is shown in edit mode, as a TextButton, below Save', (
      tester,
    ) async {
      await pumpEdit(tester, makeTransactionItem(id: 'e', note: 'Tea'));

      expect(_deleteButton, findsOneWidget);
      expect(tester.widget(_deleteButton), isA<TextButton>());
      expect(
        find.descendant(
          of: _deleteButton,
          matching: find.text('Delete transaction'),
        ),
        findsOneWidget,
      );
      // Save stays the only ElevatedButton, and Delete sits below it.
      final save = find.descendant(
        of: _sheet,
        matching: find.byType(ElevatedButton),
      );
      expect(save, findsOneWidget);
      expect(
        tester.getTopLeft(_deleteButton).dy,
        greaterThan(tester.getBottomLeft(save).dy),
      );
    });

    for (final brightness in Brightness.values) {
      testWidgets('uses the danger colour ($brightness)', (tester) async {
        await pumpEdit(
          tester,
          makeTransactionItem(id: 'e'),
          brightness: brightness,
        );
        final palette = brightness == Brightness.dark
            ? AppColors.dark
            : AppColors.light;
        final color = tester
            .widget<TextButton>(_deleteButton)
            .style
            ?.foregroundColor
            ?.resolve(<WidgetState>{});
        expect(color, palette.danger);
      });
    }

    testWidgets('is NOT shown in add mode', (tester) async {
      await pumpUi(
        tester,
        const Scaffold(body: TransactionFormSheet()),
        size: const Size(800, 1600),
        overrides: overrides(defaultAccounts()),
      );

      expect(find.text('Add transaction'), findsOneWidget);
      expect(_deleteButton, findsNothing);
      expect(find.text('Delete transaction'), findsNothing);
    });

    testWidgets('is NOT shown in the locked sheet', (tester) async {
      await pumpUi(
        tester,
        Scaffold(
          body: LockedTransactionSheet(
            item: withSource(
              makeTransactionItem(id: 'l', note: 'Lent'),
              TransactionSource.loan,
            ),
          ),
        ),
      );

      expect(find.text('Edit it from Loans'), findsOneWidget);
      expect(find.textContaining('Delete'), findsNothing);
    });
  });

  group('the confirm dialog', () {
    testWidgets('an expense: summary, balance line, warning, buttons', (
      tester,
    ) async {
      await pumpEdit(
        tester,
        makeTransactionItem(id: 'e', amount: 125050, note: 'Electricity bill'),
      );
      await openDialog(tester);

      expect(find.text('Delete this transaction?'), findsOneWidget);
      expect(
        find.text('Electricity bill \u00B7 \u20B91,250.50'),
        findsOneWidget,
      );
      expect(
        find.text('Bank: balance goes up by \u20B91,250.50'),
        findsOneWidget,
      );
      expect(find.text("This can't be undone."), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('delete_confirm_button')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('delete_error')), findsNothing);
    });

    testWidgets('the summary falls back to the category when no note', (
      tester,
    ) async {
      await pumpEdit(
        tester,
        makeTransactionItem(id: 'e', amount: 5000, note: null),
      );
      await openDialog(tester);

      expect(find.text('Food & Dining \u00B7 \u20B950.00'), findsOneWidget);
    });

    testWidgets('an income lowers the balance', (tester) async {
      await pumpEdit(
        tester,
        makeTransactionItem(
          id: 'i',
          type: TransactionType.income,
          amount: 900000,
          categoryName: 'Salary',
        ),
      );
      await openDialog(tester);

      expect(
        find.text('Bank: balance goes down by \u20B99,000.00'),
        findsOneWidget,
      );
    });

    testWidgets('a transfer to a card: From up, card amount due up', (
      tester,
    ) async {
      await pumpEdit(
        tester,
        makeTransactionItem(
          id: 'x',
          type: TransactionType.transfer,
          amount: 30000,
          note: 'Pay card',
        ),
      );
      await openDialog(tester);

      expect(
        find.text('Bank: balance goes up by \u20B9300.00'),
        findsOneWidget,
      );
      expect(
        find.text('Visa: amount due goes up by \u20B9300.00'),
        findsOneWidget,
      );
    });

    testWidgets('an expense on a card says the amount due goes down', (
      tester,
    ) async {
      await pumpEdit(
        tester,
        makeTransactionItem(id: 'e', amount: 5000, accountName: 'Visa'),
        accounts: [
          makeAccount(id: 'a1', name: 'Visa', type: AccountType.creditCard),
          makeAccount(id: 'a2', name: 'Bank'),
        ],
      );
      await openDialog(tester);

      expect(
        find.text('Visa: amount due goes down by \u20B950.00'),
        findsOneWidget,
      );
    });

    testWidgets('Cancel closes the dialog and keeps the sheet', (tester) async {
      await pumpEdit(tester, makeTransactionItem(id: 'e', note: 'Tea'));
      await openDialog(tester);

      await tester.tap(find.byKey(const ValueKey('delete_cancel_button')));
      await tester.pumpAndSettle();

      expect(_dialog, findsNothing);
      expect(_sheet, findsOneWidget);
      expect(find.text('Edit transaction'), findsOneWidget);
      // The Delete action is usable again.
      expect(tester.widget<TextButton>(_deleteButton).onPressed, isNotNull);
    });
  });

  for (final brightness in Brightness.values) {
    testWidgets('worst case dialog: 320dp, text scale 2.0, 40-character names, '
        'maxPaise ($brightness)', (tester) async {
      await pumpEdit(
        tester,
        makeTransactionItem(
          id: 'w',
          type: TransactionType.transfer,
          amount: Money.maxPaise,
          note: 'n' * 100,
        ),
        accounts: [
          makeAccount(id: 'a1', name: 'A' * 40),
          makeAccount(id: 'a2', name: 'B' * 40, type: AccountType.creditCard),
        ],
        size: const Size(320, 640),
        textScale: 2.0,
        brightness: brightness,
      );
      await openDialog(tester);

      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('${'A' * 40}: balance goes up by'),
        findsOneWidget,
      );
      expect(
        find.textContaining('${'B' * 40}: amount due goes up by'),
        findsOneWidget,
      );
      // Both buttons are reachable (the dialog scrolls).
      expect(
        find.byKey(const ValueKey('delete_cancel_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('delete_confirm_button')),
        findsOneWidget,
      );
    });
  }
}
