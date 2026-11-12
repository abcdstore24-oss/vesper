import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/core/db/db_bootstrap.dart';
import 'package:vesper/features/finance/data/account_balance.dart';
import 'package:vesper/features/finance/data/accounts_dao.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/data/categories_dao.dart';
import 'package:vesper/features/finance/data/transactions_dao.dart';
import 'package:vesper/features/finance/data/transactions_table.dart';
import 'package:vesper/features/finance/presentation/accounts_screen.dart';
import 'package:vesper/features/finance/presentation/finance_home_screen.dart';
import 'package:vesper/features/finance/presentation/widgets/account_form_sheet.dart';
import 'package:vesper/features/finance/presentation/widgets/transaction_form_sheet.dart';

import '../../../support/ui_test_helpers.dart';

final _screen = find.byType(AccountsScreen);
final _acctSheet = find.byType(AccountFormSheet);
final _txSheet = find.byType(TransactionFormSheet);
final _archive = find.byKey(const ValueKey('acct_archive_button'));
final _delete = find.byKey(const ValueKey('acct_delete_button'));
final _restore = find.byKey(const ValueKey('acct_restore_button'));
final _archiveCaption = find.byKey(const ValueKey('acct_archive_caption'));
final _deleteCaption = find.byKey(const ValueKey('acct_delete_caption'));
final _header = find.byKey(const ValueKey('accounts-archived-header'));
final _confirm = find.byKey(const ValueKey('delete_account_confirm_button'));
final _cancel = find.byKey(const ValueKey('delete_account_cancel_button'));
final _dialog = find.byType(AlertDialog);
final _acctSave = find.descendant(
  of: _acctSheet,
  matching: find.byType(ElevatedButton),
);

Finder _row(String id) => find.byKey(ValueKey('account-row-$id'));
Finder _onScreen(Finder f) => find.descendant(of: _screen, matching: f);

class _Env {
  _Env(this.harness, this.userId, this.ids);

  final DbHarness harness;
  final String userId;

  /// main (non-zero balance), zero (zero balance WITH transactions), unused
  /// (zero balance, no transactions), expense category 'food'.
  final Map<String, String> ids;

  AppDatabase get db => harness.db;
}

void main() {
  setUpAll(disableFontFetching);

  /// A real in-memory database with three accounts and the Finance home shown:
  /// "Main bank" (balance 5,000), "Zero acct" (an income and an expense of
  /// 10 that net to zero) and "Unused" (nothing at all).
  Future<_Env> open(WidgetTester tester) async {
    final harness = DbHarness();
    late String userId;
    final ids = <String, String>{};
    await tester.runAsync(() async {
      await ensureBaselineData(harness.db);
      userId = await ensureLocalUser(harness.db);
      final accounts = AccountsDao(harness.db);
      final created = {
        'main': await accounts.insert(
          userId: userId,
          name: 'Main bank',
          type: AccountType.bank,
          startingBalancePaise: 500000,
        ),
        'zero': await accounts.insert(
          userId: userId,
          name: 'Zero acct',
          type: AccountType.wallet,
          startingBalancePaise: 0,
        ),
        'unused': await accounts.insert(
          userId: userId,
          name: 'Unused',
          type: AccountType.cash,
          startingBalancePaise: 0,
        ),
      };
      ids.addAll(created);
      // Distinct created_at (whole seconds) so the order is stable.
      final base = DateTime(2026, 1, 1, 9);
      for (final (i, id) in created.values.indexed) {
        await (harness.db.update(
          harness.db.accounts,
        )..where((t) => t.id.equals(id))).write(
          AccountsCompanion(createdAt: Value(base.add(Duration(seconds: i)))),
        );
      }
      final categories = CategoriesDao(harness.db);
      ids['food'] = (await categories.getBySeedKey(userId, 'exp_food'))!.id;
      final salary = (await categories.getBySeedKey(userId, 'inc_salary'))!.id;
      final tx = TransactionsDao(harness.db);
      final now = DateTime.now().subtract(const Duration(minutes: 5));
      await tx.insert(
        userId: userId,
        accountId: ids['zero']!,
        type: TransactionType.income,
        amountPaise: 1000,
        categoryId: salary,
        note: 'Old income',
        occurredAt: now,
      );
      await tx.insert(
        userId: userId,
        accountId: ids['zero']!,
        type: TransactionType.expense,
        amountPaise: 1000,
        categoryId: ids['food'],
        note: 'Old expense',
        occurredAt: now,
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
      () => find.text('Old income').evaluate().isNotEmpty,
    );
    return _Env(harness, userId, ids);
  }

  Future<List<AccountWithBalance>> accountList(
    WidgetTester tester,
    _Env env,
  ) async => (await tester.runAsync(
    () => AccountsDao(env.db).watchAccountsWithBalance(env.userId).first,
  ))!;

  Future<AccountRow?> accountRow(
    WidgetTester tester,
    _Env env,
    String id,
  ) async =>
      tester.runAsync<AccountRow?>(() => AccountsDao(env.db).getById(id));

  Future<void> openAccounts(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Accounts'));
    await tester.tap(find.text('Accounts'));
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

  /// Taps an account row and waits for the sheet to stop sliding.
  Future<void> openRow(WidgetTester tester, String id) async {
    await settleUntil(tester, () => _row(id).evaluate().isNotEmpty);
    await tester.ensureVisible(_row(id));
    await tester.tap(_row(id));
    await settleUntil(tester, () => _acctSheet.evaluate().isNotEmpty);
    await waitUntilSteady(tester, _acctSave);
    expect(find.text('Edit account'), findsOneWidget);
  }

  /// Waits until [button] is shown and enabled (the answers have loaded).
  Future<void> waitEnabled(WidgetTester tester, Finder button) => settleUntil(
    tester,
    () =>
        button.evaluate().isNotEmpty &&
        tester.widget<TextButton>(button).onPressed != null,
  );

  Future<void> waitSheetClosed(WidgetTester tester) =>
      settleUntil(tester, () => _acctSheet.evaluate().isEmpty);

  Future<void> openTxSheet(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Add transaction'));
    await settleUntil(tester, () => _txSheet.evaluate().isNotEmpty);
    await waitUntilSteady(tester, find.byKey(const ValueKey('category_field')));
  }

  Future<void> closeTxSheet(WidgetTester tester) async {
    await tester.tapAt(const Offset(5, 5));
    await settle(tester, rounds: 6);
    expect(_txSheet, findsNothing);
  }

  Finder fromChip(_Env env, String key) =>
      find.byKey(ValueKey('from_chip_${env.ids[key]}'));

  testWidgets('archive a zero-balance account, then restore it', (
    tester,
  ) async {
    final env = await open(tester);
    final before = await accountList(tester, env);
    final totalBefore = totalBalancePaise(before);
    expect(totalBefore, 500000);

    // Archive it.
    await openAccounts(tester);
    await openRow(tester, env.ids['zero']!);
    await waitEnabled(tester, _archive);
    await tester.ensureVisible(_archive);
    await tester.tap(_archive);
    await waitSheetClosed(tester);
    await settle(tester, rounds: 6);

    expect(find.text('Account archived'), findsOneWidget);
    await settleUntil(tester, () => _header.evaluate().isNotEmpty);
    expect(_header, findsOneWidget);
    expect(
      tester.getTopLeft(_row(env.ids['zero']!)).dy,
      greaterThan(tester.getTopLeft(_header).dy),
    );
    expect(
      tester.getTopLeft(_row(env.ids['main']!)).dy,
      lessThan(tester.getTopLeft(_header).dy),
    );
    expect(
      (await accountRow(tester, env, env.ids['zero']!))!.isArchived,
      isTrue,
    );
    expect(totalBalancePaise(await accountList(tester, env)), totalBefore);

    // Gone from the add-transaction account choices; the old transactions
    // still show the account's name.
    await backToHome(tester);
    expect(find.textContaining('Zero acct'), findsWidgets);
    await openTxSheet(tester);
    await settleUntil(
      tester,
      () => fromChip(env, 'main').evaluate().isNotEmpty,
    );
    expect(fromChip(env, 'unused'), findsOneWidget);
    expect(fromChip(env, 'zero'), findsNothing);
    await closeTxSheet(tester);

    // Restore it.
    // The "Account archived" SnackBar is still showing, and the next one
    // would wait behind it (SnackBars are shown one after another): clear it.
    ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold).first),
    ).clearSnackBars();
    await tester.pump();
    await openAccounts(tester);
    await openRow(tester, env.ids['zero']!);
    await waitEnabled(tester, _restore);
    await tester.ensureVisible(_restore);
    await tester.tap(_restore);
    await waitSheetClosed(tester);
    await settle(tester, rounds: 6);

    expect(find.text('Account restored'), findsOneWidget);
    expect(
      (await accountRow(tester, env, env.ids['zero']!))!.isArchived,
      isFalse,
    );
    await settleUntil(tester, () => _header.evaluate().isEmpty);

    await backToHome(tester);
    await openTxSheet(tester);
    await settleUntil(
      tester,
      () => fromChip(env, 'zero').evaluate().isNotEmpty,
    );
    expect(fromChip(env, 'zero'), findsOneWidget);

    await env.harness.dispose(tester);
  });

  testWidgets('delete an unused account through the dialog', (tester) async {
    final env = await open(tester);
    await openAccounts(tester);
    await openRow(tester, env.ids['unused']!);
    await waitEnabled(tester, _delete);

    await tester.ensureVisible(_delete);
    await tester.tap(_delete);
    await settleUntil(tester, () => _dialog.evaluate().isNotEmpty);
    expect(find.text('Delete this account?'), findsOneWidget);
    expect(
      find.text('It has no transactions and a zero starting balance.'),
      findsOneWidget,
    );

    await tester.tap(_confirm);
    await settleUntil(
      tester,
      () => _dialog.evaluate().isEmpty && _acctSheet.evaluate().isEmpty,
    );
    await settle(tester, rounds: 6);

    expect(find.text('Account deleted'), findsOneWidget);
    await settleUntil(
      tester,
      () => _row(env.ids['unused']!).evaluate().isEmpty,
    );
    expect(_row(env.ids['unused']!), findsNothing);
    expect(await accountRow(tester, env, env.ids['unused']!), isNull);
    // Only that one account is gone.
    expect(await accountRow(tester, env, env.ids['main']!), isNotNull);
    expect(await accountRow(tester, env, env.ids['zero']!), isNotNull);

    await env.harness.dispose(tester);
  });

  testWidgets('an account with a transaction shows no Delete button', (
    tester,
  ) async {
    final env = await open(tester);
    await openAccounts(tester);
    await openRow(tester, env.ids['zero']!);
    await waitEnabled(tester, _archive); // loaded (balance is zero)

    expect(_delete, findsNothing);
    expect(_deleteCaption, findsOneWidget);
    expect(
      find.text(
        "This account has transactions, so it can't be deleted. Archive it "
        'instead.',
      ),
      findsOneWidget,
    );

    await env.harness.dispose(tester);
  });

  testWidgets('a non-zero balance shows the caption and a disabled Archive', (
    tester,
  ) async {
    final env = await open(tester);
    await openAccounts(tester);
    await openRow(tester, env.ids['main']!);
    await waitEnabled(tester, _delete); // loaded (no transactions)

    expect(tester.widget<TextButton>(_archive).onPressed, isNull);
    expect(_archiveCaption, findsOneWidget);
    expect(
      find.text(
        'Bring the balance to zero first (for example, transfer the money to '
        'another account) to archive it.',
      ),
      findsOneWidget,
    );

    await env.harness.dispose(tester);
  });

  testWidgets('the race: a transaction appears while the dialog is open', (
    tester,
  ) async {
    final env = await open(tester);
    await openAccounts(tester);
    await openRow(tester, env.ids['unused']!);
    await waitEnabled(tester, _delete);
    await tester.ensureVisible(_delete);
    await tester.tap(_delete);
    await settleUntil(tester, () => _dialog.evaluate().isNotEmpty);

    // Meanwhile something records a transaction on that account.
    await tester.runAsync(() async {
      await TransactionsDao(env.db).insert(
        userId: env.userId,
        accountId: env.ids['unused']!,
        type: TransactionType.expense,
        amountPaise: 100,
        categoryId: env.ids['food'],
        occurredAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
    });

    await tester.tap(_confirm);
    final error = find.byKey(const ValueKey('delete_account_error'));
    await settleUntil(tester, () => error.evaluate().isNotEmpty);

    expect(
      find.text(
        "This account now has transactions, so it can't be deleted. Archive "
        'it instead.',
      ),
      findsOneWidget,
    );
    // The dialog stays open, the account stays, and the buttons work again.
    expect(_dialog, findsOneWidget);
    expect(await accountRow(tester, env, env.ids['unused']!), isNotNull);
    expect(tester.widget<TextButton>(_cancel).onPressed, isNotNull);
    expect(tester.widget<TextButton>(_confirm).onPressed, isNotNull);

    await tester.tap(_cancel);
    await settle(tester, rounds: 6);
    expect(_dialog, findsNothing);
    expect(_acctSheet, findsOneWidget);

    await env.harness.dispose(tester);
  });

  testWidgets('an archived account: only its name can be changed', (
    tester,
  ) async {
    final env = await open(tester);
    await tester.runAsync(
      () => AccountsDao(env.db).archive(env.ids['unused']!),
    );
    await openAccounts(tester);
    await settleUntil(tester, () => _header.evaluate().isNotEmpty);
    await openRow(tester, env.ids['unused']!);
    await waitEnabled(tester, _restore);

    for (final label in ['Bank', 'Cash', 'Wallet', 'Credit card', 'Other']) {
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
            .onSelected,
        isNull,
        reason: label,
      );
    }
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('account_amount_field')))
          .enabled,
      isFalse,
    );

    await tester.enterText(
      find.byKey(const ValueKey('account_name_field')),
      'Renamed',
    );
    await tester.ensureVisible(_acctSave);
    await tester.tap(_acctSave);
    await waitSheetClosed(tester);

    final row = (await accountRow(tester, env, env.ids['unused']!))!;
    expect(row.name, 'Renamed');
    expect(row.isArchived, isTrue);
    expect(row.type, AccountType.cash);
    expect(row.startingBalance, 0);

    await env.harness.dispose(tester);
  });
}
