import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/core/db/db_bootstrap.dart';
import 'package:vesper/features/finance/data/accounts_dao.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/data/categories_dao.dart';
import 'package:vesper/features/finance/data/categories_table.dart';
import 'package:vesper/features/finance/data/transactions_dao.dart';
import 'package:vesper/features/finance/data/transactions_table.dart';
import 'package:vesper/features/finance/presentation/categories_screen.dart';
import 'package:vesper/features/finance/presentation/finance_home_screen.dart';
import 'package:vesper/features/finance/presentation/widgets/category_form_sheet.dart';
import 'package:vesper/features/finance/presentation/widgets/transaction_form_sheet.dart';
import 'package:vesper/shared/widgets/picker_sheet.dart';

import '../../../support/ui_test_helpers.dart';

final _screen = find.byType(CategoriesScreen);
final _catSheet = find.byType(CategoryFormSheet);
final _txSheet = find.byType(TransactionFormSheet);
final _nameField = find.byKey(const ValueKey('cat_name_field'));
final _archiveButton = find.byKey(const ValueKey('cat_archive_button'));
final _catSave = find.descendant(
  of: _catSheet,
  matching: find.byType(ElevatedButton),
);
final _picker = find.byType(PickerSheet<String>);

Finder _row(String id) => find.byKey(ValueKey('category-row-$id'));
Finder _kindChip(String name) => find.byKey(ValueKey('categories-kind-$name'));
Finder _onScreen(Finder f) => find.descendant(of: _screen, matching: f);

class _Env {
  _Env(this.harness, this.userId, this.ids);

  final DbHarness harness;
  final String userId;

  /// seed key -> category id (food, rent, salary) plus 'tx' = the transaction.
  final Map<String, String> ids;

  AppDatabase get db => harness.db;
}

void main() {
  setUpAll(disableFontFetching);

  /// A real in-memory database with one account and one expense on "Food &
  /// Dining" (no note, so the row's title is the category name), and the
  /// Finance home shown. [prepare] may change the data first.
  Future<_Env> open(
    WidgetTester tester, {
    Future<void> Function(CategoriesDao dao, String userId)? prepare,
  }) async {
    final harness = DbHarness();
    late String userId;
    final ids = <String, String>{};
    await tester.runAsync(() async {
      await ensureBaselineData(harness.db);
      userId = await ensureLocalUser(harness.db);
      final categories = CategoriesDao(harness.db);
      for (final key in ['exp_food', 'exp_rent', 'inc_salary']) {
        ids[key] = (await categories.getBySeedKey(userId, key))!.id;
      }
      final bank = await AccountsDao(harness.db).insert(
        userId: userId,
        name: 'Main bank',
        type: AccountType.bank,
        startingBalancePaise: 500000,
      );
      ids['tx'] = await TransactionsDao(harness.db).insert(
        userId: userId,
        accountId: bank,
        type: TransactionType.expense,
        amountPaise: 12000,
        categoryId: ids['exp_food'],
        occurredAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      await prepare?.call(categories, userId);
    });

    await pumpUi(
      tester,
      const FinanceHomeScreen(),
      container: harness.container,
      size: const Size(800, 1600),
    );
    await settleUntil(
      tester,
      () => find
          .byKey(ValueKey('transaction-tile-${ids['tx']}'))
          .evaluate()
          .isNotEmpty,
    );
    return _Env(harness, userId, ids);
  }

  /// Waits until [finder] is on screen and has stopped moving (a bottom sheet
  /// finishing its slide-in), before anything inside it is tapped.
  Future<void> steady(WidgetTester tester, Finder finder) async {
    double? last;
    await settleUntil(tester, () {
      if (finder.evaluate().isEmpty) return false;
      final y = tester.getTopLeft(finder.first).dy;
      final done = last != null && (y - last!).abs() < 0.01;
      last = y;
      return done;
    });
  }

  Future<void> openCategories(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Categories'));
    await tester.tap(find.text('Categories'));
    await settleUntil(
      tester,
      () =>
          _screen.evaluate().isNotEmpty &&
          _onScreen(find.byType(Card)).evaluate().isNotEmpty,
    );
    await settle(tester, rounds: 8); // route transition
  }

  Future<void> backToHome(WidgetTester tester) async {
    await tester.pageBack();
    await settleUntil(tester, () => _screen.evaluate().isEmpty);
    await settle(tester, rounds: 4);
  }

  Future<void> openRow(WidgetTester tester, String id) async {
    await tester.ensureVisible(_row(id));
    await tester.tap(_row(id));
    await settleUntil(tester, () => _catSheet.evaluate().isNotEmpty);
    await steady(tester, _catSave);
    expect(find.text('Edit category'), findsOneWidget);
  }

  Future<void> openAddSheet(WidgetTester tester) async {
    await tester.tap(_onScreen(find.byType(FloatingActionButton)));
    await settleUntil(tester, () => _catSheet.evaluate().isNotEmpty);
    await steady(tester, _catSave);
    expect(find.text('Add category'), findsWidgets);
  }

  Future<void> typeName(WidgetTester tester, String text) async {
    await tester.enterText(_nameField, text);
    await tester.pump();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(_catSave);
    await tester.tap(_catSave);
    await settle(tester, rounds: 10);
  }

  Future<void> waitSheetClosed(WidgetTester tester) =>
      settleUntil(tester, () => _catSheet.evaluate().isEmpty);

  /// Opens the add-transaction sheet from the Finance home.
  Future<void> openTxSheet(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Add transaction'));
    await settleUntil(tester, () => _txSheet.evaluate().isNotEmpty);
    await steady(tester, find.byKey(const ValueKey('category_field')));
  }

  /// Opens the category picker of the (expense) add sheet and searches [text].
  Future<void> searchPicker(WidgetTester tester, String text) async {
    final field = find.byKey(const ValueKey('category_field'));
    await tester.ensureVisible(field);
    await tester.tap(field);
    await settle(tester, rounds: 6);
    expect(_picker, findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('picker_search')), text);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> closeTxSheet(WidgetTester tester) async {
    // Closes the picker, then the sheet (tapping the barrier above each).
    for (var i = 0; i < 2; i++) {
      await tester.tapAt(const Offset(5, 5));
      await settle(tester, rounds: 6);
    }
    expect(_txSheet, findsNothing);
  }

  Future<CategoryRow> byName(WidgetTester tester, _Env env, String name) async {
    final all = (await tester.runAsync(
      () => CategoriesDao(env.db).getAll(env.userId),
    ))!;
    return all.firstWhere((c) => c.name == name);
  }

  testWidgets('add a category: it shows in the list and in the picker', (
    tester,
  ) async {
    final env = await open(tester);
    await openCategories(tester);
    expect(_onScreen(find.text('Pets')), findsNothing);

    await openAddSheet(tester);
    await typeName(tester, '  Pets ');
    await tester.ensureVisible(
      find.byKey(const ValueKey('cat_icon_paw_print')),
    );
    await tester.tap(find.byKey(const ValueKey('cat_icon_paw_print')));
    await tester.pump();
    await save(tester);
    await waitSheetClosed(tester);

    await settleUntil(
      tester,
      () => _onScreen(find.text('Pets')).evaluate().isNotEmpty,
    );
    expect(_onScreen(find.text('Pets')), findsOneWidget);

    final pets = await byName(tester, env, 'Pets');
    expect(pets.kind, CategoryKind.expense);
    expect(pets.icon, 'paw_print');
    expect(pets.seedKey, isNull);
    expect(pets.isArchived, isFalse);

    // In the add-transaction sheet's category picker.
    await backToHome(tester);
    await openTxSheet(tester);
    await searchPicker(tester, 'Pets');
    expect(
      find.descendant(
        of: _picker,
        // Only the Text rows: find.text would also match the search field,
        // which holds the typed "Pets".
        matching: find.byWidgetPredicate((w) => w is Text && w.data == 'Pets'),
      ),
      findsOneWidget,
    );

    await env.harness.dispose(tester);
  });

  testWidgets('renaming a built-in changes the name on an existing row', (
    tester,
  ) async {
    final env = await open(tester);
    expect(find.text('Food & Dining'), findsWidgets); // the Recent row

    await openCategories(tester);
    await openRow(tester, env.ids['exp_food']!);
    expect(find.text('Built-in category'), findsOneWidget);
    await typeName(tester, 'Meals');
    await save(tester);
    await waitSheetClosed(tester);

    await settleUntil(
      tester,
      () => _onScreen(find.text('Meals')).evaluate().isNotEmpty,
    );
    expect(_onScreen(find.text('Food & Dining')), findsNothing);

    final meals = await byName(tester, env, 'Meals');
    expect(meals.id, env.ids['exp_food']);
    expect(meals.seedKey, 'exp_food');

    await backToHome(tester);
    // The existing transaction row (Recent) shows the new name.
    expect(find.text('Meals'), findsOneWidget);
    expect(find.text('Food & Dining'), findsNothing);

    await env.harness.dispose(tester);
  });

  testWidgets('archive hides a category from pickers; restore brings it back', (
    tester,
  ) async {
    final env = await open(tester);
    final foodChip = find.byKey(
      ValueKey('recent_category_chip_${env.ids['exp_food']}'),
    );

    // Before: it is a recent chip (they load lazily, so wait for it).
    await openTxSheet(tester);
    await settleUntil(tester, () => foodChip.evaluate().isNotEmpty);
    expect(foodChip, findsOneWidget);
    await closeTxSheet(tester);

    // Archive it (no confirmation).
    await openCategories(tester);
    await openRow(tester, env.ids['exp_food']!);
    expect(find.text('Archive category'), findsOneWidget);
    await tester.ensureVisible(_archiveButton);
    await tester.tap(_archiveButton);
    await waitSheetClosed(tester);
    await settle(tester, rounds: 6);

    expect(find.text('Category archived'), findsOneWidget);
    final archivedHeader = find.byKey(
      const ValueKey('categories-archived-header'),
    );
    await settleUntil(tester, () => archivedHeader.evaluate().isNotEmpty);
    expect(archivedHeader, findsOneWidget);
    expect(
      find.descendant(
        of: _row(env.ids['exp_food']!),
        matching: find.text('Archived \u00B7 Built-in'),
      ),
      findsOneWidget,
    );
    expect((await byName(tester, env, 'Food & Dining')).isArchived, isTrue);

    // The old transaction keeps showing it.
    await backToHome(tester);
    expect(find.text('Food & Dining'), findsOneWidget);

    // Gone from the recent chips and the picker. Give the lazily loaded
    // chips time to arrive, so "nothing" is not just "not loaded yet".
    await openTxSheet(tester);
    await settle(tester, rounds: 10);
    expect(foodChip, findsNothing);
    await searchPicker(tester, 'Food');
    expect(
      find.descendant(of: _picker, matching: find.text('Food & Dining')),
      findsNothing,
    );
    await closeTxSheet(tester);

    // Restore it.
    await openCategories(tester);
    await openRow(tester, env.ids['exp_food']!);
    expect(find.text('Restore category'), findsOneWidget);
    await tester.ensureVisible(_archiveButton);
    await tester.tap(_archiveButton);
    await waitSheetClosed(tester);
    await settle(tester, rounds: 6);
    expect(find.text('Category restored'), findsOneWidget);
    expect((await byName(tester, env, 'Food & Dining')).isArchived, isFalse);

    await backToHome(tester);
    await openTxSheet(tester);
    await settleUntil(tester, () => foodChip.evaluate().isNotEmpty);
    expect(foodChip, findsOneWidget);
    await searchPicker(tester, 'Food');
    expect(
      find.descendant(of: _picker, matching: find.text('Food & Dining')),
      findsOneWidget,
    );

    await env.harness.dispose(tester);
  });

  testWidgets('a duplicate name shows an inline error; the sheet stays', (
    tester,
  ) async {
    final env = await open(
      tester,
      prepare: (dao, userId) async {
        final rent = (await dao.getBySeedKey(userId, 'exp_rent'))!;
        await dao.setArchived(rent.id, true);
      },
    );
    await openCategories(tester);
    await openAddSheet(tester);

    // An active duplicate (a built-in), ignoring case.
    await typeName(tester, 'food & dining');
    await save(tester);
    expect(
      find.text('You already have a category with that name'),
      findsOneWidget,
    );
    expect(_catSheet, findsOneWidget);

    // An archived duplicate.
    await typeName(tester, 'rent');
    await save(tester);
    expect(
      find.text('A category with that name is in Archived'),
      findsOneWidget,
    );
    expect(_catSheet, findsOneWidget);

    // The buttons work again: a free name saves.
    await typeName(tester, 'Pets');
    await save(tester);
    await waitSheetClosed(tester);
    await settleUntil(
      tester,
      () => _onScreen(find.text('Pets')).evaluate().isNotEmpty,
    );
    expect(_onScreen(find.text('Pets')), findsOneWidget);

    await env.harness.dispose(tester);
  });

  testWidgets('both tabs: income and expense categories stay apart', (
    tester,
  ) async {
    final env = await open(tester);
    await openCategories(tester);

    // Expense tab (the default).
    expect(_onScreen(find.text('Food & Dining')), findsOneWidget);
    expect(_onScreen(find.text('Salary')), findsNothing);

    // Income tab.
    await tester.tap(_kindChip('income'));
    await settleUntil(
      tester,
      () => _onScreen(find.text('Salary')).evaluate().isNotEmpty,
    );
    expect(_onScreen(find.text('Salary')), findsOneWidget);
    expect(_onScreen(find.text('Food & Dining')), findsNothing);

    // Add an income category from the Income tab.
    await openAddSheet(tester);
    await typeName(tester, 'Freelance');
    await save(tester);
    await waitSheetClosed(tester);
    await settleUntil(
      tester,
      () => _onScreen(find.text('Freelance')).evaluate().isNotEmpty,
    );
    expect(_onScreen(find.text('Freelance')), findsOneWidget);

    final freelance = await byName(tester, env, 'Freelance');
    expect(freelance.kind, CategoryKind.income);

    // It is not on the Expense tab.
    await tester.tap(_kindChip('expense'));
    await settleUntil(
      tester,
      () => _onScreen(find.text('Food & Dining')).evaluate().isNotEmpty,
    );
    expect(_onScreen(find.text('Freelance')), findsNothing);

    // Editing keeps the kind (shown read-only).
    await tester.tap(_kindChip('income'));
    await settleUntil(tester, () => _row(freelance.id).evaluate().isNotEmpty);
    await openRow(tester, freelance.id);
    expect(find.text('Income category'), findsOneWidget);

    await env.harness.dispose(tester);
  });
}
