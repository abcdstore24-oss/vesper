import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/theme/app_colors.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/presentation/accounts_screen.dart';
import 'package:vesper/features/finance/presentation/widgets/account_form_sheet.dart';
import 'package:vesper/shared/widgets/dashboard_card.dart';

import '../../../support/ui_test_helpers.dart';

Finder _row(String id) => find.byKey(ValueKey('account-row-$id'));

void main() {
  setUpAll(disableFontFetching);

  testWidgets('12 accounts: last row clears the FAB, all rows same height', (
    tester,
  ) async {
    const types = AccountType.values;
    final accounts = [
      for (var i = 1; i <= 12; i++)
        makeAccount(
          id: 'id$i',
          name: 'Account ${i.toString().padLeft(2, '0')}',
          type: types[i % types.length],
          // A mix of owed cards, overpaid cards, overdrafts and plain balances.
          balance: i.isEven ? -(i * 12345) : i * 12345,
        ),
    ];

    await pumpUi(
      tester,
      const AccountsScreen(),
      overrides: [accountsOverride(accounts)],
    );

    // All rows exist and are the same height.
    final heights = [
      for (final a in accounts) tester.getSize(_row(a.account.id)).height,
    ];
    for (final h in heights) {
      expect(h, closeTo(heights.first, 0.01));
    }

    // Scroll to the very end.
    for (var i = 0; i < 3; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();
    }

    final lastBottom = tester.getBottomLeft(_row('id12')).dy;
    final fabTop = tester.getTopLeft(find.byType(FloatingActionButton)).dy;
    expect(lastBottom, lessThanOrEqualTo(fabTop));
    expect(tester.takeException(), isNull);
  });

  testWidgets('card row: owed shows positive + "due"; overpaid "credit"', (
    tester,
  ) async {
    await pumpUi(
      tester,
      const AccountsScreen(),
      overrides: [
        accountsOverride([
          makeAccount(
            id: 'owed',
            name: 'Visa',
            type: AccountType.creditCard,
            balance: -120050,
          ),
          makeAccount(
            id: 'over',
            name: 'Amex',
            type: AccountType.creditCard,
            balance: 5000,
          ),
          makeAccount(
            id: 'od',
            name: 'Overdraft',
            type: AccountType.bank,
            balance: -50000,
          ),
          makeAccount(id: 'ok', name: 'Cash', type: AccountType.cash, balance: 700),
        ]),
      ],
    );

    Finder within(String id, Finder f) =>
        find.descendant(of: _row(id), matching: f);

    // Owed: amount is shown positive, in the danger colour, with "due".
    expect(within('owed', find.text('\u20B91,200.50')), findsOneWidget);
    expect(within('owed', find.text('due')), findsOneWidget);
    expect(
      tester.widget<Text>(within('owed', find.text('\u20B91,200.50'))).style?.color,
      AppColors.light.danger,
    );

    // Overpaid: positive tone and "credit".
    expect(within('over', find.text('\u20B950.00')), findsOneWidget);
    expect(within('over', find.text('credit')), findsOneWidget);
    expect(
      tester.widget<Text>(within('over', find.text('\u20B950.00'))).style?.color,
      AppColors.light.success,
    );

    // Non-card negative: minus sign, danger, no caption.
    expect(within('od', find.text('-\u20B9500.00')), findsOneWidget);
    expect(
      tester.widget<Text>(within('od', find.text('-\u20B9500.00'))).style?.color,
      AppColors.light.danger,
    );
    expect(within('od', find.text('due')), findsNothing);
    expect(within('od', find.text('credit')), findsNothing);

    // Plain balance: neutral.
    expect(
      tester.widget<Text>(within('ok', find.text('\u20B97.00'))).style?.color,
      AppColors.light.textPrimary,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('archived accounts are hidden', (tester) async {
    await pumpUi(
      tester,
      const AccountsScreen(),
      overrides: [
        accountsOverride([
          makeAccount(id: 'a', name: 'Shown', balance: 100),
          makeAccount(id: 'b', name: 'Hidden', balance: 200, isArchived: true),
        ]),
      ],
    );

    expect(find.text('Shown'), findsOneWidget);
    expect(find.text('Hidden'), findsNothing);
  });

  testWidgets('empty state reuses DashboardCard with an Add account button', (
    tester,
  ) async {
    await pumpUi(
      tester,
      const AccountsScreen(),
      overrides: [accountsOverride(const [])],
    );

    expect(find.byType(DashboardCard), findsOneWidget);
    // The card title and the summary caption are different phrases, so
    // "No accounts yet" is shown only once.
    expect(find.text('Add your first account'), findsOneWidget);
    expect(find.text('No accounts yet'), findsOneWidget);

    final addButton = find.widgetWithText(ElevatedButton, 'Add account');
    expect(addButton, findsOneWidget);

    await tester.tap(addButton);
    await tester.pumpAndSettle();
    expect(find.byType(AccountFormSheet), findsOneWidget);
    expect(find.text('Add account'), findsWidgets);
  });

  testWidgets('FAB opens the add sheet', (tester) async {
    await pumpUi(
      tester,
      const AccountsScreen(),
      overrides: [accountsOverride([makeAccount()])],
    );

    expect(find.byTooltip('Add account'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(AccountFormSheet), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Add account'), findsOneWidget);
  });

  testWidgets('tapping a row opens the sheet in edit mode', (tester) async {
    await pumpUi(
      tester,
      const AccountsScreen(),
      overrides: [
        accountsOverride([makeAccount(id: 'a', name: 'Savings', balance: 125050)]),
      ],
    );

    await tester.tap(_row('a'));
    await tester.pumpAndSettle();

    expect(find.text('Edit account'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Save changes'), findsOneWidget);
    final name = tester.widget<TextField>(
      find.byKey(const ValueKey('account_name_field')),
    );
    expect(name.controller?.text, 'Savings');
  });
}