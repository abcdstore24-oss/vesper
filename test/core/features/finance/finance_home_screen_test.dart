import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/utils/money.dart';
import 'package:vesper/features/finance/data/account_balance.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/presentation/accounts_screen.dart';
import 'package:vesper/features/finance/presentation/finance_home_screen.dart';
import 'package:vesper/features/finance/presentation/providers/accounts_providers.dart';
import 'package:vesper/shared/widgets/amount_text.dart';

import '../../../support/ui_test_helpers.dart';

const _totalCard = ValueKey('total_balance_card');
const _duesCard = ValueKey('card_dues_card');

void main() {
  setUpAll(disableFontFetching);

  testWidgets('no accounts: one Total balance card, "No accounts yet"', (
    tester,
  ) async {
    await pumpUi(
      tester,
      const FinanceHomeScreen(),
      overrides: [accountsOverride(const [])],
    );

    expect(find.byKey(_totalCard), findsOneWidget);
    expect(find.byKey(_duesCard), findsNothing);
    expect(find.text('Total balance'), findsOneWidget);
    expect(find.text('No accounts yet'), findsOneWidget);
    expect(find.text('\u20B90.00'), findsOneWidget);
    expect(find.text('Manage'), findsOneWidget);
    expect(find.text('Accounts'), findsOneWidget);
    expect(find.text('Balances by account'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with a card account: two cards, identical width and height', (
    tester,
  ) async {
    await pumpUi(
      tester,
      const FinanceHomeScreen(),
      overrides: [
        accountsOverride([
          makeAccount(id: 'a', name: 'Bank', balance: 100000),
          makeAccount(
            id: 'b',
            name: 'Visa',
            type: AccountType.creditCard,
            balance: -30000,
          ),
        ]),
      ],
    );

    expect(find.byKey(_totalCard), findsOneWidget);
    expect(find.byKey(_duesCard), findsOneWidget);
    expect(find.text('Total balance'), findsOneWidget);
    expect(find.text('Card dues'), findsOneWidget);
    expect(find.text('\u20B91,000.00'), findsOneWidget);
    expect(find.text('\u20B9300.00'), findsOneWidget);
    expect(find.text('1 account'), findsOneWidget);
    expect(find.text('1 card'), findsOneWidget);

    expect(
      tester.getSize(find.byKey(_totalCard)),
      tester.getSize(find.byKey(_duesCard)),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('only a credit card: total caption is "0 accounts"', (
    tester,
  ) async {
    await pumpUi(
      tester,
      const FinanceHomeScreen(),
      overrides: [
        accountsOverride([
          makeAccount(
            id: 'c',
            name: 'Visa',
            type: AccountType.creditCard,
            balance: -5000,
          ),
        ]),
      ],
    );

    expect(find.text('0 accounts'), findsOneWidget);
    expect(find.text('No accounts yet'), findsNothing);
    expect(find.text('1 card'), findsOneWidget);
    // Cards are not part of Total balance; they show up as dues.
    expect(find.text('\u20B90.00'), findsOneWidget);
    expect(find.text('\u20B950.00'), findsOneWidget);
  });

  testWidgets('"No accounts yet" only when there are no cards either', (
    tester,
  ) async {
    await pumpUi(
      tester,
      const FinanceHomeScreen(),
      overrides: [
        accountsOverride([
          makeAccount(id: 'o', name: 'Old', balance: 1000, isArchived: true),
          makeAccount(
            id: 'oc',
            name: 'Old card',
            type: AccountType.creditCard,
            balance: -1000,
            isArchived: true,
          ),
        ]),
      ],
    );

    // Archived accounts and cards don't count.
    expect(find.text('No accounts yet'), findsOneWidget);
    expect(find.text('0 accounts'), findsNothing);
    expect(find.byKey(_duesCard), findsNothing);
  });

  testWidgets('equal heights even when one card needs more lines', (
    tester,
  ) async {
    // Narrow + big text: the labels wrap differently, heights must match.
    await pumpUi(
      tester,
      const FinanceHomeScreen(),
      size: const Size(320, 640),
      textScale: 1.5,
      overrides: [
        accountsOverride([
          makeAccount(id: 'a', balance: 1),
          makeAccount(
            id: 'b',
            name: 'Visa',
            type: AccountType.creditCard,
            balance: -1,
          ),
        ]),
      ],
    );

    expect(
      tester.getSize(find.byKey(_totalCard)),
      tester.getSize(find.byKey(_duesCard)),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading shows a progress indicator, not a fake 0', (
    tester,
  ) async {
    await pumpUi(
      tester,
      const FinanceHomeScreen(),
      overrides: [
        accountsWithBalanceProvider.overrideWith((ref) {
          final controller = StreamController<List<AccountWithBalance>>();
          ref.onDispose(controller.close);
          return controller.stream;
        }),
      ],
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('\u20B90.00'), findsNothing);
    expect(find.text('Total balance'), findsNothing);
  });

  testWidgets('error shows a message and Retry reloads', (tester) async {
    var calls = 0;
    await pumpUi(
      tester,
      const FinanceHomeScreen(),
      overrides: [
        accountsWithBalanceProvider.overrideWith((ref) {
          calls++;
          return calls == 1
              ? Stream<List<AccountWithBalance>>.error(Exception('boom'))
              : Stream.value([makeAccount(balance: 5000)]);
        }),
      ],
    );

    expect(find.text("Couldn't load your accounts"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('\u20B90.00'), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(find.text("Couldn't load your accounts"), findsNothing);
    expect(find.text('\u20B950.00'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'worst case: maxPaise balances at 320dp, text scale 1.5 ($brightness)',
      (tester) async {
        await pumpUi(
          tester,
          const FinanceHomeScreen(),
          size: const Size(320, 640),
          textScale: 1.5,
          brightness: brightness,
          overrides: [
            accountsOverride([
              makeAccount(id: 'a', name: 'Bank', balance: Money.maxPaise),
              makeAccount(
                id: 'b',
                name: 'Visa',
                type: AccountType.creditCard,
                balance: -Money.maxPaise,
              ),
            ]),
          ],
        );

        expect(tester.takeException(), isNull);
        expect(find.byKey(_totalCard), findsOneWidget);
        expect(find.byKey(_duesCard), findsOneWidget);
        // Both amounts are exactly maxPaise, so both format normally.
        expect(find.text('\u20B910,00,00,00,00,000.00'), findsNWidgets(2));

        final amountTexts = find.descendant(
          of: find.byType(AmountText),
          matching: find.byType(Text),
        );
        expect(amountTexts, findsNWidgets(2));
        for (var i = 0; i < 2; i++) {
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

  testWidgets('two accounts of maxPaise: total shows "Amount too large"', (
    tester,
  ) async {
    await pumpUi(
      tester,
      const FinanceHomeScreen(),
      size: const Size(320, 640),
      textScale: 1.5,
      overrides: [
        accountsOverride([
          makeAccount(id: 'a', name: 'One', balance: Money.maxPaise),
          makeAccount(id: 'b', name: 'Two', balance: Money.maxPaise),
        ]),
      ],
    );

    expect(find.text('Amount too large'), findsOneWidget);
    expect(find.text('2 accounts'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Accounts row opens the Accounts screen', (tester) async {
    await pumpUi(
      tester,
      const FinanceHomeScreen(),
      overrides: [
        accountsOverride([makeAccount(name: 'Cash', balance: 100)]),
      ],
    );

    await tester.tap(find.text('Accounts'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountsScreen), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}