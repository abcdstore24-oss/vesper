import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/features/finance/presentation/widgets/transaction_tile.dart';

import '../../../support/ui_test_helpers.dart';

void main() {
  setUpAll(disableFontFetching);

  testWidgets('showDate: the default shows the date, false hides it', (
    tester,
  ) async {
    final item = makeTransactionItem(id: 't1', note: 'Lunch');

    await pumpUi(tester, Scaffold(body: TransactionTile(item: item)));
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);

    await pumpUi(
      tester,
      Scaffold(body: TransactionTile(item: item, showDate: false)),
    );
    expect(find.text('Today'), findsNothing);
    // The rest of the row is unchanged.
    expect(find.text('Lunch'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
