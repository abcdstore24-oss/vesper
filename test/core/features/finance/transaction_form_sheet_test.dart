import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/core/db/db_bootstrap.dart';
import 'package:vesper/core/utils/app_dates.dart';
import 'package:vesper/features/finance/data/account_balance.dart';
import 'package:vesper/features/finance/data/accounts_dao.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/data/categories_dao.dart';
import 'package:vesper/features/finance/data/categories_table.dart';
import 'package:vesper/features/finance/data/transactions_dao.dart';
import 'package:vesper/features/finance/data/transactions_table.dart';
import 'package:vesper/features/finance/presentation/finance_home_screen.dart';
import 'package:vesper/features/finance/presentation/providers/transactions_providers.dart';
import 'package:vesper/features/finance/presentation/widgets/account_form_sheet.dart';
import 'package:vesper/features/finance/presentation/widgets/transaction_form_sheet.dart';
import 'package:vesper/shared/widgets/picker_sheet.dart';

import '../../../support/ui_test_helpers.dart';

const _formatError = 'Enter an amount like 1250 or 1250.50 (up to 2 decimals)';

final _amountField = find.byKey(const ValueKey('tx_amount_field'));
final _noteField = find.byKey(const ValueKey('tx_note_field'));
final _dateField = find.byKey(const ValueKey('tx_date_field'));
final _saveButton = find.descendant(
  of: find.byType(TransactionFormSheet),
  matching: find.byType(ElevatedButton),
);

Finder _typeChip(TransactionType type) =>
    find.byKey(ValueKey('type_chip_${type.name}'));

final _categoryField = find.byKey(const ValueKey('category_field'));
final _fromField = find.byKey(const ValueKey('from_field'));
final _toField = find.byKey(const ValueKey('to_field'));

/// The open picker sheet (rows are chosen from inside it).
final _picker = find.byType(PickerSheet<String>);

/// Any one-tap "Recent" category chip.
final _anyRecentChip = find.byWidgetPredicate((w) {
  final key = w.key;
  return w is ChoiceChip &&
      key is ValueKey<String> &&
      key.value.startsWith('recent_category_chip_');
});

/// The text shown inside a picker field (its choice or its hint).
Finder _inField(Finder field, String text) =>
    find.descendant(of: field, matching: find.text(text));

String? _fieldError(WidgetTester tester, Finder field) => tester
    .widget<InputDecorator>(
      find.descendant(of: field, matching: find.byType(InputDecorator)),
    )
    .decoration
    .errorText;

/// True if [a] comes before [b] in reading order (row first, then left to
/// right), so chips that wrap onto a second line are still ordered.
bool _before(Offset a, Offset b) =>
    a.dy < b.dy - 1 || ((a.dy - b.dy).abs() <= 1 && a.dx < b.dx);
Finder _from(String id) => find.byKey(ValueKey('from_chip_$id'));
Finder _to(String id) => find.byKey(ValueKey('to_chip_$id'));

class _Acct {
  const _Acct(this.name, this.type, this.paise);

  final String name;
  final AccountType type;
  final int paise;
}

class _Env {
  _Env(this.harness, this.userId, this.ids);

  final DbHarness harness;
  final String userId;
  final Map<String, String> ids;

  AppDatabase get db => harness.db;
}

const _oneAccount = [_Acct('Main bank', AccountType.bank, 500000)];

void main() {
  setUpAll(disableFontFetching);

  /// A real in-memory database; accounts are created, bootstrap runs (unless
  /// [bootstrap] is false), the Finance home is shown and, optionally, the
  /// add-transaction sheet is opened.
  Future<_Env> open(
    WidgetTester tester, {
    List<_Acct> accounts = _oneAccount,
    bool bootstrap = true,
    bool openSheet = true,
    Future<void> Function(
      AppDatabase db,
      String userId,
      Map<String, String> accountIds,
    )?
    seed,
  }) async {
    final harness = DbHarness();
    late String userId;
    final ids = <String, String>{};
    await tester.runAsync(() async {
      if (bootstrap) await ensureBaselineData(harness.db);
      userId = await ensureLocalUser(harness.db);
      for (final a in accounts) {
        ids[a.name] = await AccountsDao(harness.db).insert(
          userId: userId,
          name: a.name,
          type: a.type,
          startingBalancePaise: a.paise,
        );
      }
      // created_at has whole-second resolution, so accounts inserted in a
      // loop share a second and would be ordered by NAME (and flip if the
      // loop crosses a second boundary). Give them distinct, increasing
      // times so "the first account" is the first in the list, every run.
      final base = DateTime(2026, 1, 1, 9);
      for (var i = 0; i < accounts.length; i++) {
        final id = ids[accounts[i].name]!;
        await (harness.db.update(
          harness.db.accounts,
        )..where((t) => t.id.equals(id))).write(
          AccountsCompanion(createdAt: Value(base.add(Duration(seconds: i)))),
        );
      }
      if (seed != null) await seed(harness.db, userId, ids);
    });

    await pumpUi(
      tester,
      const FinanceHomeScreen(),
      container: harness.container,
      size: const Size(800, 1600),
    );
    await settle(tester);

    if (openSheet) {
      await tester.tap(find.byType(FloatingActionButton));
      await settle(tester, rounds: 10);
      expect(find.byType(TransactionFormSheet), findsOneWidget);
    }
    return _Env(harness, userId, ids);
  }

  Future<List<TransactionRow>> rows(WidgetTester tester, _Env env) async =>
      (await tester.runAsync(() => env.db.select(env.db.transactions).get()))!;

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

  /// Taps a TYPE chip (Expense / Income / Transfer) and waits for the data
  /// that depends on it. The category field for the new kind needs its
  /// categories, which load lazily (a real async database query the first
  /// time the kind is shown), so a bare pump() is not enough before using it.
  Future<void> tapTypeChip(WidgetTester tester, TransactionType type) async {
    await tapChip(tester, _typeChip(type));
    await settle(tester, rounds: 4);
    if (type != TransactionType.transfer) {
      await settleUntil(tester, () => _categoryField.evaluate().isNotEmpty);
    }
  }

  /// Opens a picker field, taps the row with [title], and waits for the
  /// sheet to close.
  Future<void> chooseInPicker(
    WidgetTester tester,
    Finder field,
    String title,
  ) async {
    await tester.ensureVisible(field);
    await tester.tap(field);
    await settle(tester, rounds: 6);
    expect(_picker, findsOneWidget);
    await tester.tap(find.descendant(of: _picker, matching: find.text(title)));
    await settle(tester, rounds: 6);
    expect(_picker, findsNothing);
  }

  Future<void> chooseCategory(WidgetTester tester, String name) =>
      chooseInPicker(tester, _categoryField, name);

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(_saveButton);
    await tester.tap(_saveButton);
    await settle(tester);
  }

  group('saving', () {
    testWidgets('an expense: 1,250.50 with a note', (tester) async {
      final env = await open(tester);

      await chooseCategory(tester, 'Bills & Utilities');
      await tester.enterText(_amountField, '1,250.50');
      await tester.enterText(_noteField, 'Electricity bill');
      await save(tester);

      final saved = await rows(tester, env);
      expect(saved, hasLength(1));
      expect(saved.single.amount, 125050);
      expect(saved.single.type, TransactionType.expense);
      expect(saved.single.note, 'Electricity bill');
      expect(saved.single.accountId, env.ids['Main bank']);
      expect(saved.single.toAccountId, isNull);

      // The balance went down by exactly that.
      expect((await balances(tester, env))['Main bank'], 500000 - 125050);

      // The sheet closed and the Finance home shows the row, no refresh.
      expect(find.byType(TransactionFormSheet), findsNothing);
      expect(find.text('Electricity bill'), findsOneWidget);
      expect(find.text('-\u20B91,250.50'), findsOneWidget);

      await env.harness.dispose(tester);
    });

    testWidgets('an income', (tester) async {
      final env = await open(tester);

      await tapTypeChip(tester, TransactionType.income);
      await chooseCategory(tester, 'Salary');
      await tester.enterText(_amountField, '50000');
      await save(tester);

      final saved = await rows(tester, env);
      expect(saved.single.type, TransactionType.income);
      expect(saved.single.amount, 5000000);
      expect((await balances(tester, env))['Main bank'], 500000 + 5000000);

      expect(find.byType(TransactionFormSheet), findsNothing);
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('\u20B950,000.00'), findsOneWidget);

      await env.harness.dispose(tester);
    });

    testWidgets('a transfer moves both balances; the total is unchanged', (
      tester,
    ) async {
      final env = await open(
        tester,
        accounts: const [
          _Acct('Main bank', AccountType.bank, 500000),
          _Acct('Cash wallet', AccountType.cash, 0),
        ],
      );
      final totalBefore = totalBalancePaise(await accountList(tester, env));

      await tapTypeChip(tester, TransactionType.transfer);
      await tapChip(tester, _to(env.ids['Cash wallet']!));
      await tester.enterText(_amountField, '300');
      await save(tester);

      final saved = await rows(tester, env);
      expect(saved.single.type, TransactionType.transfer);
      expect(saved.single.amount, 30000);
      expect(saved.single.accountId, env.ids['Main bank']);
      expect(saved.single.toAccountId, env.ids['Cash wallet']);
      expect(saved.single.categoryId, isNull);

      expect(await balances(tester, env), {
        'Main bank': 470000,
        'Cash wallet': 30000,
      });
      expect(totalBalancePaise(await accountList(tester, env)), totalBefore);

      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('Main bank \u2192 Cash wallet'), findsOneWidget);
      // The date is shown under the amount, not in the subtitle.
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('\u20B9300.00'), findsOneWidget);

      await env.harness.dispose(tester);
    });

    testWidgets('double-tapping Save inserts exactly once', (tester) async {
      final env = await open(tester);

      await chooseCategory(tester, 'Groceries');
      await tester.enterText(_amountField, '100');
      await tester.ensureVisible(_saveButton);
      await tester.tap(_saveButton);
      await tester.tap(_saveButton);
      await settle(tester);

      expect(await rows(tester, env), hasLength(1));
      expect(find.byType(TransactionFormSheet), findsNothing);

      await env.harness.dispose(tester);
    });
  });

  group('validation (nothing is saved)', () {
    testWidgets('amount: empty, 0, 1.234 and 12,50', (tester) async {
      final env = await open(tester);
      await chooseCategory(tester, 'Groceries');

      for (final (text, message) in const [
        ('', _formatError),
        ('0', 'Enter an amount greater than 0'),
        ('1.234', _formatError),
        ('12,50', _formatError),
      ]) {
        await tester.enterText(_amountField, text);
        await tester.ensureVisible(_saveButton);
        await tester.tap(_saveButton);
        await tester.pump();
        expect(find.text(message), findsOneWidget, reason: 'for "$text"');
      }

      expect(await rows(tester, env), isEmpty);
      expect(find.byType(TransactionFormSheet), findsOneWidget);

      await env.harness.dispose(tester);
    });

    testWidgets('no category: "Choose a category"', (tester) async {
      final env = await open(tester);

      await tester.enterText(_amountField, '100');
      await tester.ensureVisible(_saveButton);
      await tester.tap(_saveButton);
      await tester.pump();

      // The hint inside the field says the same words, so read the error
      // from the field's decoration.
      expect(_fieldError(tester, _categoryField), 'Choose a category');
      expect(await rows(tester, env), isEmpty);

      await env.harness.dispose(tester);
    });

    testWidgets('a 101-character note is rejected inline', (tester) async {
      final env = await open(tester);

      await chooseCategory(tester, 'Groceries');
      await tester.enterText(_amountField, '100');
      await tester.enterText(_noteField, 'x' * 101);
      await save(tester);

      expect(
        find.text('Keep the note to 100 characters or fewer'),
        findsOneWidget,
      );
      expect(await rows(tester, env), isEmpty);
      expect(find.byType(TransactionFormSheet), findsOneWidget);

      await env.harness.dispose(tester);
    });

    testWidgets('a transfer needs a destination account', (tester) async {
      final env = await open(
        tester,
        accounts: const [
          _Acct('Main bank', AccountType.bank, 500000),
          _Acct('Cash wallet', AccountType.cash, 0),
        ],
      );

      await tapTypeChip(tester, TransactionType.transfer);
      await tester.enterText(_amountField, '100');
      await tester.ensureVisible(_saveButton);
      await tester.tap(_saveButton);
      await tester.pump();

      expect(find.text('Choose an account'), findsOneWidget);
      expect(await rows(tester, env), isEmpty);

      await env.harness.dispose(tester);
    });
  });

  group('choices', () {
    testWidgets('Transfer is disabled with a single account', (tester) async {
      final env = await open(tester);

      final chip = tester.widget<ChoiceChip>(
        _typeChip(TransactionType.transfer),
      );
      expect(chip.onSelected, isNull);
      expect(find.text('Add a second account to transfer'), findsOneWidget);

      await tester.tap(_typeChip(TransactionType.transfer));
      await tester.pump();
      expect(find.text('Paid from'), findsOneWidget); // still an expense

      await env.harness.dispose(tester);
    });

    testWidgets('"To" excludes the From account; changing From clears To', (
      tester,
    ) async {
      final env = await open(
        tester,
        accounts: const [
          _Acct('Main bank', AccountType.bank, 500000),
          _Acct('Cash wallet', AccountType.cash, 0),
          _Acct('Savings', AccountType.bank, 1000),
        ],
      );
      final main = env.ids['Main bank']!;
      final cash = env.ids['Cash wallet']!;
      final savings = env.ids['Savings']!;

      await tapTypeChip(tester, TransactionType.transfer);
      expect(find.text('From'), findsOneWidget);
      // The first account is preselected as From and is not offered as To.
      expect(tester.widget<ChoiceChip>(_from(main)).selected, isTrue);
      expect(_to(main), findsNothing);
      expect(_to(cash), findsOneWidget);
      expect(_to(savings), findsOneWidget);

      await tapChip(tester, _to(cash));
      expect(tester.widget<ChoiceChip>(_to(cash)).selected, isTrue);

      // Make Cash the From account: it can't also be To, so To is cleared.
      await tapChip(tester, _from(cash));
      expect(_to(cash), findsNothing);
      expect(_to(main), findsOneWidget);
      expect(tester.widget<ChoiceChip>(_to(main)).selected, isFalse);
      expect(tester.widget<ChoiceChip>(_to(savings)).selected, isFalse);

      await env.harness.dispose(tester);
    });

    testWidgets('switching Expense/Income clears the category', (tester) async {
      final env = await open(tester);

      // Nothing is preselected.
      expect(_inField(_categoryField, 'Choose a category'), findsOneWidget);

      await chooseCategory(tester, 'Groceries');
      expect(_inField(_categoryField, 'Groceries'), findsOneWidget);

      await tapTypeChip(tester, TransactionType.income);
      expect(_inField(_categoryField, 'Choose a category'), findsOneWidget);
      expect(_inField(_categoryField, 'Groceries'), findsNothing);

      await chooseCategory(tester, 'Salary');
      expect(_inField(_categoryField, 'Salary'), findsOneWidget);

      await tapTypeChip(tester, TransactionType.expense);
      expect(_inField(_categoryField, 'Choose a category'), findsOneWidget);
      expect(_inField(_categoryField, 'Salary'), findsNothing);

      await env.harness.dispose(tester);
    });

    testWidgets('labels follow the type', (tester) async {
      final env = await open(
        tester,
        accounts: const [
          _Acct('Main bank', AccountType.bank, 500000),
          _Acct('Cash wallet', AccountType.cash, 0),
        ],
      );

      expect(find.text('Paid from'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Add expense'),
        findsOneWidget,
      );

      await tapTypeChip(tester, TransactionType.income);
      expect(find.text('Received in'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Add income'), findsOneWidget);

      await tapTypeChip(tester, TransactionType.transfer);
      expect(find.text('From'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Add transfer'),
        findsOneWidget,
      );

      await env.harness.dispose(tester);
    });

    testWidgets('the first active account is the default', (tester) async {
      final env = await open(
        tester,
        accounts: const [
          _Acct('Main bank', AccountType.bank, 500000),
          _Acct('Cash wallet', AccountType.cash, 0),
        ],
      );

      expect(
        tester.widget<ChoiceChip>(_from(env.ids['Main bank']!)).selected,
        isTrue,
      );
      expect(
        tester.widget<ChoiceChip>(_from(env.ids['Cash wallet']!)).selected,
        isFalse,
      );

      await env.harness.dispose(tester);
    });
  });

  group('date', () {
    testWidgets('defaults to Today; Cancel keeps it', (tester) async {
      final env = await open(tester);

      expect(
        find.descendant(of: _dateField, matching: find.text('Today')),
        findsOneWidget,
      );

      await tester.ensureVisible(_dateField);
      await tester.tap(_dateField);
      await settle(tester, rounds: 10);
      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await settle(tester, rounds: 10);
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(
        find.descendant(of: _dateField, matching: find.text('Today')),
        findsOneWidget,
      );

      await env.harness.dispose(tester);
    });

    testWidgets('a picked past day is stored at 12:00', (tester) async {
      final env = await open(tester);
      final now = DateTime.now();
      final firstOfMonth = DateTime(now.year, now.month, 1);

      await tester.ensureVisible(_dateField);
      await tester.tap(_dateField);
      await settle(tester, rounds: 10);
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('OK'));
      await settle(tester, rounds: 10);

      expect(
        find.descendant(
          of: _dateField,
          matching: find.text(AppDates.format(firstOfMonth, now: now)),
        ),
        findsOneWidget,
      );

      await chooseCategory(tester, 'Groceries');
      await tester.enterText(_amountField, '100');
      await save(tester);

      final saved = (await rows(tester, env)).single;
      final expected = AppDates.occurredAtFor(firstOfMonth, DateTime.now());
      if (now.day == 1) {
        // Picked "today": the current time is kept.
        expect(saved.occurredAt.day, 1);
      } else {
        expect(saved.occurredAt.isAtSameMomentAs(expected), isTrue);
        expect(saved.occurredAt.hour, 12);
      }

      await env.harness.dispose(tester);
    });
  });

  group('edge states', () {
    testWidgets('no accounts: a message and an Add account button', (
      tester,
    ) async {
      final env = await open(tester, accounts: const []);

      expect(
        find.text('Add an account before recording transactions.'),
        findsOneWidget,
      );
      expect(_amountField, findsNothing);

      await tester.tap(
        find.descendant(
          of: find.byType(TransactionFormSheet),
          matching: find.widgetWithText(ElevatedButton, 'Add account'),
        ),
      );
      await settle(tester, rounds: 10);
      expect(find.byType(AccountFormSheet), findsOneWidget);

      await env.harness.dispose(tester);
    });

    testWidgets('no categories: a message and Save is blocked', (tester) async {
      final env = await open(tester, bootstrap: false);

      expect(find.text('No categories available'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(_saveButton);
      expect(button.onPressed, isNull);

      await env.harness.dispose(tester);
    });
  });

  group('category field and picker', () {
    testWidgets('a hint first, then the chosen category with its icon', (
      tester,
    ) async {
      final env = await open(tester);

      expect(_inField(_categoryField, 'Choose a category'), findsOneWidget);

      await chooseCategory(tester, 'Groceries');

      expect(_inField(_categoryField, 'Groceries'), findsOneWidget);
      expect(_inField(_categoryField, 'Choose a category'), findsNothing);
      expect(
        find.descendant(
          of: _categoryField,
          matching: find.byIcon(PhosphorIconsRegular.shoppingCart),
        ),
        findsOneWidget,
      );

      await env.harness.dispose(tester);
    });

    testWidgets(
      'the picker searches, shows a check, and cancel keeps the choice',
      (tester) async {
        final env = await open(tester);

        await tester.ensureVisible(_categoryField);
        await tester.tap(_categoryField);
        await settle(tester, rounds: 6);

        // 14 expense categories: more than the search threshold.
        expect(_picker, findsOneWidget);
        expect(find.byKey(const ValueKey('picker_search')), findsOneWidget);

        await tester.enterText(
          find.byKey(const ValueKey('picker_search')),
          'bil',
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.descendant(
            of: _picker,
            matching: find.text('Bills & Utilities'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: _picker, matching: find.text('Groceries')),
          findsNothing,
        );

        // Cancel (tap outside the sheet): nothing is chosen.
        await tester.tapAt(const Offset(10, 10));
        await settle(tester, rounds: 6);
        expect(_picker, findsNothing);
        expect(_inField(_categoryField, 'Choose a category'), findsOneWidget);

        // Choose one, reopen: the chosen row carries a check; cancel keeps it.
        await chooseCategory(tester, 'Groceries');
        await tester.tap(_categoryField);
        await settle(tester, rounds: 6);
        expect(
          find.descendant(
            of: _picker,
            matching: find.byIcon(PhosphorIconsRegular.check),
          ),
          findsOneWidget,
        );
        await tester.tapAt(const Offset(10, 10));
        await settle(tester, rounds: 6);
        expect(_inField(_categoryField, 'Groceries'), findsOneWidget);

        await env.harness.dispose(tester);
      },
    );
  });

  group('recent categories', () {
    // Past dates relative to the real clock (the DAO rejects future dates).
    Future<void> seedRecents(
      AppDatabase db,
      String userId,
      Map<String, String> ids,
    ) async {
      final dao = TransactionsDao(db);
      final categories = CategoriesDao(db);
      final account = ids['Main bank']!;
      final base = DateTime.now().subtract(const Duration(days: 60));
      DateTime day(int d) =>
          DateTime(base.year, base.month, base.day, 12).add(Duration(days: d));

      Future<void> add(
        String seedKey,
        int d, {
        TransactionType type = TransactionType.expense,
        TransactionSource? source,
      }) async {
        final category = (await categories.getBySeedKey(userId, seedKey))!;
        await dao.insert(
          userId: userId,
          accountId: account,
          type: type,
          amountPaise: 100,
          categoryId: category.id,
          occurredAt: day(d),
          source: source,
          sourceId: source == null ? null : 'src-1',
        );
      }

      await add('exp_rent', 1);
      await add('exp_groceries', 1);
      await add('exp_education', 2);
      await add('exp_travel', 3);
      await add('exp_gifts', 4);
      await add('exp_health', 5);
      await add('exp_transport', 6);
      await add('inc_salary', 7, type: TransactionType.income);
      await add('exp_entertainment', 10);
      await add(
        'sys_loan_given',
        11,
        source: TransactionSource.loan,
      ); // a sourced row
      await add('exp_groceries', 12);

      // Used most recently, but archived afterwards.
      await (db.update(db.categories)
            ..where((t) => t.seedKey.equals('exp_entertainment')))
          .write(const CategoriesCompanion(isArchived: Value(true)));
    }

    Finder chip(String name) => find.widgetWithText(ChoiceChip, name);

    testWidgets(
      'at most 5, newest use first, only matching active ordinary rows',
      (tester) async {
        final env = await open(tester, seed: seedRecents);
        await settleUntil(tester, () => _anyRecentChip.evaluate().isNotEmpty);

        expect(find.text('Recent'), findsOneWidget);
        expect(_anyRecentChip, findsNWidgets(5));

        // Newest use first: Groceries (used again on the latest day),
        // Transport, Health, Gifts, Travel.
        const expected = [
          'Groceries',
          'Transport',
          'Health',
          'Gifts & Donations',
          'Travel',
        ];
        for (final name in expected) {
          expect(chip(name), findsOneWidget, reason: name);
        }
        for (var i = 0; i < expected.length - 1; i++) {
          expect(
            _before(
              tester.getTopLeft(chip(expected[i])),
              tester.getTopLeft(chip(expected[i + 1])),
            ),
            isTrue,
            reason: '${expected[i]} should come before ${expected[i + 1]}',
          );
        }

        // Not offered: older than the 5th, archived, sourced/system, income.
        for (final name in [
          'Rent',
          'Education',
          'Entertainment',
          'Loan given',
          'Salary',
        ]) {
          expect(chip(name), findsNothing, reason: name);
        }

        await env.harness.dispose(tester);
      },
    );

    testWidgets('the Income list holds income categories only', (tester) async {
      final env = await open(tester, seed: seedRecents);
      await tapTypeChip(tester, TransactionType.income);
      await settleUntil(tester, () => _anyRecentChip.evaluate().isNotEmpty);

      expect(_anyRecentChip, findsOneWidget);
      expect(chip('Salary'), findsOneWidget);
      expect(chip('Groceries'), findsNothing);

      await env.harness.dispose(tester);
    });

    testWidgets('hidden when there is nothing recent', (tester) async {
      final env = await open(tester);
      await settle(tester, rounds: 6);

      expect(_categoryField, findsOneWidget);
      expect(_anyRecentChip, findsNothing);
      expect(find.text('Recent'), findsNothing);

      await env.harness.dispose(tester);
    });

    testWidgets(
      'tapping a chip selects it; the picker keeps the chips in sync',
      (tester) async {
        final env = await open(tester, seed: seedRecents);
        await settleUntil(tester, () => _anyRecentChip.evaluate().isNotEmpty);

        expect(tester.widget<ChoiceChip>(chip('Groceries')).selected, isFalse);

        await tapChip(tester, chip('Groceries'));
        expect(_inField(_categoryField, 'Groceries'), findsOneWidget);
        expect(tester.widget<ChoiceChip>(chip('Groceries')).selected, isTrue);

        // Choosing another one through the picker moves the selection.
        await chooseCategory(tester, 'Transport');
        expect(_inField(_categoryField, 'Transport'), findsOneWidget);
        expect(tester.widget<ChoiceChip>(chip('Transport')).selected, isTrue);
        expect(tester.widget<ChoiceChip>(chip('Groceries')).selected, isFalse);

        // A choice that is not among the recents leaves every chip unselected.
        await chooseCategory(tester, 'Rent');
        expect(_inField(_categoryField, 'Rent'), findsOneWidget);
        expect(tester.widget<ChoiceChip>(chip('Transport')).selected, isFalse);

        await env.harness.dispose(tester);
      },
    );

    testWidgets('a saved transaction shows up in the recents next time', (
      tester,
    ) async {
      final env = await open(tester);

      await chooseCategory(tester, 'Rent');
      await tester.enterText(_amountField, '100');
      await save(tester);
      expect(find.byType(TransactionFormSheet), findsNothing);

      await tester.tap(find.byType(FloatingActionButton));
      await settle(tester, rounds: 10);
      await settleUntil(tester, () => _anyRecentChip.evaluate().isNotEmpty);

      expect(chip('Rent'), findsOneWidget);
      expect(tester.widget<ChoiceChip>(chip('Rent')).selected, isFalse);

      await env.harness.dispose(tester);
    });
  });

  group('accounts: chips up to $accountChipsMax, a picker beyond', () {
    const four = [
      _Acct('Bank A', AccountType.bank, 500000),
      _Acct('Bank B', AccountType.bank, 0),
      _Acct('Cash C', AccountType.cash, 0),
      _Acct('Wallet D', AccountType.wallet, 0),
    ];
    const five = [...four, _Acct('Bank E', AccountType.bank, 0)];

    testWidgets('4 accounts keep the chips (From and To)', (tester) async {
      final env = await open(tester, accounts: four);

      expect(_fromField, findsNothing);
      for (final name in ['Bank A', 'Bank B', 'Cash C', 'Wallet D']) {
        expect(_from(env.ids[name]!), findsOneWidget, reason: name);
      }

      await tapTypeChip(tester, TransactionType.transfer);
      expect(_toField, findsNothing);
      expect(_to(env.ids['Bank A']!), findsNothing); // the From account
      for (final name in ['Bank B', 'Cash C', 'Wallet D']) {
        expect(_to(env.ids[name]!), findsOneWidget, reason: name);
      }

      await env.harness.dispose(tester);
    });

    testWidgets('5 accounts: picker fields, default From, To excludes From', (
      tester,
    ) async {
      final env = await open(tester, accounts: five);

      // From is a picker field showing the first account; no From chips.
      expect(_fromField, findsOneWidget);
      expect(_inField(_fromField, 'Bank A'), findsOneWidget);
      expect(_from(env.ids['Bank A']!), findsNothing);

      // Its picker: 5 rows with the account type as subtitle, no search.
      await tester.ensureVisible(_fromField);
      await tester.tap(_fromField);
      await settle(tester, rounds: 6);
      expect(_picker, findsOneWidget);
      expect(find.byKey(const ValueKey('picker_search')), findsNothing);
      for (final name in ['Bank A', 'Bank B', 'Cash C', 'Wallet D', 'Bank E']) {
        expect(
          find.descendant(of: _picker, matching: find.text(name)),
          findsOneWidget,
          reason: name,
        );
      }
      expect(
        find.descendant(of: _picker, matching: find.text('Wallet')),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(10, 10));
      await settle(tester, rounds: 6);

      // Transfer: To is a picker field that never offers the From account.
      await tapTypeChip(tester, TransactionType.transfer);
      expect(_toField, findsOneWidget);
      expect(_inField(_toField, 'Choose an account'), findsOneWidget);
      await tester.ensureVisible(_toField);
      await tester.tap(_toField);
      await settle(tester, rounds: 6);
      expect(
        find.descendant(of: _picker, matching: find.text('Bank A')),
        findsNothing,
      );
      for (final name in ['Bank B', 'Cash C', 'Wallet D', 'Bank E']) {
        expect(
          find.descendant(of: _picker, matching: find.text(name)),
          findsOneWidget,
          reason: name,
        );
      }
      await tester.tapAt(const Offset(10, 10));
      await settle(tester, rounds: 6);

      await env.harness.dispose(tester);
    });

    testWidgets('changing From so it equals To clears To', (tester) async {
      final env = await open(tester, accounts: five);

      await tapTypeChip(tester, TransactionType.transfer);
      await chooseInPicker(tester, _toField, 'Cash C');
      expect(_inField(_toField, 'Cash C'), findsOneWidget);

      await chooseInPicker(tester, _fromField, 'Cash C');
      expect(_inField(_fromField, 'Cash C'), findsOneWidget);
      expect(_inField(_toField, 'Choose an account'), findsOneWidget);
      expect(_inField(_toField, 'Cash C'), findsNothing);

      await env.harness.dispose(tester);
    });

    testWidgets('a transfer chosen through the pickers is saved', (
      tester,
    ) async {
      final env = await open(tester, accounts: five);

      await tapTypeChip(tester, TransactionType.transfer);
      await chooseInPicker(tester, _toField, 'Wallet D');
      await tester.enterText(_amountField, '100');
      await save(tester);

      final saved = (await rows(tester, env)).single;
      expect(saved.type, TransactionType.transfer);
      expect(saved.accountId, env.ids['Bank A']);
      expect(saved.toAccountId, env.ids['Wallet D']);
      expect(saved.amount, 10000);
      expect(await balances(tester, env), {
        'Bank A': 490000,
        'Bank B': 0,
        'Cash C': 0,
        'Wallet D': 10000,
        'Bank E': 0,
      });

      await env.harness.dispose(tester);
    });

    testWidgets('a transfer with no To chosen asks for one', (tester) async {
      final env = await open(tester, accounts: five);

      await tapTypeChip(tester, TransactionType.transfer);
      await tester.enterText(_amountField, '100');
      await tester.ensureVisible(_saveButton);
      await tester.tap(_saveButton);
      await tester.pump();

      expect(_fieldError(tester, _toField), 'Choose an account');
      expect(await rows(tester, env), isEmpty);

      await env.harness.dispose(tester);
    });
  });

  group('layout', () {
    testWidgets('40-character names do not overflow at 320dp, text scale 1.5', (
      tester,
    ) async {
      final accounts = [
        makeAccountRow(id: 'a1', name: 'A' * 40),
        makeAccountRow(id: 'a2', name: 'B' * 40, type: AccountType.wallet),
        makeAccountRow(id: 'a3', name: 'C' * 40, type: AccountType.creditCard),
      ];
      final categories = [
        for (var i = 0; i < 3; i++)
          CategoryRow(
            id: 'c$i',
            userId: 'user-1',
            name: String.fromCharCode(68 + i) * 40,
            icon: 'fork_knife',
            color: 0xFFC97B84,
            kind: CategoryKind.expense,
            isArchived: false,
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
      ];

      await pumpUi(
        tester,
        const Scaffold(body: TransactionFormSheet()),
        size: const Size(320, 1400),
        textScale: 1.5,
        overrides: [
          activeAccountsProvider.overrideWith((ref) => AsyncData(accounts)),
          categoriesByKindProvider.overrideWith(
            (ref, kind) => Stream.value(categories),
          ),
          recentCategoriesProvider.overrideWith(
            (ref, kind) => Stream.value(categories.take(2).toList()),
          ),
        ],
      );
      expect(tester.takeException(), isNull);

      // The category picker with 40-character names.
      await tapChip(tester, _categoryField);
      await tester.pumpAndSettle();
      expect(_picker, findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      await tapChip(tester, _typeChip(TransactionType.transfer));
      expect(tester.takeException(), isNull);
      expect(find.text('To'), findsOneWidget);
    });
  });
}
