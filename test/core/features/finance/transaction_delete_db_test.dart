import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/core/db/db_bootstrap.dart';
import 'package:vesper/core/utils/money.dart';
import 'package:vesper/features/finance/data/account_balance.dart';
import 'package:vesper/features/finance/data/accounts_dao.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/data/categories_dao.dart';
import 'package:vesper/features/finance/data/transactions_dao.dart';
import 'package:vesper/features/finance/data/transactions_table.dart';
import 'package:vesper/features/finance/presentation/finance_home_screen.dart';
import 'package:vesper/features/finance/presentation/transactions_screen.dart';
import 'package:vesper/features/finance/presentation/widgets/transaction_form_sheet.dart';

import '../../../support/ui_test_helpers.dart';

Finder _tile(String id) => find.byKey(ValueKey('transaction-tile-$id'));
final _sheet = find.byType(TransactionFormSheet);
final _dialog = find.byType(AlertDialog);
final _deleteButton = find.byKey(const ValueKey('tx_delete_button'));
final _confirm = find.byKey(const ValueKey('delete_confirm_button'));
final _cancel = find.byKey(const ValueKey('delete_cancel_button'));

class _Seed {
  _Seed(this.db, this.userId, this.acct);

  final AppDatabase db;
  final String userId;

  /// Account id by name ("Main bank", "Wallet cash", "Visa").
  final Map<String, String> acct;

  TransactionsDao get dao => TransactionsDao(db);

  Future<String> cat(String seedKey) async =>
      (await CategoriesDao(db).getBySeedKey(userId, seedKey))!.id;

  Future<String> expense(
    String account,
    int paise, {
    String? note,
    DateTime? at,
  }) async => dao.insert(
    userId: userId,
    accountId: acct[account]!,
    type: TransactionType.expense,
    amountPaise: paise,
    categoryId: await cat('exp_food'),
    note: note,
    occurredAt: at ?? DateTime.now().subtract(const Duration(minutes: 5)),
  );

  Future<String> income(String account, int paise, {String? note}) async =>
      dao.insert(
        userId: userId,
        accountId: acct[account]!,
        type: TransactionType.income,
        amountPaise: paise,
        categoryId: await cat('inc_salary'),
        note: note,
        occurredAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
}

class _Env {
  _Env(this.harness, this.userId, this.ids, this.acct);

  final DbHarness harness;
  final String userId;
  final Map<String, String> ids;
  final Map<String, String> acct;

  AppDatabase get db => harness.db;
}

void main() {
  setUpAll(disableFontFetching);

  /// A real in-memory database with "Main bank", "Wallet cash" and a credit
  /// card "Visa", the Finance home shown, and the rows [seed] creates
  /// (name -> transaction id; the first one is waited for).
  Future<_Env> open(
    WidgetTester tester, {
    int bankStart = 500000,
    required Future<Map<String, String>> Function(_Seed s) seed,
  }) async {
    final harness = DbHarness();
    late String userId;
    late Map<String, String> ids;
    final acct = <String, String>{};
    await tester.runAsync(() async {
      await ensureBaselineData(harness.db);
      userId = await ensureLocalUser(harness.db);
      final accounts = AccountsDao(harness.db);
      for (final (name, type, start) in [
        ('Main bank', AccountType.bank, bankStart),
        ('Wallet cash', AccountType.cash, 0),
        ('Visa', AccountType.creditCard, 0),
      ]) {
        acct[name] = await accounts.insert(
          userId: userId,
          name: name,
          type: type,
          startingBalancePaise: start,
        );
      }
      // Distinct created_at (whole seconds): "Main bank" is the first.
      final base = DateTime(2026, 1, 1, 9);
      for (final (i, id) in acct.values.indexed) {
        await (harness.db.update(
          harness.db.accounts,
        )..where((t) => t.id.equals(id))).write(
          AccountsCompanion(createdAt: Value(base.add(Duration(seconds: i)))),
        );
      }
      ids = await seed(_Seed(harness.db, userId, acct));
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
    return _Env(harness, userId, ids, acct);
  }

  Future<List<AccountWithBalance>> accountList(
    WidgetTester tester,
    _Env env,
  ) async => (await tester.runAsync(
    () => AccountsDao(env.db).watchAccountsWithBalance(env.userId).first,
  ))!;

  Future<Map<String, int>> balances(WidgetTester tester, _Env env) async => {
    for (final a in await accountList(tester, env))
      a.account.name: a.balancePaise,
  };

  Future<int> txCount(WidgetTester tester, _Env env) async =>
      (await tester.runAsync(
        () => env.db.select(env.db.transactions).get(),
      ))!.length;

  /// Waits until the edit sheet has finished sliding in (the Delete button
  /// stops moving between rounds); a tap during the slide would miss.
  Future<void> sheetSettled(WidgetTester tester) async {
    double? last;
    await settleUntil(tester, () {
      if (_deleteButton.evaluate().isEmpty) return false;
      final y = tester.getTopLeft(_deleteButton).dy;
      final steady = last != null && (y - last!).abs() < 0.01;
      last = y;
      return steady;
    });
  }

  /// Taps a row, waits for the edit sheet, taps Delete and waits for the
  /// confirm dialog. [tile] narrows the row when two screens show it.
  Future<void> openConfirm(
    WidgetTester tester,
    String id, {
    Finder? tile,
  }) async {
    final row = tile ?? _tile(id);
    await tester.ensureVisible(row);
    await tester.tap(row);
    await settleUntil(tester, () => _sheet.evaluate().isNotEmpty);
    // Not _categoryField: a transfer has no category field.
    await sheetSettled(tester);
    await tester.ensureVisible(_deleteButton);
    await tester.tap(_deleteButton);
    await settleUntil(tester, () => _dialog.evaluate().isNotEmpty);
    expect(find.text('Delete this transaction?'), findsOneWidget);
  }

  /// Confirms and waits for the dialog and the sheet to close.
  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(_confirm);
    await settleUntil(
      tester,
      () => _dialog.evaluate().isEmpty && _sheet.evaluate().isEmpty,
    );
    await settle(tester, rounds: 6);
  }

  testWidgets('delete an expense: gone from the list and Recent, balance up', (
    tester,
  ) async {
    final env = await open(
      tester,
      seed: (s) async => {
        'lunch': await s.expense('Main bank', 12000, note: 'Lunch'),
        'keep': await s.expense('Main bank', 5000, note: 'Keep me'),
      },
    );
    expect((await balances(tester, env))['Main bank'], 500000 - 17000);

    // From the full list. While the page slides in, the Finance home
    // underneath still has a tile with the same key, so look inside the list.
    Finder inList(String id) => find.descendant(
      of: find.byType(TransactionsScreen),
      matching: _tile(id),
    );
    await tester.tap(find.text('See all'));
    await settleUntil(
      tester,
      () => inList(env.ids['lunch']!).evaluate().isNotEmpty,
    );
    await settle(tester, rounds: 8);

    await openConfirm(
      tester,
      env.ids['lunch']!,
      tile: inList(env.ids['lunch']!),
    );
    expect(
      find.text('Main bank: balance goes up by \u20B9120.00'),
      findsOneWidget,
    );
    await confirm(tester);

    expect(_dialog, findsNothing);
    expect(_sheet, findsNothing);
    expect(find.text('Transaction deleted'), findsOneWidget);
    expect(inList(env.ids['lunch']!), findsNothing);
    expect(inList(env.ids['keep']!), findsOneWidget);
    expect((await balances(tester, env))['Main bank'], 500000 - 5000);

    // Recent (the Finance home underneath) updated too.
    await tester.pageBack();
    await settleUntil(
      tester,
      () => find.byType(TransactionsScreen).evaluate().isEmpty,
    );
    expect(find.text('Lunch'), findsNothing);
    expect(find.text('Keep me'), findsOneWidget);

    await env.harness.dispose(tester);
  });

  testWidgets('delete an income: the balance goes down', (tester) async {
    final env = await open(
      tester,
      seed: (s) async => {
        'pay': await s.income('Main bank', 900000, note: 'Pay'),
      },
    );
    expect((await balances(tester, env))['Main bank'], 500000 + 900000);

    await openConfirm(tester, env.ids['pay']!);
    expect(
      find.text('Main bank: balance goes down by \u20B99,000.00'),
      findsOneWidget,
    );
    await confirm(tester);

    expect(await txCount(tester, env), 0);
    expect((await balances(tester, env))['Main bank'], 500000);
    expect(find.text('Transaction deleted'), findsOneWidget);

    await env.harness.dispose(tester);
  });

  testWidgets('delete a transfer: both balances move back', (tester) async {
    final env = await open(
      tester,
      seed: (s) async => {
        'move': await s.dao.insert(
          userId: s.userId,
          accountId: s.acct['Main bank']!,
          toAccountId: s.acct['Wallet cash']!,
          type: TransactionType.transfer,
          amountPaise: 30000,
          note: 'Move cash',
          occurredAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      },
    );
    var b = await balances(tester, env);
    expect(b['Main bank'], 500000 - 30000);
    expect(b['Wallet cash'], 30000);

    await openConfirm(tester, env.ids['move']!);
    expect(
      find.text('Main bank: balance goes up by \u20B9300.00'),
      findsOneWidget,
    );
    expect(
      find.text('Wallet cash: balance goes down by \u20B9300.00'),
      findsOneWidget,
    );
    await confirm(tester);

    b = await balances(tester, env);
    expect(b['Main bank'], 500000);
    expect(b['Wallet cash'], 0);
    expect(await txCount(tester, env), 0);

    await env.harness.dispose(tester);
  });

  testWidgets('delete an expense on a credit card lowers the card dues', (
    tester,
  ) async {
    final env = await open(
      tester,
      seed: (s) async => {
        'swipe': await s.expense('Visa', 5000, note: 'Swipe'),
      },
    );
    expect(creditCardDuesPaise(await accountList(tester, env)), 5000);

    await openConfirm(tester, env.ids['swipe']!);
    expect(
      find.text('Visa: amount due goes down by \u20B950.00'),
      findsOneWidget,
    );
    await confirm(tester);

    expect(creditCardDuesPaise(await accountList(tester, env)), 0);
    expect((await balances(tester, env))['Visa'], 0);

    await env.harness.dispose(tester);
  });

  testWidgets('double-tapping Delete deletes exactly once', (tester) async {
    final env = await open(
      tester,
      seed: (s) async => {
        'row': await s.expense('Main bank', 12000, note: 'Once'),
      },
    );

    await openConfirm(tester, env.ids['row']!);
    // Two taps in the same frame: the second one must do nothing.
    await tester.tap(_confirm);
    await tester.tap(_confirm, warnIfMissed: false);
    await settleUntil(
      tester,
      () => _dialog.evaluate().isEmpty && _sheet.evaluate().isEmpty,
    );
    await settle(tester, rounds: 6);

    expect(await txCount(tester, env), 0);
    expect(find.text('Transaction deleted'), findsOneWidget);
    // A second delete would have said the row was already gone.
    expect(find.text('That transaction no longer exists'), findsNothing);
    expect((await balances(tester, env))['Main bank'], 500000);

    await env.harness.dispose(tester);
  });

  testWidgets('a row on an ARCHIVED account can be deleted', (tester) async {
    final env = await open(
      tester,
      seed: (s) async {
        final id = await s.expense('Main bank', 12000, note: 'Old account');
        await (s.db.update(s.db.accounts)
              ..where((a) => a.id.equals(s.acct['Main bank']!)))
            .write(const AccountsCompanion(isArchived: Value(true)));
        return {'row': id};
      },
    );

    await openConfirm(tester, env.ids['row']!);
    expect(
      find.text('Main bank: balance goes up by \u20B9120.00'),
      findsOneWidget,
    );
    await confirm(tester);

    expect(await txCount(tester, env), 0);
    expect((await balances(tester, env))['Main bank'], 500000);

    await env.harness.dispose(tester);
  });

  testWidgets('balanceOutOfRange shows inside the dialog; the row stays', (
    tester,
  ) async {
    // Balance at the maximum: expense 100 first, then an income of 100.
    // Deleting the expense would push the balance over the maximum.
    final env = await open(
      tester,
      bankStart: Money.maxPaise,
      seed: (s) async => {
        'expense': await s.expense('Main bank', 100, note: 'Small'),
        'income': await s.income('Main bank', 100, note: 'Back'),
      },
    );
    expect((await balances(tester, env))['Main bank'], Money.maxPaise);

    await openConfirm(tester, env.ids['expense']!);
    await tester.tap(_confirm);
    await settleUntil(
      tester,
      () => find.byKey(const ValueKey('delete_error')).evaluate().isNotEmpty,
    );

    expect(
      find.text(
        "Can't delete this: it would make an account balance too large.",
      ),
      findsOneWidget,
    );
    // The dialog stays open, the row stays, and the buttons work again.
    expect(_dialog, findsOneWidget);
    expect(_sheet, findsOneWidget);
    expect(await txCount(tester, env), 2);
    expect(tester.widget<TextButton>(_cancel).onPressed, isNotNull);
    expect(tester.widget<TextButton>(_confirm).onPressed, isNotNull);

    await tester.tap(_cancel);
    await settle(tester, rounds: 6);
    expect(_dialog, findsNothing);
    expect(_sheet, findsOneWidget);
    expect((await balances(tester, env))['Main bank'], Money.maxPaise);

    await env.harness.dispose(tester);
  });
}
