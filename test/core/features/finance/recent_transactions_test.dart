import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/core/theme/app_colors.dart';
import 'package:vesper/core/utils/app_dates.dart';
import 'package:vesper/core/utils/money.dart';
import 'package:vesper/features/finance/data/transaction_queries.dart';
import 'package:vesper/features/finance/data/transactions_table.dart';
import 'package:vesper/features/finance/presentation/finance_home_screen.dart';
import 'package:vesper/features/finance/presentation/providers/transactions_providers.dart';
import 'package:vesper/features/finance/presentation/widgets/transaction_form_sheet.dart';
import 'package:vesper/shared/widgets/amount_text.dart';

import '../../../support/ui_test_helpers.dart';

Finder _tile(String id) => find.byKey(ValueKey('transaction-tile-$id'));

void main() {
  setUpAll(disableFontFetching);

  Future<void> pumpHome(
    WidgetTester tester,
    List<TransactionListItem> items, {
    Size size = const Size(800, 600),
    double textScale = 1.0,
    Brightness brightness = Brightness.light,
  }) {
    return pumpUi(
      tester,
      const FinanceHomeScreen(),
      size: size,
      textScale: textScale,
      brightness: brightness,
      overrides: [
        accountsOverride([makeAccount(name: 'Bank', balance: 100000)]),
        recentTransactionsOverride(items),
      ],
    );
  }

  testWidgets('empty state, header order, and the add button', (tester) async {
    await pumpHome(tester, const []);

    expect(find.text('Recent transactions'), findsOneWidget);
    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.text('Tap + to add your first one.'), findsOneWidget);

    // Balance summary, then Recent transactions, then Manage.
    final total = tester.getTopLeft(find.text('Total balance')).dy;
    final recent = tester.getTopLeft(find.text('Recent transactions')).dy;
    final manage = tester.getTopLeft(find.text('Manage')).dy;
    expect(total, lessThan(recent));
    expect(recent, lessThan(manage));

    expect(find.byTooltip('Add transaction'), findsOneWidget);
    // No dead buttons yet.
    expect(find.textContaining('See all'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows at most 5 rows', (tester) async {
    await pumpHome(tester, [
      for (var i = 1; i <= 7; i++) makeTransactionItem(id: 't$i', note: 'row $i'),
    ]);

    for (var i = 1; i <= 5; i++) {
      expect(_tile('t$i'), findsOneWidget);
    }
    expect(_tile('t6'), findsNothing);
    expect(_tile('t7'), findsNothing);
    expect(find.text('No transactions yet'), findsNothing);
  });

  testWidgets('rows are descriptive, with exact amounts and tones', (
    tester,
  ) async {
    await pumpHome(tester, [
      makeTransactionItem(
        id: 'e',
        amount: 125050,
        note: 'Electricity bill',
        categoryName: 'Bills & Utilities',
        categoryIcon: 'receipt',
        accountName: 'Bank',
      ),
      makeTransactionItem(
        id: 'i',
        type: TransactionType.income,
        amount: 5000000,
        categoryName: 'Salary',
        categoryIcon: 'briefcase',
        accountName: 'Bank',
      ),
      makeTransactionItem(
        id: 'x',
        type: TransactionType.transfer,
        amount: 30000,
        accountName: 'Bank',
        toAccountName: 'Visa',
      ),
    ]);

    Finder within(String id, Finder f) =>
        find.descendant(of: _tile(id), matching: f);
    Color? colorOf(String id, String text) =>
        tester.widget<Text>(within(id, find.text(text))).style?.color;

    // Expense: the note is the title, the category stays in the subtitle.
    expect(within('e', find.text('Electricity bill')), findsOneWidget);
    expect(
      within('e', find.text('Bills & Utilities \u00B7 Bank')),
      findsOneWidget,
    );
    // The date is in the right column, not in the subtitle.
    expect(within('e', find.text('Today')), findsOneWidget);
    expect(colorOf('e', '-\u20B91,250.50'), AppColors.light.danger);

    // Income: the category is the title (dropped from the subtitle).
    expect(within('i', find.text('Salary')), findsOneWidget);
    expect(within('i', find.text('Bank')), findsOneWidget);
    expect(within('i', find.text('Today')), findsOneWidget);
    expect(colorOf('i', '\u20B950,000.00'), AppColors.light.success);

    // Transfer: neutral, "from → to".
    expect(within('x', find.text('Transfer')), findsOneWidget);
    expect(
      within('x', find.text('Bank \u2192 Visa')),
      findsOneWidget,
    );
    expect(within('x', find.text('Today')), findsOneWidget);
    expect(colorOf('x', '\u20B9300.00'), AppColors.light.textPrimary);
  });

  testWidgets('the date sits under the amount, right-aligned, one line', (
    tester,
  ) async {
    // A date in a previous year, so the label includes the year.
    final lastYear = DateTime(DateTime.now().year - 1, 10, 5, 12);
    await pumpHome(tester, [
      makeTransactionItem(id: 'e', amount: 125050, note: 'Electricity bill'),
      makeTransactionItem(id: 'o', amount: 50, occurredAt: lastYear),
    ]);

    final oldLabel = AppDates.format(lastYear);
    expect(oldLabel, endsWith('${lastYear.year}'));
    for (final entry in {'e': 'Today', 'o': oldLabel}.entries) {
      final tile = _tile(entry.key);
      final date = find.descendant(of: tile, matching: find.text(entry.value));
      final amount = find.descendant(
        of: tile,
        matching: find.byType(AmountText),
      );
      expect(date, findsOneWidget, reason: entry.value);

      final dateBox = tester.getRect(date);
      final amountBox = tester.getRect(amount);
      // Under the amount...
      expect(dateBox.top, greaterThanOrEqualTo(amountBox.bottom - 1));
      // ...and aligned to the same right edge.
      expect(dateBox.right, closeTo(amountBox.right, 1.0));
      // One line.
      expect(tester.getSize(date).height, lessThan(30));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('the subtitle never contains the date', (tester) async {
    await pumpHome(tester, [
      makeTransactionItem(id: 'a', categoryName: 'Groceries'),
      makeTransactionItem(
        id: 'b',
        type: TransactionType.transfer,
        accountName: 'Bank',
        toAccountName: 'Visa',
      ),
    ]);

    expect(find.text('Bank'), findsOneWidget); // subtitle of the expense
    expect(find.text('Bank \u2192 Visa'), findsOneWidget);
    expect(find.textContaining('\u00B7 Today'), findsNothing);
    expect(find.text('Today'), findsNWidgets(2)); // one per row, on the right
  });

  testWidgets('rows are not tappable', (tester) async {
    await pumpHome(tester, [makeTransactionItem(id: 't1', note: 'x')]);

    expect(
      find.descendant(of: _tile('t1'), matching: find.byType(InkWell)),
      findsNothing,
    );
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'worst case: 100-char note, 40-char names, maxPaise at 320dp, '
      'text scale 1.5 ($brightness)',
      (tester) async {
        await pumpHome(
          tester,
          [
            makeTransactionItem(
              id: 'a',
              amount: Money.maxPaise,
              note: 'n' * 100,
              accountName: 'A' * 40,
            ),
            makeTransactionItem(
              id: 'b',
              type: TransactionType.income,
              amount: Money.maxPaise,
              categoryName: 'C' * 40,
              accountName: 'B' * 40,
            ),
            makeTransactionItem(
              id: 'c',
              type: TransactionType.transfer,
              amount: Money.maxPaise,
              note: 'm' * 100,
              accountName: 'D' * 40,
              toAccountName: 'E' * 40,
            ),
          ],
          size: const Size(320, 640),
          textScale: 1.5,
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);

        // The date under each amount is never truncated either.
        final dates = find.text('Today');
        expect(dates, findsNWidgets(3));
        for (var i = 0; i < 3; i++) {
          final date = tester.widget<Text>(dates.at(i));
          expect(date.overflow, isNot(TextOverflow.ellipsis));
          expect(date.maxLines, 1);
        }

        final amountTexts = find.descendant(
          of: find.descendant(
            of: find.byType(Card),
            matching: find.byType(AmountText),
          ),
          matching: find.byType(Text),
        );
        expect(amountTexts, findsWidgets);
        for (var i = 0; i < tester.widgetList(amountTexts).length; i++) {
          final text = tester.widget<Text>(amountTexts.at(i));
          expect(text.overflow, isNot(TextOverflow.ellipsis));
          expect(text.maxLines, 1);
          final paragraph = tester.renderObject<RenderParagraph>(
            amountTexts.at(i),
          );
          expect(paragraph.didExceedMaxLines, isFalse);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('after scrolling, the last row clears the FAB', (tester) async {
    await pumpHome(tester, [
      for (var i = 1; i <= 5; i++) makeTransactionItem(id: 't$i', note: 'row $i'),
    ]);

    for (var i = 0; i < 3; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();
    }

    final lastBottom = tester
        .getBottomLeft(find.widgetWithText(ListTile, 'Accounts'))
        .dy;
    final fabTop = tester.getTopLeft(find.byType(FloatingActionButton)).dy;
    expect(lastBottom, lessThanOrEqualTo(fabTop));
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading shows a spinner, not "No transactions yet"', (
    tester,
  ) async {
    await pumpUi(
      tester,
      const FinanceHomeScreen(),
      overrides: [
        accountsOverride([makeAccount(name: 'Bank', balance: 100000)]),
        recentTransactionsProvider.overrideWith((ref) {
          final controller = StreamController<List<TransactionListItem>>();
          ref.onDispose(controller.close);
          return controller.stream;
        }),
      ],
    );

    expect(find.text('Recent transactions'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No transactions yet'), findsNothing);
  });

  testWidgets('error shows a message and Retry reloads', (tester) async {
    var calls = 0;
    await pumpUi(
      tester,
      const FinanceHomeScreen(),
      overrides: [
        accountsOverride([makeAccount(name: 'Bank', balance: 100000)]),
        recentTransactionsProvider.overrideWith((ref) {
          calls++;
          return calls == 1
              ? Stream<List<TransactionListItem>>.error(Exception('boom'))
              : Stream.value([makeTransactionItem(note: 'Back again')]);
        }),
      ],
    );

    expect(find.text("Couldn't load transactions"), findsOneWidget);
    expect(find.text('No transactions yet'), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(find.text("Couldn't load transactions"), findsNothing);
    expect(find.text('Back again'), findsOneWidget);
  });

  testWidgets('the add button opens the add-transaction sheet', (tester) async {
    await pumpUi(
      tester,
      const FinanceHomeScreen(),
      overrides: [
        accountsOverride([makeAccount(name: 'Bank', balance: 100000)]),
        recentTransactionsOverride(const []),
        categoriesByKindProvider.overrideWith(
          (ref, kind) => Stream.value(const <CategoryRow>[]),
        ),
      ],
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(TransactionFormSheet), findsOneWidget);
    expect(find.text('Add transaction'), findsWidgets);
  });
}