import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/core/db/local_user_provider.dart';
import 'package:vesper/features/finance/data/accounts_dao.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/presentation/accounts_screen.dart';
import 'package:vesper/features/finance/presentation/widgets/account_form_sheet.dart';

import '../../../support/ui_test_helpers.dart';

final _nameField = find.byKey(const ValueKey('account_name_field'));
final _amountField = find.byKey(const ValueKey('account_amount_field'));
final _saveButton = find.descendant(
  of: find.byType(AccountFormSheet),
  matching: find.byType(ElevatedButton),
);

String _text(WidgetTester tester, Finder field) =>
    tester.widget<TextField>(field).controller!.text;

void main() {
  setUpAll(disableFontFetching);

  group('validation (no database involved)', () {
    Future<void> openSheet(WidgetTester tester) async {
      await pumpUi(
        tester,
        const AccountsScreen(),
        overrides: [accountsOverride(const [])],
      );
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.byType(AccountFormSheet), findsOneWidget);
    }

    testWidgets('add mode autofocuses the name field and defaults to Bank', (
      tester,
    ) async {
      await openSheet(tester);

      expect(tester.widget<TextField>(_nameField).autofocus, isTrue);
      expect(find.text('Add account'), findsWidgets);
      final bank = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Bank'),
      );
      expect(bank.selected, isTrue);
      for (final label in ['Cash', 'Wallet', 'Credit card', 'Other']) {
        expect(find.widgetWithText(ChoiceChip, label), findsOneWidget);
      }
      expect(find.text('Opening balance'), findsOneWidget);
      expect(find.text('Amount in rupees'), findsOneWidget);
    });

    testWidgets('empty name shows "Enter a name"', (tester) async {
      await openSheet(tester);

      await tester.tap(_saveButton);
      await tester.pump();

      expect(find.text('Enter a name'), findsOneWidget);
      expect(find.byType(AccountFormSheet), findsOneWidget);
    });

    testWidgets('"1.234" shows the amount error', (tester) async {
      await openSheet(tester);

      await tester.enterText(_nameField, 'Cash');
      await tester.enterText(_amountField, '1.234');
      await tester.tap(_saveButton);
      await tester.pump();

      expect(
        find.text('Enter an amount like 1250 or 1250.50 (up to 2 decimals)'),
        findsOneWidget,
      );
      expect(find.byType(AccountFormSheet), findsOneWidget);
    });

    testWidgets('"12,50" is rejected, not read as 1,250 rupees', (
      tester,
    ) async {
      await openSheet(tester);

      await tester.enterText(_nameField, 'Cash');
      await tester.enterText(_amountField, '12,50');
      await tester.tap(_saveButton);
      await tester.pump();

      expect(
        find.text('Enter an amount like 1250 or 1250.50 (up to 2 decimals)'),
        findsOneWidget,
      );
      expect(find.byType(AccountFormSheet), findsOneWidget);
    });

    testWidgets('switching type keeps the typed text, changes the meaning', (
      tester,
    ) async {
      await openSheet(tester);

      await tester.enterText(_amountField, '500');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Credit card'));
      await tester.pump();

      expect(_text(tester, _amountField), '500');
      expect(find.text('Amount owed'), findsOneWidget);
      expect(find.text('Leave empty if you owe nothing'), findsOneWidget);
      expect(find.text('Opening balance'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Wallet'));
      await tester.pump();
      expect(_text(tester, _amountField), '500');
      expect(find.text('Opening balance'), findsOneWidget);
    });

    testWidgets('a card amount cannot be negative', (tester) async {
      await openSheet(tester);

      await tester.enterText(_nameField, 'Visa');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Credit card'));
      await tester.pump();
      await tester.enterText(_amountField, '-5');
      await tester.tap(_saveButton);
      await tester.pump();

      expect(
        find.text('Enter an amount like 1250 or 1250.50 (up to 2 decimals)'),
        findsOneWidget,
      );
    });
  });

  group('saving (in-memory database, no bootstrap)', () {
    late DbHarness harness;

    setUp(() {
      harness = DbHarness();
    });

    Future<String> userId(WidgetTester tester) async {
      return (await tester.runAsync(
        () => harness.container.read(localUserIdProvider.future),
      ))!;
    }

    Future<List<AccountRow>> allAccounts(WidgetTester tester) async {
      final id = await userId(tester);
      return (await tester.runAsync(() => AccountsDao(harness.db).getAll(id)))!;
    }

    Future<String> addAccount(
      WidgetTester tester,
      String name,
      AccountType type,
      int paise,
    ) async {
      final id = await userId(tester);
      return (await tester.runAsync(
        () => AccountsDao(harness.db).insert(
          userId: id,
          name: name,
          type: type,
          startingBalancePaise: paise,
        ),
      ))!;
    }

    Future<void> pumpAccounts(WidgetTester tester) async {
      await pumpUi(
        tester,
        const AccountsScreen(),
        container: harness.container,
      );
      await settle(tester);
    }

    Future<void> openAddSheet(WidgetTester tester) async {
      await tester.tap(find.byType(FloatingActionButton));
      await settle(tester, rounds: 10);
      expect(find.byType(AccountFormSheet), findsOneWidget);
    }

    Future<void> openEditSheet(WidgetTester tester, String accountId) async {
      await tester.tap(find.byKey(ValueKey('account-row-$accountId')));
      await settle(tester, rounds: 10);
      expect(find.text('Edit account'), findsOneWidget);
    }

    testWidgets('duplicate name (case-insensitive) is rejected inline', (
      tester,
    ) async {
      await addAccount(tester, 'Cash', AccountType.cash, 0);
      await pumpAccounts(tester);
      await openAddSheet(tester);

      await tester.enterText(_nameField, 'cASH');
      await tester.tap(_saveButton);
      await settle(tester, rounds: 10);

      expect(
        find.text('You already have an account with this name'),
        findsOneWidget,
      );
      expect(find.byType(AccountFormSheet), findsOneWidget);
      expect(await allAccounts(tester), hasLength(1));

      await harness.dispose(tester);
    });

    testWidgets('a name over 40 characters is rejected inline', (tester) async {
      await pumpAccounts(tester);
      await openAddSheet(tester);

      await tester.enterText(_nameField, 'x' * 41);
      await tester.tap(_saveButton);
      await settle(tester, rounds: 10);

      expect(find.text('Keep it to 40 characters or fewer'), findsOneWidget);
      expect(await allAccounts(tester), isEmpty);

      await harness.dispose(tester);
    });

    testWidgets('card "1200.50" is stored as -120050', (tester) async {
      await pumpAccounts(tester);
      await openAddSheet(tester);

      await tester.enterText(_nameField, 'Visa');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Credit card'));
      await tester.pump();
      await tester.enterText(_amountField, '1200.50');
      await tester.tap(_saveButton);
      await settle(tester);

      final accounts = await allAccounts(tester);
      expect(accounts, hasLength(1));
      expect(accounts.single.name, 'Visa');
      expect(accounts.single.type, AccountType.creditCard);
      expect(accounts.single.startingBalance, -120050);
      expect(find.byType(AccountFormSheet), findsNothing);

      await harness.dispose(tester);
    });

    testWidgets('non-card accepts a leading minus (overdraft)', (tester) async {
      await pumpAccounts(tester);
      await openAddSheet(tester);

      await tester.enterText(_nameField, 'Current');
      await tester.enterText(_amountField, '-500');
      await tester.tap(_saveButton);
      await settle(tester);

      final accounts = await allAccounts(tester);
      expect(accounts.single.type, AccountType.bank);
      expect(accounts.single.startingBalance, -50000);

      await harness.dispose(tester);
    });

    testWidgets('empty amount saves as 0 and the name is trimmed', (
      tester,
    ) async {
      await pumpAccounts(tester);
      await openAddSheet(tester);

      await tester.enterText(_nameField, '  Pocket  ');
      await tester.tap(_saveButton);
      await settle(tester);

      final accounts = await allAccounts(tester);
      expect(accounts.single.name, 'Pocket');
      expect(accounts.single.startingBalance, 0);

      await harness.dispose(tester);
    });

    testWidgets('edit round-trips the stored value into the field', (
      tester,
    ) async {
      final bankId = await addAccount(
        tester,
        'Savings',
        AccountType.bank,
        125050,
      );
      final cardId = await addAccount(
        tester,
        'Visa',
        AccountType.creditCard,
        -120050,
      );
      await pumpAccounts(tester);

      // Bank: Money.format without the symbol.
      await openEditSheet(tester, bankId);
      expect(_text(tester, _nameField), 'Savings');
      expect(_text(tester, _amountField), '1,250.50');
      expect(find.text('Opening balance'), findsOneWidget);
      expect(tester.widget<TextField>(_nameField).autofocus, isFalse);
      await tester.tap(_saveButton);
      await settle(tester);
      expect(find.byType(AccountFormSheet), findsNothing);

      // Card: the amount OWED, positive.
      await openEditSheet(tester, cardId);
      expect(_text(tester, _amountField), '1,200.50');
      expect(find.text('Amount owed'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Credit card'))
            .selected,
        isTrue,
      );
      // Saving without touching anything must not change the balance.
      await tester.tap(_saveButton);
      await settle(tester);

      var accounts = {for (final a in await allAccounts(tester)) a.id: a};
      expect(accounts[bankId]!.startingBalance, 125050);
      expect(accounts[cardId]!.startingBalance, -120050);

      // Editing the amount stores the new value (negated for a card).
      await openEditSheet(tester, cardId);
      await tester.enterText(_amountField, '99');
      await tester.tap(_saveButton);
      await settle(tester);

      accounts = {for (final a in await allAccounts(tester)) a.id: a};
      expect(accounts[cardId]!.startingBalance, -9900);

      await harness.dispose(tester);
    });

    testWidgets('edit: renaming to another account\'s name is rejected', (
      tester,
    ) async {
      await addAccount(tester, 'Cash', AccountType.cash, 0);
      final bankId = await addAccount(tester, 'Bank', AccountType.bank, 0);
      await pumpAccounts(tester);

      await openEditSheet(tester, bankId);
      await tester.enterText(_nameField, 'cash');
      await tester.tap(_saveButton);
      await settle(tester, rounds: 10);

      expect(
        find.text('You already have an account with this name'),
        findsOneWidget,
      );
      expect(find.byType(AccountFormSheet), findsOneWidget);

      await harness.dispose(tester);
    });

    testWidgets('double-tapping Save inserts exactly once', (tester) async {
      await pumpAccounts(tester);
      await openAddSheet(tester);

      await tester.enterText(_nameField, 'Cash');
      await tester.tap(_saveButton);
      await tester.tap(_saveButton);
      await settle(tester);

      expect(await allAccounts(tester), hasLength(1));
      expect(find.byType(AccountFormSheet), findsNothing);

      await harness.dispose(tester);
    });
  });

  group('edit: switching between card and non-card', () {
    late DbHarness harness;

    setUp(() {
      harness = DbHarness();
    });

    Future<String> userId(WidgetTester tester) async {
      return (await tester.runAsync(
        () => harness.container.read(localUserIdProvider.future),
      ))!;
    }

    Future<AccountRow> onlyAccount(WidgetTester tester) async {
      final id = await userId(tester);
      return (await tester.runAsync(
        () => AccountsDao(harness.db).getAll(id),
      ))!.single;
    }

    Future<void> openEditFor(
      WidgetTester tester,
      String name,
      AccountType type,
      int paise,
    ) async {
      final id = await userId(tester);
      final accountId = (await tester.runAsync(
        () => AccountsDao(harness.db).insert(
          userId: id,
          name: name,
          type: type,
          startingBalancePaise: paise,
        ),
      ))!;
      await pumpUi(
        tester,
        const AccountsScreen(),
        container: harness.container,
      );
      await settle(tester);
      await tester.tap(find.byKey(ValueKey('account-row-$accountId')));
      await settle(tester, rounds: 10);
      expect(find.text('Edit account'), findsOneWidget);
    }

    Future<void> pickType(WidgetTester tester, String label) async {
      await tester.tap(find.widgetWithText(ChoiceChip, label));
      await tester.pump();
    }

    testWidgets('card owing 1200.50 -> Bank, untouched, Save keeps -120050', (
      tester,
    ) async {
      await openEditFor(tester, 'Visa', AccountType.creditCard, -120050);
      expect(_text(tester, _amountField), '1,200.50');

      await pickType(tester, 'Bank');
      // Re-rendered from the STORED balance in the new meaning.
      expect(_text(tester, _amountField), '-1,200.50');
      expect(find.text('Opening balance'), findsOneWidget);

      await tester.tap(_saveButton);
      await settle(tester);

      final account = await onlyAccount(tester);
      expect(account.type, AccountType.bank);
      expect(account.startingBalance, -120050);
      expect(find.byType(AccountFormSheet), findsNothing);

      await harness.dispose(tester);
    });

    testWidgets(
      'Bank overdraft -500 -> Credit card, untouched: field "500.00"',
      (tester) async {
        await openEditFor(tester, 'Current', AccountType.bank, -50000);
        expect(_text(tester, _amountField), '-500.00');

        await pickType(tester, 'Credit card');
        expect(_text(tester, _amountField), '500.00');
        expect(find.text('Amount owed'), findsOneWidget);

        await tester.tap(_saveButton);
        await settle(tester);

        final account = await onlyAccount(tester);
        expect(account.type, AccountType.creditCard);
        expect(account.startingBalance, -50000);

        await harness.dispose(tester);
      },
    );

    testWidgets(
      'Bank +1000 -> Credit card, untouched: Save asks for the amount',
      (tester) async {
        await openEditFor(tester, 'Savings', AccountType.bank, 100000);
        expect(_text(tester, _amountField), '1,000.00');

        await pickType(tester, 'Credit card');
        expect(_text(tester, _amountField), '');

        await tester.tap(_saveButton);
        await settle(tester, rounds: 10);

        expect(find.text('Enter the amount owed (0 if none)'), findsOneWidget);
        expect(find.byType(AccountFormSheet), findsOneWidget);
        var account = await onlyAccount(tester);
        expect(account.type, AccountType.bank);
        expect(account.startingBalance, 100000);

        // Typing an amount clears the error and saves it as owed.
        await tester.enterText(_amountField, '0');
        await tester
            .pump(); // rebuilds: errorText becomes null, the fade starts
        // The decorator cross-fades its helper/error text over 167 ms (see
        // _HelperErrorState in Flutter's input_decorator.dart), and the old
        // error Text stays in the tree until that fade finishes. The fade starts
        // inside the rebuild above, so it needs a pump AFTER the rebuild.
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Enter the amount owed (0 if none)'), findsNothing);
        await tester.tap(_saveButton);
        await settle(tester);

        account = await onlyAccount(tester);
        expect(account.type, AccountType.creditCard);
        expect(account.startingBalance, 0);

        await harness.dispose(tester);
      },
    );

    testWidgets('a touched amount keeps the typed text when the type changes', (
      tester,
    ) async {
      await openEditFor(tester, 'Savings', AccountType.bank, 125050);

      await tester.enterText(_amountField, '77');
      await pickType(tester, 'Credit card');
      expect(_text(tester, _amountField), '77');
      expect(find.text('Amount owed'), findsOneWidget);

      await tester.tap(_saveButton);
      await settle(tester);

      final account = await onlyAccount(tester);
      expect(account.type, AccountType.creditCard);
      expect(account.startingBalance, -7700);

      await harness.dispose(tester);
    });

    testWidgets('switching back restores the original prefill', (tester) async {
      await openEditFor(tester, 'Visa', AccountType.creditCard, -120050);

      await pickType(tester, 'Bank');
      expect(_text(tester, _amountField), '-1,200.50');
      await pickType(tester, 'Credit card');
      expect(_text(tester, _amountField), '1,200.50');
      await pickType(tester, 'Wallet');
      expect(_text(tester, _amountField), '-1,200.50');
      await pickType(tester, 'Credit card');
      expect(_text(tester, _amountField), '1,200.50');

      // Saving after returning to the original type changes nothing.
      await tester.tap(_saveButton);
      await settle(tester);
      expect((await onlyAccount(tester)).startingBalance, -120050);

      await harness.dispose(tester);
    });

    testWidgets('Bank +1000 -> Card -> back to Bank: no error, unchanged', (
      tester,
    ) async {
      await openEditFor(tester, 'Savings', AccountType.bank, 100000);

      await pickType(tester, 'Credit card');
      expect(_text(tester, _amountField), '');
      await pickType(tester, 'Bank');
      expect(_text(tester, _amountField), '1,000.00');

      await tester.tap(_saveButton);
      await settle(tester);

      final account = await onlyAccount(tester);
      expect(account.type, AccountType.bank);
      expect(account.startingBalance, 100000);
      expect(find.byType(AccountFormSheet), findsNothing);

      await harness.dispose(tester);
    });

    testWidgets('switching between two non-card types leaves the text alone', (
      tester,
    ) async {
      await openEditFor(tester, 'Savings', AccountType.bank, 125050);

      await pickType(tester, 'Cash');
      expect(_text(tester, _amountField), '1,250.50');
      await pickType(tester, 'Other');
      expect(_text(tester, _amountField), '1,250.50');

      await harness.dispose(tester);
    });

    testWidgets('a card with a positive balance saves untouched, unchanged', (
      tester,
    ) async {
      await openEditFor(tester, 'Amex', AccountType.creditCard, 5000);
      expect(_text(tester, _amountField), '');

      await tester.tap(_saveButton);
      await settle(tester);

      // No error: the type didn't change, and the balance is left alone.
      expect(find.byType(AccountFormSheet), findsNothing);
      final account = await onlyAccount(tester);
      expect(account.type, AccountType.creditCard);
      expect(account.startingBalance, 5000);

      await harness.dispose(tester);
    });
  });

  group('FIRST LAUNCH (fresh database, no bootstrap)', () {
    testWidgets(
      'an account added from the Accounts screen appears without a restart',
      (tester) async {
        final harness = DbHarness();
        final db = harness.db;

        // Truly fresh: no user row, nothing seeded.
        expect(
          await tester.runAsync(() => db.select(db.userProfile).get()),
          isEmpty,
        );

        await pumpUi(
          tester,
          const AccountsScreen(),
          container: harness.container,
        );
        await settle(tester);

        // Empty state: the card title and the (different) summary caption.
        expect(find.text('Add your first account'), findsOneWidget);
        expect(find.text('No accounts yet'), findsOneWidget);

        // First account.
        await tester.tap(find.byType(FloatingActionButton));
        await settle(tester, rounds: 10);
        await tester.enterText(_nameField, 'Cash');
        await tester.tap(_saveButton);
        await settle(tester);

        expect(find.byType(AccountFormSheet), findsNothing);
        expect(find.text('Cash'), findsOneWidget);
        expect(find.text('No accounts yet'), findsNothing);
        expect(find.text('Add your first account'), findsNothing);
        expect(find.text('1 account'), findsOneWidget);

        // Second account, same container, still no restart.
        await tester.tap(find.byType(FloatingActionButton));
        await settle(tester, rounds: 10);
        await tester.enterText(_nameField, 'Wallet');
        await tester.tap(find.widgetWithText(ChoiceChip, 'Wallet'));
        await tester.pump();
        await tester.tap(_saveButton);
        await settle(tester);

        expect(find.byType(AccountFormSheet), findsNothing);
        expect(find.text('Cash'), findsOneWidget);
        // 'Wallet' is both the row title and its type label.
        expect(find.text('Wallet'), findsNWidgets(2));
        expect(find.text('2 accounts'), findsOneWidget);

        // One local user row, created by the provider (not a bootstrap).
        final users = await tester.runAsync(
          () => db.select(db.userProfile).get(),
        );
        expect(users, hasLength(1));
        expect(harness.container.read(localUserIdProvider).hasValue, isTrue);

        await harness.dispose(tester);
      },
    );
  });
}
