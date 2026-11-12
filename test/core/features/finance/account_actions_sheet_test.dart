import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/theme/app_colors.dart';
import 'package:vesper/core/utils/money.dart';
import 'package:vesper/features/finance/data/account_balance.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/presentation/accounts_screen.dart';
import 'package:vesper/features/finance/presentation/providers/accounts_providers.dart';
import 'package:vesper/features/finance/presentation/widgets/account_form_sheet.dart';

import '../../../support/ui_test_helpers.dart';

final _archive = find.byKey(const ValueKey('acct_archive_button'));
final _delete = find.byKey(const ValueKey('acct_delete_button'));
final _restore = find.byKey(const ValueKey('acct_restore_button'));
final _archiveCaption = find.byKey(const ValueKey('acct_archive_caption'));
final _deleteCaption = find.byKey(const ValueKey('acct_delete_caption'));
final _archivedCaption = find.byKey(const ValueKey('acct_archived_caption'));
final _nameField = find.byKey(const ValueKey('account_name_field'));
final _amountField = find.byKey(const ValueKey('account_amount_field'));
final _dialog = find.byType(AlertDialog);

const _zeroCaption =
    'Bring the balance to zero first (for example, transfer the money to '
    'another account) to archive it.';
const _txCaption =
    "This account has transactions, so it can't be deleted. Archive it "
    'instead.';

VoidCallback? _onPressed(WidgetTester tester, Finder button) =>
    tester.widget<TextButton>(button).onPressed;

/// An account row with its own computed balance (which may differ from the
/// starting balance once it has transactions).
AccountWithBalance _item({
  String id = 'a',
  String name = 'Savings',
  AccountType type = AccountType.bank,
  int starting = 0,
  int? balance,
  bool archived = false,
}) => AccountWithBalance(
  account: makeAccountRow(
    id: id,
    name: name,
    type: type,
    startingBalance: starting,
    isArchived: archived,
  ),
  balancePaise: balance ?? starting,
);

void main() {
  setUpAll(disableFontFetching);

  /// The edit sheet without a database. [hasTransactions] null = the answer
  /// never arrives (still loading).
  Future<void> pumpSheet(
    WidgetTester tester,
    AccountWithBalance? item, {
    bool? hasTransactions = false,
    List<AccountWithBalance>? accounts,
    Size size = const Size(800, 1600),
    double textScale = 1.0,
    Brightness brightness = Brightness.light,
  }) => pumpUi(
    tester,
    Scaffold(
      body: AccountFormSheet(key: UniqueKey(), account: item?.account),
    ),
    size: size,
    textScale: textScale,
    brightness: brightness,
    overrides: [
      accountsOverride(accounts ?? [?item]),
      accountHasTransactionsProvider.overrideWith(
        (ref, id) => hasTransactions == null
            ? Completer<bool>().future
            : Future.value(hasTransactions),
      ),
    ],
  );

  group('the sheet in each state', () {
    testWidgets('eligible: Archive and Delete are enabled, no captions', (
      tester,
    ) async {
      await pumpSheet(tester, _item());
      await tester.pump();

      expect(find.text('Edit account'), findsOneWidget);
      expect(_onPressed(tester, _archive), isNotNull);
      expect(_onPressed(tester, _delete), isNotNull);
      expect(_archiveCaption, findsNothing);
      expect(_deleteCaption, findsNothing);
      expect(_restore, findsNothing);
      expect(_archivedCaption, findsNothing);
      // Save stays the only ElevatedButton, and the actions sit below it.
      final save = find.widgetWithText(ElevatedButton, 'Save changes');
      expect(save, findsOneWidget);
      expect(
        tester.getTopLeft(_archive).dy,
        greaterThan(tester.getBottomLeft(save).dy),
      );
    });

    testWidgets('a non-zero balance: Archive disabled with the caption', (
      tester,
    ) async {
      await pumpSheet(tester, _item(starting: 0, balance: 500));
      await tester.pump();

      expect(_onPressed(tester, _archive), isNull);
      expect(find.text(_zeroCaption), findsOneWidget);
      // Delete is still offered (no transactions).
      expect(_onPressed(tester, _delete), isNotNull);
    });

    testWidgets('a negative balance is ineligible', (tester) async {
      await pumpSheet(tester, _item(starting: -100));
      await tester.pump();
      expect(_onPressed(tester, _archive), isNull);
      expect(find.text(_zeroCaption), findsOneWidget);
    });

    testWidgets('a card with dues is ineligible', (tester) async {
      await pumpSheet(
        tester,
        _item(id: 'c', type: AccountType.creditCard, starting: -5000),
      );
      await tester.pump();
      expect(_onPressed(tester, _archive), isNull);
      expect(find.text(_zeroCaption), findsOneWidget);
    });

    testWidgets('has transactions: no Delete, a caption instead', (
      tester,
    ) async {
      await pumpSheet(tester, _item(), hasTransactions: true);
      await tester.pump();

      expect(_delete, findsNothing);
      expect(find.text(_txCaption), findsOneWidget);
      // Archive still follows the balance (zero here).
      expect(_onPressed(tester, _archive), isNotNull);
    });

    testWidgets('has transactions and a non-zero balance: both captions', (
      tester,
    ) async {
      await pumpSheet(tester, _item(balance: 500), hasTransactions: true);
      await tester.pump();

      expect(_delete, findsNothing);
      expect(_onPressed(tester, _archive), isNull);
      expect(find.text(_zeroCaption), findsOneWidget);
      expect(find.text(_txCaption), findsOneWidget);
    });

    testWidgets('archived: Restore, type and amount disabled, name editable', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        _item(name: 'Old wallet', type: AccountType.wallet, archived: true),
      );
      await tester.pump();

      expect(_onPressed(tester, _restore), isNotNull);
      expect(_archive, findsNothing);
      expect(_delete, findsNothing);
      expect(_archivedCaption, findsOneWidget);
      expect(
        find.text('This account is archived, so only its name can be changed.'),
        findsOneWidget,
      );

      for (final label in ['Bank', 'Cash', 'Wallet', 'Credit card', 'Other']) {
        expect(
          tester
              .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
              .onSelected,
          isNull,
          reason: label,
        );
      }
      expect(tester.widget<TextField>(_amountField).enabled, isFalse);
      expect(tester.widget<TextField>(_nameField).enabled, isTrue);
      expect(
        find.widgetWithText(ElevatedButton, 'Save changes'),
        findsOneWidget,
      );
    });

    testWidgets('still loading: the actions are disabled, no captions', (
      tester,
    ) async {
      await pumpSheet(tester, _item(), hasTransactions: null);
      await tester.pump();

      expect(_onPressed(tester, _archive), isNull);
      expect(_onPressed(tester, _delete), isNull);
      expect(_archiveCaption, findsNothing);
      expect(_deleteCaption, findsNothing);
    });

    testWidgets('no balance yet (account missing from the stream): disabled', (
      tester,
    ) async {
      await pumpSheet(tester, _item(), accounts: const []);
      await tester.pump();

      expect(_onPressed(tester, _archive), isNull);
      expect(_onPressed(tester, _delete), isNull);
    });

    testWidgets('archived and still loading: Restore is disabled', (
      tester,
    ) async {
      await pumpSheet(tester, _item(archived: true), hasTransactions: null);
      await tester.pump();
      expect(_onPressed(tester, _restore), isNull);
    });

    testWidgets('add mode has none of the actions', (tester) async {
      await pumpSheet(tester, null);
      await tester.pump();

      expect(find.text('Add account'), findsWidgets);
      expect(_archive, findsNothing);
      expect(_delete, findsNothing);
      expect(_restore, findsNothing);
      expect(_archivedCaption, findsNothing);
    });

    testWidgets('Delete and Archive are neutral / danger TextButtons', (
      tester,
    ) async {
      await pumpSheet(tester, _item());
      await tester.pump();

      Color? colorOf(Finder f) => tester
          .widget<TextButton>(f)
          .style
          ?.foregroundColor
          ?.resolve(<WidgetState>{});
      expect(colorOf(_delete), AppColors.light.danger);
      expect(colorOf(_archive), isNot(AppColors.light.danger));
    });
  });

  group('the delete dialog', () {
    testWidgets('opens with the name, the impact lines and the warning', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        _item(name: 'Savings', type: AccountType.bank, starting: 0, balance: 0),
      );
      await tester.pump();

      await tapChip(tester, _delete);
      await tester.pumpAndSettle();

      expect(find.text('Delete this account?'), findsOneWidget);
      final inDialog = find.descendant(
        of: _dialog,
        matching: find.text('Savings'),
      );
      expect(inDialog, findsOneWidget);
      expect(
        find.text('It has no transactions and a zero starting balance.'),
        findsOneWidget,
      );
      expect(find.text("This can't be undone."), findsOneWidget);
      expect(
        find.byKey(const ValueKey('delete_account_confirm_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('delete_account_cancel_button')),
        findsOneWidget,
      );
    });

    testWidgets('a non-zero starting balance, in the lines', (tester) async {
      await pumpSheet(tester, _item(starting: 125050, balance: 0));
      await tester.pump();
      await tapChip(tester, _delete);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Its starting balance of \u20B91,250.50 will no longer count in '
          'Total balance.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a card with a starting amount due, in the lines', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        _item(
          id: 'c',
          type: AccountType.creditCard,
          starting: -5000,
          balance: 0,
        ),
      );
      await tester.pump();
      await tapChip(tester, _delete);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Its starting amount due of \u20B950.00 will no longer count in '
          'Card dues.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Cancel closes the dialog and keeps the sheet usable', (
      tester,
    ) async {
      await pumpSheet(tester, _item());
      await tester.pump();
      await tapChip(tester, _delete);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('delete_account_cancel_button')),
      );
      await tester.pumpAndSettle();

      expect(_dialog, findsNothing);
      expect(find.byType(AccountFormSheet), findsOneWidget);
      expect(_onPressed(tester, _delete), isNotNull);
      expect(_onPressed(tester, _archive), isNotNull);
    });
  });

  group('worst case: 320dp, text scale 2.0, 40-character names', () {
    final states = <String, AccountWithBalance Function()>{
      'eligible': () =>
          _item(name: 'A' * 40, starting: Money.maxPaise, balance: 0),
      'non-zero balance': () => _item(name: 'B' * 40, balance: Money.maxPaise),
      'archived': () => _item(name: 'C' * 40, archived: true),
    };

    for (final brightness in Brightness.values) {
      for (final entry in states.entries) {
        testWidgets('sheet: ${entry.key} ($brightness)', (tester) async {
          await pumpSheet(
            tester,
            entry.value(),
            hasTransactions: entry.key == 'non-zero balance',
            size: const Size(320, 640),
            textScale: 2.0,
            brightness: brightness,
          );
          await tester.pump();

          expect(tester.takeException(), isNull);
          expect(find.text('Edit account'), findsOneWidget);
        });
      }

      testWidgets('delete dialog ($brightness)', (tester) async {
        await pumpSheet(
          tester,
          _item(
            name: 'D' * 40,
            type: AccountType.creditCard,
            starting: -Money.maxPaise,
            balance: 0,
          ),
          size: const Size(320, 640),
          textScale: 2.0,
          brightness: brightness,
        );
        await tester.pump();
        await tapChip(tester, _delete);
        await tester.pumpAndSettle();

        expect(_dialog, findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('delete_account_cancel_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('delete_account_confirm_button')),
          findsOneWidget,
        );
      });
    }
  });

  group('AccountsScreen: the Archived section', () {
    Future<void> pumpScreen(
      WidgetTester tester,
      List<AccountWithBalance> accounts, {
      Size size = const Size(800, 1000),
      double textScale = 1.0,
      Brightness brightness = Brightness.light,
    }) => pumpUi(
      tester,
      const AccountsScreen(),
      size: size,
      textScale: textScale,
      brightness: brightness,
      overrides: [
        accountsOverride(accounts),
        accountHasTransactionsProvider.overrideWith((ref, id) async => false),
      ],
    );

    final header = find.byKey(const ValueKey('accounts-archived-header'));
    Finder row(String id) => find.byKey(ValueKey('account-row-$id'));
    double opacityOf(WidgetTester tester, String id) => tester
        .widget<Opacity>(
          find.descendant(of: row(id), matching: find.byType(Opacity)),
        )
        .opacity;

    testWidgets('no archived account: no section', (tester) async {
      await pumpScreen(tester, [_item(id: 'a', name: 'Only')]);
      expect(header, findsNothing);
      expect(find.text('Archived'), findsNothing);
    });

    testWidgets('archived accounts sit below the active ones, muted', (
      tester,
    ) async {
      await pumpScreen(tester, [
        _item(id: 'a', name: 'Active one', starting: 100, balance: 100),
        _item(id: 'b', name: 'Old one', archived: true),
        _item(id: 'c', name: 'Old two', archived: true),
      ]);

      expect(header, findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Active one')).dy,
        lessThan(tester.getTopLeft(header).dy),
      );
      expect(
        tester.getTopLeft(header).dy,
        lessThan(tester.getTopLeft(find.text('Old one')).dy),
      );
      expect(find.text('Old two'), findsOneWidget);

      expect(
        find.descendant(of: row('a'), matching: find.byType(Opacity)),
        findsNothing,
      );
      expect(opacityOf(tester, 'b'), lessThan(1));
      expect(opacityOf(tester, 'c'), lessThan(1));
    });

    testWidgets('only archived accounts: the empty state and the section', (
      tester,
    ) async {
      await pumpScreen(tester, [
        _item(id: 'b', name: 'Old one', archived: true),
      ]);

      expect(find.text('Add your first account'), findsOneWidget);
      expect(header, findsOneWidget);
      expect(find.text('Old one'), findsOneWidget);
    });

    testWidgets('tapping an archived row opens the edit sheet with Restore', (
      tester,
    ) async {
      await pumpScreen(tester, [
        _item(id: 'a', name: 'Active one', starting: 100, balance: 100),
        _item(id: 'b', name: 'Old one', archived: true),
      ]);

      await tester.tap(row('b'));
      await tester.pumpAndSettle();

      expect(find.text('Edit account'), findsOneWidget);
      expect(_restore, findsOneWidget);
      expect(tester.widget<TextField>(_nameField).controller!.text, 'Old one');
    });

    testWidgets('the totals ignore archived accounts', (tester) async {
      await pumpScreen(tester, [
        _item(id: 'a', name: 'Active one', starting: 100000, balance: 100000),
        _item(id: 'b', name: 'Old one', starting: 0, archived: true),
      ]);
      // Total Balance stays the active account's alone.
      expect(find.text('\u20B91,000.00'), findsWidgets);
    });

    for (final brightness in Brightness.values) {
      testWidgets('worst case, 320dp, text scale 2.0 ($brightness)', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          [
            _item(
              id: 'a',
              name: 'A' * 40,
              starting: Money.maxPaise,
              balance: Money.maxPaise,
            ),
            _item(
              id: 'b',
              name: 'B' * 40,
              archived: true,
              type: AccountType.creditCard,
            ),
          ],
          size: const Size(320, 640),
          textScale: 2.0,
          brightness: brightness,
        );
        expect(tester.takeException(), isNull);
        // The header is far below the first (very tall) row, so the lazy list
        // has not built it yet: scroll to it first.
        await tester.scrollUntilVisible(
          header,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(header, findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
