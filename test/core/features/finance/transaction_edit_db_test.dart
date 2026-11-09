import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/core/db/db_bootstrap.dart';
import 'package:vesper/core/utils/money.dart';
import 'package:vesper/features/finance/data/accounts_dao.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/data/categories_dao.dart';
import 'package:vesper/features/finance/data/transactions_dao.dart';
import 'package:vesper/features/finance/data/transactions_table.dart';
import 'package:vesper/features/finance/presentation/finance_home_screen.dart';
import 'package:vesper/features/finance/presentation/transactions_screen.dart';
import 'package:vesper/features/finance/presentation/widgets/transaction_form_sheet.dart';
import 'package:vesper/shared/widgets/picker_sheet.dart';

import '../../../support/ui_test_helpers.dart';

Finder _tile(String id) => find.byKey(ValueKey('transaction-tile-$id'));
final _amountField = find.byKey(const ValueKey('tx_amount_field'));
final _noteField = find.byKey(const ValueKey('tx_note_field'));
final _categoryField = find.byKey(const ValueKey('category_field'));
final _dateField = find.byKey(const ValueKey('tx_date_field'));
final _sheet = find.byType(TransactionFormSheet);
final _saveButton = find.descendant(
  of: _sheet,
  matching: find.byType(ElevatedButton),
);
final _picker = find.byType(PickerSheet<String>);

/// What a test's seed callback can use.
class _Seed {
  _Seed(this.db, this.userId, this.bank, this.cash);

  final AppDatabase db;
  final String userId;
  final String bank;
  final String cash;

  TransactionsDao get dao => TransactionsDao(db);

  Future<String> cat(String seedKey) async =>
      (await CategoriesDao(db).getBySeedKey(userId, seedKey))!.id;

  Future<void> archiveCategory(String id) =>
      (db.update(db.categories)..where((c) => c.id.equals(id))).write(
        const CategoriesCompanion(isArchived: Value(true)),
      );

  Future<void> archiveAccount(String id) =>
      (db.update(db.accounts)..where((a) => a.id.equals(id))).write(
        const AccountsCompanion(isArchived: Value(true)),
      );
}

class _Env {
  _Env(this.harness, this.userId, this.ids);

  final DbHarness harness;
  final String userId;
  final Map<String, String> ids;

  AppDatabase get db => harness.db;
}

void main() {
  setUpAll(disableFontFetching);

  /// A real in-memory database with two accounts ("Main bank" first, then
  /// "Wallet cash"), the Finance home shown, and the rows [seed] creates.
  /// [seed] returns name -> transaction id; the first one is waited for.
  Future<_Env> open(
    WidgetTester tester, {
    int bankStart = 500000,
    required Future<Map<String, String>> Function(_Seed s) seed,
  }) async {
    final harness = DbHarness();
    late String userId;
    late Map<String, String> ids;
    await tester.runAsync(() async {
      await ensureBaselineData(harness.db);
      userId = await ensureLocalUser(harness.db);
      final accounts = AccountsDao(harness.db);
      final bank = await accounts.insert(
        userId: userId,
        name: 'Main bank',
        type: AccountType.bank,
        startingBalancePaise: bankStart,
      );
      final cash = await accounts.insert(
        userId: userId,
        name: 'Wallet cash',
        type: AccountType.cash,
        startingBalancePaise: 0,
      );
      // Distinct created_at (whole seconds) so "Main bank" is the first.
      final base = DateTime(2026, 1, 1, 9);
      for (final (i, id) in [bank, cash].indexed) {
        await (harness.db.update(
          harness.db.accounts,
        )..where((t) => t.id.equals(id))).write(
          AccountsCompanion(createdAt: Value(base.add(Duration(seconds: i)))),
        );
      }
      ids = await seed(_Seed(harness.db, userId, bank, cash));
      ids['bank'] = bank;
      ids['cash'] = cash;
    });

    await pumpUi(
      tester,
      const FinanceHomeScreen(),
      container: harness.container,
      size: const Size(800, 1600),
    );
    await settleUntil(
      tester,
      () => _tile(ids.values.first).evaluate().isNotEmpty,
    );
    return _Env(harness, userId, ids);
  }

  Future<TransactionRow> row(WidgetTester tester, _Env env, String id) async =>
      (await tester.runAsync(() => TransactionsDao(env.db).getById(id)))!;

  Future<Map<String, int>> balances(WidgetTester tester, _Env env) async {
    final list = (await tester.runAsync(
      () => AccountsDao(env.db).watchAccountsWithBalance(env.userId).first,
    ))!;
    return {for (final a in list) a.account.name: a.balancePaise};
  }

  /// Waits until the bottom sheet has finished sliding in: its Save button
  /// is on screen and stops moving between rounds.
  Future<void> sheetSettled(WidgetTester tester) async {
    double? last;
    await settleUntil(tester, () {
      if (_saveButton.evaluate().isEmpty) return false;
      final y = tester.getTopLeft(_saveButton).dy;
      final steady = last != null && (y - last!).abs() < 0.01;
      last = y;
      return steady;
    });
  }

  /// Taps a row and waits for the edit sheet (and its categories) to show.
  /// [tile] narrows the row when two screens show the same one.
  Future<void> openEdit(WidgetTester tester, String id, {Finder? tile}) async {
    final row = tile ?? _tile(id);
    await tester.ensureVisible(row);
    await tester.tap(row);
    await settleUntil(tester, () => _sheet.evaluate().isNotEmpty);
    await settleUntil(tester, () => _categoryField.evaluate().isNotEmpty);
    await sheetSettled(tester);
    expect(find.text('Edit transaction'), findsOneWidget);
  }

  Future<void> chooseCategory(WidgetTester tester, String title) async {
    await tester.ensureVisible(_categoryField);
    await tester.tap(_categoryField);
    await settle(tester, rounds: 6);
    expect(_picker, findsOneWidget);
    await tester.tap(find.descendant(of: _picker, matching: find.text(title)));
    await settle(tester, rounds: 6);
    expect(_picker, findsNothing);
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(_saveButton);
    await tester.tap(_saveButton);
    await settle(tester, rounds: 12);
  }

  DateTime pastMoment() {
    final d = DateTime.now().subtract(const Duration(days: 3));
    return DateTime(d.year, d.month, d.day, 17, 42, 31);
  }

  testWidgets('edit amount, note and category: lists and balances update', (
    tester,
  ) async {
    final env = await open(
      tester,
      seed: (s) async => {
        'lunch': await s.dao.insert(
          userId: s.userId,
          accountId: s.bank,
          type: TransactionType.expense,
          amountPaise: 12000,
          categoryId: await s.cat('exp_food'),
          note: 'Lunch',
          occurredAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      },
    );
    expect((await balances(tester, env))['Main bank'], 500000 - 12000);

    await openEdit(tester, env.ids['lunch']!);
    // Pre-filled.
    expect(tester.widget<TextField>(_amountField).controller!.text, '120.00');
    expect(tester.widget<TextField>(_noteField).controller!.text, 'Lunch');

    await chooseCategory(tester, 'Groceries');
    await tester.enterText(_amountField, '250');
    await tester.enterText(_noteField, 'Dinner');
    await save(tester);
    await settleUntil(tester, () => _sheet.evaluate().isEmpty);

    expect(_sheet, findsNothing);
    final saved = await row(tester, env, env.ids['lunch']!);
    expect(saved.amount, 25000);
    expect(saved.note, 'Dinner');
    expect(
      saved.categoryId,
      (await tester.runAsync(
        () => CategoriesDao(env.db).getBySeedKey(env.userId, 'exp_groceries'),
      ))!.id,
    );
    expect((await balances(tester, env))['Main bank'], 500000 - 25000);

    // The Finance home shows it without a refresh.
    await settleUntil(tester, () => find.text('Dinner').evaluate().isNotEmpty);
    expect(find.text('Dinner'), findsOneWidget);
    expect(find.text('-\u20B9250.00'), findsOneWidget);
    expect(find.text('Lunch'), findsNothing);

    await env.harness.dispose(tester);
  });

  testWidgets('an untouched date keeps the exact stored occurred_at', (
    tester,
  ) async {
    final at = pastMoment();
    final env = await open(
      tester,
      seed: (s) async => {
        'old': await s.dao.insert(
          userId: s.userId,
          accountId: s.bank,
          type: TransactionType.expense,
          amountPaise: 4200,
          categoryId: await s.cat('exp_food'),
          note: 'Old one',
          occurredAt: at,
        ),
      },
    );

    await openEdit(tester, env.ids['old']!);
    await tester.enterText(_noteField, 'Old one, edited');
    await save(tester);
    await settleUntil(tester, () => _sheet.evaluate().isEmpty);

    final saved = await row(tester, env, env.ids['old']!);
    expect(saved.note, 'Old one, edited');
    expect(saved.occurredAt.isAtSameMomentAs(at), isTrue);
    expect(saved.occurredAt.hour, 17);
    expect(saved.occurredAt.minute, 42);
    expect(saved.occurredAt.second, 31);

    await env.harness.dispose(tester);
  });

  testWidgets('picking a date stores 12:00 on that day', (tester) async {
    final at = pastMoment();
    final env = await open(
      tester,
      seed: (s) async => {
        'old': await s.dao.insert(
          userId: s.userId,
          accountId: s.bank,
          type: TransactionType.expense,
          amountPaise: 4200,
          categoryId: await s.cat('exp_food'),
          occurredAt: at,
        ),
      },
    );

    await openEdit(tester, env.ids['old']!);
    await tester.ensureVisible(_dateField);
    await tester.tap(_dateField);
    await settle(tester, rounds: 10);
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await settle(tester, rounds: 10);
    await save(tester);
    await settleUntil(tester, () => _sheet.evaluate().isEmpty);

    final saved = await row(tester, env, env.ids['old']!);
    expect(
      saved.occurredAt.isAtSameMomentAs(DateTime(at.year, at.month, 1, 12)),
      isTrue,
    );

    await env.harness.dispose(tester);
  });

  testWidgets('a row with an ARCHIVED category can be edited (note only)', (
    tester,
  ) async {
    late String food;
    final env = await open(
      tester,
      seed: (s) async {
        food = await s.cat('exp_food');
        final id = await s.dao.insert(
          userId: s.userId,
          accountId: s.bank,
          type: TransactionType.expense,
          amountPaise: 7000,
          categoryId: food,
          note: 'Before',
          occurredAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        await s.archiveCategory(food);
        await s.archiveCategory(await s.cat('exp_transport'));
        return {'row': id};
      },
    );

    await openEdit(tester, env.ids['row']!);
    expect(
      find.descendant(
        of: _categoryField,
        matching: find.text('Food & Dining (archived)'),
      ),
      findsOneWidget,
    );

    // The picker offers the row's own archived category, and no other
    // archived one.
    await tester.ensureVisible(_categoryField);
    await tester.tap(_categoryField);
    await settle(tester, rounds: 6);
    expect(
      find.descendant(
        of: _picker,
        matching: find.text('Food & Dining (archived)'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _picker, matching: find.text('Transport')),
      findsNothing,
    );
    await tester.tap(
      find.descendant(
        of: _picker,
        matching: find.text('Food & Dining (archived)'),
      ),
    );
    await settle(tester, rounds: 6);

    await tester.enterText(_noteField, 'After');
    await save(tester);
    await settleUntil(tester, () => _sheet.evaluate().isEmpty);

    final saved = await row(tester, env, env.ids['row']!);
    expect(saved.note, 'After');
    expect(saved.categoryId, food);
    expect(saved.amount, 7000);

    await env.harness.dispose(tester);
  });

  testWidgets('a row on an ARCHIVED account asks for another account', (
    tester,
  ) async {
    final env = await open(
      tester,
      seed: (s) async {
        final id = await s.dao.insert(
          userId: s.userId,
          accountId: s.bank,
          type: TransactionType.expense,
          amountPaise: 3000,
          categoryId: await s.cat('exp_food'),
          note: 'On old account',
          occurredAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        await s.archiveAccount(s.bank);
        return {'row': id};
      },
    );

    await openEdit(tester, env.ids['row']!);
    final archivedChip = find.byKey(ValueKey('from_chip_${env.ids['bank']}'));
    expect(
      find.descendant(
        of: archivedChip,
        matching: find.text('Main bank (archived)'),
      ),
      findsOneWidget,
    );

    // Saved unchanged: an inline message, nothing written.
    await save(tester);
    expect(
      find.text('That account is archived. Choose another account.'),
      findsOneWidget,
    );
    expect(_sheet, findsOneWidget);
    expect(
      (await row(tester, env, env.ids['row']!)).accountId,
      env.ids['bank'],
    );

    // Choose another account: it saves.
    await tester.tap(find.byKey(ValueKey('from_chip_${env.ids['cash']}')));
    await tester.pump();
    await save(tester);
    await settleUntil(tester, () => _sheet.evaluate().isEmpty);

    expect(_sheet, findsNothing);
    expect(
      (await row(tester, env, env.ids['row']!)).accountId,
      env.ids['cash'],
    );

    await env.harness.dispose(tester);
  });

  testWidgets('both Recent and the full list open the edit sheet', (
    tester,
  ) async {
    final env = await open(
      tester,
      seed: (s) async => {
        'row': await s.dao.insert(
          userId: s.userId,
          accountId: s.bank,
          type: TransactionType.expense,
          amountPaise: 1500,
          categoryId: await s.cat('exp_food'),
          note: 'Tea',
          occurredAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      },
    );
    final id = env.ids['row']!;

    // From Recent.
    await openEdit(tester, id);
    expect(_sheet, findsOneWidget);
    await tester.tapAt(const Offset(5, 5)); // dismiss
    await settleUntil(tester, () => _sheet.evaluate().isEmpty);
    expect(_sheet, findsNothing);

    // From the full list.
    await tester.tap(find.text('See all'));
    final listRow = find.descendant(
      of: find.byType(TransactionsScreen),
      matching: _tile(id),
    );
    await settleUntil(tester, () => listRow.evaluate().isNotEmpty);
    await settle(tester, rounds: 8); // route transition
    await openEdit(tester, id, tile: listRow);
    expect(_sheet, findsOneWidget);
    expect(tester.widget<TextField>(_noteField).controller!.text, 'Tea');

    await env.harness.dispose(tester);
  });

  testWidgets('balanceOutOfRange shows inline and the row stays unchanged', (
    tester,
  ) async {
    final env = await open(
      tester,
      bankStart: Money.maxPaise - 50000,
      seed: (s) async => {
        'row': await s.dao.insert(
          userId: s.userId,
          accountId: s.bank,
          type: TransactionType.income,
          amountPaise: 10000,
          categoryId: await s.cat('inc_salary'),
          note: 'Bonus',
          occurredAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      },
    );

    await openEdit(tester, env.ids['row']!);
    // +1,000.00 instead of +100.00 would push the balance over the maximum.
    await tester.enterText(_amountField, '1000');
    await save(tester);

    expect(
      find.text('That would make an account balance too large'),
      findsOneWidget,
    );
    expect(_sheet, findsOneWidget);
    final saved = await row(tester, env, env.ids['row']!);
    expect(saved.amount, 10000);
    expect(saved.note, 'Bonus');

    await env.harness.dispose(tester);
  });
}
