import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/db/db_bootstrap.dart';
import 'package:vesper/core/utils/money.dart';
import 'package:vesper/features/finance/data/accounts_dao.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/data/categories_dao.dart';
import 'package:vesper/features/finance/data/transaction_queries.dart';
import 'package:vesper/features/finance/data/transactions_dao.dart';
import 'package:vesper/features/finance/data/transactions_table.dart';
import 'package:vesper/features/finance/presentation/finance_home_screen.dart';
import 'package:vesper/features/finance/presentation/providers/transactions_providers.dart';
import 'package:vesper/features/finance/presentation/transactions_screen.dart';
import 'package:vesper/features/finance/presentation/widgets/transaction_form_sheet.dart';
import 'package:vesper/features/finance/presentation/widgets/transaction_tile.dart';
import 'package:vesper/shared/widgets/picker_sheet.dart';

import '../../../support/ui_test_helpers.dart';

Finder _tile(String id) => find.byKey(ValueKey('transaction-tile-$id'));
Finder _chip(String name) => find.byKey(ValueKey('transactions-filter-$name'));

/// Overrides allTransactionsProvider with a fixed list, filtered by the
/// family key in Dart (the real provider filters in SQL).
Override _allOverride(List<TransactionListItem> items) {
  return allTransactionsProvider.overrideWith(
    (ref, type) => Stream.value([
      for (final i in items)
        if (type == null || i.transaction.type == type) i,
    ]),
  );
}

/// Taps a filter chip, then pumps until the (override) stream has emitted
/// and the list has rebuilt.
Future<void> pick(WidgetTester tester, Finder chip) async {
  await tapChip(tester, chip);
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(disableFontFetching);

  Future<void> pumpScreen(
    WidgetTester tester,
    List<TransactionListItem> items, {
    Size size = const Size(800, 600),
    double textScale = 1.0,
    Brightness brightness = Brightness.light,
  }) {
    return pumpUi(
      tester,
      const TransactionsScreen(),
      size: size,
      textScale: textScale,
      brightness: brightness,
      overrides: [_allOverride(items)],
    );
  }

  group('layout (no database)', () {
    testWidgets('title, chips, date headers and one Card per row', (
      tester,
    ) async {
      final now = DateTime.now();
      await pumpScreen(tester, [
        makeTransactionItem(id: 'a', note: 'Today row', occurredAt: now),
        makeTransactionItem(
          id: 'b',
          note: 'Yesterday row',
          occurredAt: DateTime(now.year, now.month, now.day - 1, 12),
        ),
      ]);

      expect(find.text('Transactions'), findsOneWidget);
      for (final name in ['all', 'expense', 'income', 'transfer']) {
        expect(_chip(name), findsOneWidget);
      }
      expect(tester.widget<ChoiceChip>(_chip('all')).selected, isTrue);

      // Rows do not repeat the date: only the headers say it.
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      for (final id in ['a', 'b']) {
        expect(
          find.ancestor(of: _tile(id), matching: find.byType(Card)),
          findsOneWidget,
        );
      }
      // Newest first: header, row, header, row.
      expect(
        tester.getTopLeft(find.text('Today')).dy,
        lessThan(tester.getTopLeft(_tile('a')).dy),
      );
      expect(
        tester.getTopLeft(_tile('a')).dy,
        lessThan(tester.getTopLeft(find.text('Yesterday')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Yesterday')).dy,
        lessThan(tester.getTopLeft(_tile('b')).dy),
      );
      // Tappable since Task 4b-2b (tap opens the edit sheet).
      expect(
        find.descendant(of: _tile('a'), matching: find.byType(InkWell)),
        findsOneWidget,
      );
      expect(find.byTooltip('Add transaction'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final brightness in Brightness.values) {
      testWidgets('worst case: 320dp, text scale 2.0, 100-char note, maxPaise '
          '($brightness)', (tester) async {
        await pumpScreen(
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
          textScale: 2.0,
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);
        // The chips wrap instead of overflowing, and are all reachable.
        for (final name in ['all', 'expense', 'income', 'transfer']) {
          expect(_chip(name), findsOneWidget);
          expect(tester.getRect(_chip(name)).right, lessThanOrEqualTo(320));
        }
        expect(_tile('a'), findsOneWidget);
      });
    }

    testWidgets('500 rows: the list is lazy and the last row clears the FAB', (
      tester,
    ) async {
      final now = DateTime.now();
      await pumpScreen(tester, [
        for (var i = 1; i <= 500; i++)
          makeTransactionItem(
            id: 't$i',
            note: 'row $i',
            occurredAt: now.subtract(Duration(days: i)),
          ),
      ]);

      // Lazy: only the rows near the viewport are built.
      final built = find.byType(TransactionTile).evaluate().length;
      expect(built, greaterThan(0));
      expect(built, lessThan(60));

      // Scroll to the very end.
      final last = _tile('t500');
      for (var i = 0; i < 400 && last.evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -2000));
        await tester.pump();
      }
      expect(last, findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -2000));
        await tester.pumpAndSettle();
      }

      final lastBottom = tester
          .getBottomLeft(
            find.ancestor(of: last, matching: find.byType(Card)).first,
          )
          .dy;
      final fabTop = tester.getTopLeft(find.byType(FloatingActionButton)).dy;
      expect(lastBottom, lessThanOrEqualTo(fabTop));
      expect(tester.takeException(), isNull);
    });

    testWidgets('chips filter and show the matching empty message', (
      tester,
    ) async {
      await pumpScreen(tester, [
        makeTransactionItem(id: 'e1', note: 'An expense'),
        makeTransactionItem(
          id: 'x1',
          type: TransactionType.transfer,
          note: 'A transfer',
        ),
      ]);

      expect(_tile('e1'), findsOneWidget);
      expect(_tile('x1'), findsOneWidget);

      await pick(tester, _chip('income'));
      expect(tester.widget<ChoiceChip>(_chip('income')).selected, isTrue);
      expect(tester.widget<ChoiceChip>(_chip('all')).selected, isFalse);
      expect(find.text('No income transactions'), findsOneWidget);
      expect(_tile('e1'), findsNothing);
      // The chip row is still there.
      expect(_chip('all'), findsOneWidget);

      await pick(tester, _chip('expense'));
      expect(_tile('e1'), findsOneWidget);
      expect(_tile('x1'), findsNothing);
      expect(find.text('No income transactions'), findsNothing);

      await pick(tester, _chip('transfer'));
      expect(_tile('x1'), findsOneWidget);
      expect(_tile('e1'), findsNothing);

      await pick(tester, _chip('all'));
      expect(_tile('e1'), findsOneWidget);
      expect(_tile('x1'), findsOneWidget);
    });

    testWidgets('empty: All shows the empty card, filters a short message', (
      tester,
    ) async {
      await pumpScreen(tester, const []);

      expect(find.text('No transactions yet'), findsOneWidget);
      expect(find.text('Tap + to add your first one.'), findsOneWidget);

      await pick(tester, _chip('expense'));
      expect(find.text('No expense transactions'), findsOneWidget);
      expect(find.text('No transactions yet'), findsNothing);

      await pick(tester, _chip('income'));
      expect(find.text('No income transactions'), findsOneWidget);

      await pick(tester, _chip('transfer'));
      expect(find.text('No transfers'), findsOneWidget);

      await pick(tester, _chip('all'));
      expect(find.text('No transactions yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('loading: spinner (not empty) and the chips stay visible', (
      tester,
    ) async {
      await pumpUi(
        tester,
        const TransactionsScreen(),
        overrides: [
          allTransactionsProvider.overrideWith((ref, type) {
            final controller = StreamController<List<TransactionListItem>>();
            ref.onDispose(controller.close);
            return controller.stream;
          }),
        ],
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No transactions yet'), findsNothing);
      expect(_chip('all'), findsOneWidget);
      expect(_chip('transfer'), findsOneWidget);
    });

    testWidgets('error: message + Retry reloads; the chips stay visible', (
      tester,
    ) async {
      var calls = 0;
      await pumpUi(
        tester,
        const TransactionsScreen(),
        overrides: [
          allTransactionsProvider.overrideWith((ref, type) {
            calls++;
            return calls == 1
                ? Stream<List<TransactionListItem>>.error(Exception('boom'))
                : Stream.value([makeTransactionItem(note: 'Back again')]);
          }),
        ],
      );

      expect(find.text("Couldn't load transactions"), findsOneWidget);
      expect(find.text('No transactions yet'), findsNothing);
      expect(_chip('all'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();

      expect(find.text("Couldn't load transactions"), findsNothing);
      expect(find.text('Back again'), findsOneWidget);
    });
  });

  group('"See all" on the Finance home (no database)', () {
    Future<void> pumpHome(WidgetTester tester, List<Override> overrides) {
      return pumpUi(
        tester,
        const FinanceHomeScreen(),
        overrides: [
          accountsOverride([makeAccount(name: 'Bank', balance: 100000)]),
          ...overrides,
        ],
      );
    }

    testWidgets('shown with rows; opens the Transactions screen', (
      tester,
    ) async {
      await pumpHome(tester, [
        recentTransactionsOverride([makeTransactionItem(note: 'Lunch')]),
        _allOverride([makeTransactionItem(note: 'Lunch')]),
      ]);

      expect(find.text('See all'), findsOneWidget);
      await tester.tap(find.text('See all'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionsScreen), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);
    });

    testWidgets('not shown when empty', (tester) async {
      await pumpHome(tester, [recentTransactionsOverride(const [])]);
      expect(find.text('See all'), findsNothing);
      expect(find.text('No transactions yet'), findsOneWidget);
    });

    testWidgets('not shown while loading', (tester) async {
      await pumpHome(tester, [
        recentTransactionsProvider.overrideWith((ref) {
          final controller = StreamController<List<TransactionListItem>>();
          ref.onDispose(controller.close);
          return controller.stream;
        }),
      ]);
      expect(find.text('See all'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('not shown on error', (tester) async {
      await pumpHome(tester, [
        recentTransactionsProvider.overrideWith(
          (ref) => Stream<List<TransactionListItem>>.error(Exception('boom')),
        ),
      ]);
      expect(find.text('See all'), findsNothing);
      expect(find.text("Couldn't load transactions"), findsOneWidget);
    });
  });

  group('database-backed', () {
    Future<(DbHarness, String)> open(WidgetTester tester) async {
      final harness = DbHarness();
      late String userId;
      await tester.runAsync(() async {
        await ensureBaselineData(harness.db);
        userId = await ensureLocalUser(harness.db);
        final bank = await AccountsDao(harness.db).insert(
          userId: userId,
          name: 'Main bank',
          type: AccountType.bank,
          startingBalancePaise: 500000,
        );
        final cash = await AccountsDao(harness.db).insert(
          userId: userId,
          name: 'Wallet cash',
          type: AccountType.cash,
          startingBalancePaise: 0,
        );
        final dao = TransactionsDao(harness.db);
        final categories = CategoriesDao(harness.db);
        final food = (await categories.getBySeedKey(userId, 'exp_food'))!.id;
        final salary = (await categories.getBySeedKey(
          userId,
          'inc_salary',
        ))!.id;
        final at = DateTime.now().subtract(const Duration(minutes: 5));
        await dao.insert(
          userId: userId,
          accountId: bank,
          type: TransactionType.expense,
          amountPaise: 12000,
          categoryId: food,
          note: 'Lunch',
          occurredAt: at,
        );
        await dao.insert(
          userId: userId,
          accountId: bank,
          type: TransactionType.income,
          amountPaise: 900000,
          categoryId: salary,
          note: 'Pay day',
          occurredAt: at,
        );
        await dao.insert(
          userId: userId,
          accountId: bank,
          toAccountId: cash,
          type: TransactionType.transfer,
          amountPaise: 3000,
          note: 'Move cash',
          occurredAt: at,
        );
      });

      await pumpUi(
        tester,
        const FinanceHomeScreen(),
        container: harness.container,
        size: const Size(800, 1600),
      );
      await settleUntil(
        tester,
        () => find.text('See all').evaluate().isNotEmpty,
      );
      return (harness, userId);
    }

    final onScreen = find.byType(TransactionsScreen);

    testWidgets('See all opens the list, a chip filters, + adds a row live', (
      tester,
    ) async {
      final (harness, _) = await open(tester);

      expect(find.text('See all'), findsOneWidget);
      await tester.tap(find.text('See all'));
      await settle(tester, rounds: 8); // route transition
      await settleUntil(
        tester,
        () => find
            .descendant(of: onScreen, matching: find.text('Lunch'))
            .evaluate()
            .isNotEmpty,
      );
      Finder inList(String text) =>
          find.descendant(of: onScreen, matching: find.text(text));
      expect(onScreen, findsOneWidget);
      expect(inList('Lunch'), findsOneWidget);
      expect(inList('Pay day'), findsOneWidget);
      expect(inList('Move cash'), findsOneWidget);

      // A chip filters (in SQL; the stream for that filter loads lazily).
      await tapChip(tester, _chip('income'));
      await settleUntil(
        tester,
        () =>
            inList('Pay day').evaluate().isNotEmpty &&
            inList('Lunch').evaluate().isEmpty,
      );
      expect(inList('Pay day'), findsOneWidget);
      expect(inList('Lunch'), findsNothing);
      expect(inList('Move cash'), findsNothing);

      await tapChip(tester, _chip('all'));
      await settleUntil(
        tester,
        () =>
            inList('Lunch').evaluate().isNotEmpty &&
            inList('Pay day').evaluate().isNotEmpty,
      );

      // Add through the FAB on this screen; no reopening needed.
      await tester.tap(
        find.descendant(
          of: onScreen,
          matching: find.byType(FloatingActionButton),
        ),
      );
      await settle(tester, rounds: 10);
      expect(find.byType(TransactionFormSheet), findsOneWidget);

      final categoryField = find.byKey(const ValueKey('category_field'));
      await settleUntil(tester, () => categoryField.evaluate().isNotEmpty);
      await tester.ensureVisible(categoryField);
      await tester.tap(categoryField);
      await settle(tester, rounds: 6);
      final picker = find.byType(PickerSheet<String>);
      expect(picker, findsOneWidget);
      await tester.tap(
        find.descendant(of: picker, matching: find.text('Bills & Utilities')),
      );
      await settle(tester, rounds: 6);

      await tester.enterText(
        find.byKey(const ValueKey('tx_amount_field')),
        '100',
      );
      await tester.enterText(
        find.byKey(const ValueKey('tx_note_field')),
        'Gym',
      );
      final save = find.descendant(
        of: find.byType(TransactionFormSheet),
        matching: find.byType(ElevatedButton),
      );
      await tester.ensureVisible(save);
      await tester.tap(save);
      await settleUntil(
        tester,
        () =>
            inList('Gym').evaluate().isNotEmpty &&
            find.byType(TransactionFormSheet).evaluate().isEmpty,
      );

      expect(find.byType(TransactionFormSheet), findsNothing);
      expect(inList('Gym'), findsOneWidget);
      expect(inList('Lunch'), findsOneWidget);

      await harness.dispose(tester);
    });
  });
}
