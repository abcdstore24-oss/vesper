import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:vesper/features/finance/data/transactions_table.dart';
import 'package:vesper/features/finance/presentation/widgets/transaction_tile.dart';

import '../../../support/transaction_item_helpers.dart';
import '../../../support/ui_test_helpers.dart';

Finder _tile(String id) => find.byKey(ValueKey('transaction-tile-$id'));
final _lock = find.byIcon(PhosphorIconsRegular.lock);

void main() {
  setUpAll(disableFontFetching);

  testWidgets('without onTap the row is not tappable', (tester) async {
    await pumpUi(
      tester,
      Scaffold(
        body: TransactionTile(
          item: makeTransactionItem(id: 't1', note: 'x'),
        ),
      ),
    );

    expect(_tile('t1'), findsOneWidget);
    expect(
      find.descendant(of: _tile('t1'), matching: find.byType(InkWell)),
      findsNothing,
    );
  });

  testWidgets('with onTap: ripple, the key, showDate and taps all work', (
    tester,
  ) async {
    var taps = 0;
    await pumpUi(
      tester,
      Scaffold(
        body: Card(
          clipBehavior: Clip.antiAlias,
          child: TransactionTile(
            item: makeTransactionItem(id: 't1', note: 'Lunch'),
            showDate: false,
            onTap: () => taps++,
          ),
        ),
      ),
    );

    expect(
      find.descendant(of: _tile('t1'), matching: find.byType(InkWell)),
      findsOneWidget,
    );
    expect(find.text('Today'), findsNothing); // showDate: false still holds
    expect(find.text('Lunch'), findsOneWidget);

    await tester.tap(find.text('Lunch'));
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the lock shows only for rows with a source', (tester) async {
    final plain = makeTransactionItem(id: 'p', note: 'Plain');
    final loan = withSource(
      makeTransactionItem(id: 'l', note: 'Loan row'),
      TransactionSource.loan,
    );
    final investment = withSource(
      makeTransactionItem(id: 'i', note: 'Trade row'),
      TransactionSource.investment,
    );

    await pumpUi(
      tester,
      Scaffold(
        body: Column(
          children: [
            TransactionTile(item: plain, onTap: () {}),
            TransactionTile(item: loan, onTap: () {}),
            TransactionTile(item: investment),
          ],
        ),
      ),
    );

    expect(find.descendant(of: _tile('p'), matching: _lock), findsNothing);
    expect(find.descendant(of: _tile('l'), matching: _lock), findsOneWidget);
    // The lock does not depend on onTap.
    expect(find.descendant(of: _tile('i'), matching: _lock), findsOneWidget);
    // Title text is unchanged next to the lock.
    expect(find.text('Loan row'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'locked row, worst case at 320dp, text scale 2.0 ($brightness)',
      (tester) async {
        final item = withSource(
          makeTransactionItem(
            id: 'l',
            amount: 100000000000000,
            note: 'n' * 100,
            accountName: 'A' * 40,
          ),
          TransactionSource.loan,
        );
        await pumpUi(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: TransactionTile(item: item, onTap: () {}),
              ),
            ),
          ),
          size: const Size(320, 640),
          textScale: 2.0,
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);
        expect(_lock, findsOneWidget);
      },
    );
  }
}
