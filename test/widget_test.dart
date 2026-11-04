import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vesper/features/finance/data/account_balance.dart';
import 'package:vesper/features/finance/data/transaction_queries.dart';
import 'package:vesper/features/finance/presentation/providers/accounts_providers.dart';
import 'package:vesper/features/finance/presentation/providers/transactions_providers.dart';
import 'package:vesper/main.dart';

void main() {
  testWidgets('App launches and shows the nav shell', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // AppShell builds every tab at startup. The Finance tab's
          // BalanceSummary shows a progress spinner until accounts load, and
          // the real database cannot open in a test, so the spinner would
          // animate forever and pumpAndSettle would time out.
          accountsWithBalanceProvider.overrideWith(
            (ref) => Stream.value(const <AccountWithBalance>[]),
          ),
          // The Finance home also shows "Recent transactions", which would
          // sit on its own spinner for the same reason.
          recentTransactionsProvider.overrideWith(
            (ref) => Stream.value(const <TransactionListItem>[]),
          ),
        ],
        child: const VesperApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}