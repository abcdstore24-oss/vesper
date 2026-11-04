import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/core/db/db_provider.dart';
import 'package:vesper/core/theme/app_theme.dart';
import 'package:vesper/features/finance/data/account_balance.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/data/transaction_queries.dart';
import 'package:vesper/features/finance/data/transactions_table.dart';
import 'package:vesper/features/finance/presentation/providers/accounts_providers.dart';
import 'package:vesper/features/finance/presentation/providers/transactions_providers.dart';

import 'test_db.dart';

/// Call once per test file (setUpAll). Stops google_fonts from trying the
/// network in tests; it then fails quietly and text falls back to the test
/// font (Ahem: every glyph is a 1em square, so widths are very pessimistic).
void disableFontFetching() {
  GoogleFonts.config.allowRuntimeFetching = false;
}

/// True ONLY for the exception google_fonts throws when a font file is not in
/// the app's assets and runtime fetching is off (as in the test sandbox):
/// an [Exception] (not an Error) whose message contains BOTH
/// "allowRuntimeFetching is false but font" and "was not found in the
/// application assets". Anything else is false.
bool isMissingFontError(Object error) {
  if (error is! Exception) return false;
  final text = error.toString();
  return text.contains('allowRuntimeFetching is false but font') &&
      text.contains('was not found in the application assets');
}

/// Runs [body] in a guarded zone that IGNORES [isMissingFontError] errors
/// and re-reports every other error, unchanged, to the zone this was called
/// from. Futures belong to the zone they were created in, so anything
/// google_fonts starts while [body] runs reports here, even after [body]
/// returns. Returns null if [body] throws synchronously (re-reported).
T? runIgnoringMissingFonts<T>(T Function() body) {
  final outer = Zone.current;
  return runZonedGuarded<T>(body, (error, stackTrace) {
    if (isMissingFontError(error)) return;
    outer.handleUncaughtError(error, stackTrace);
  });
}

/// AppTheme.light / AppTheme.dark, built where google_fonts' missing-font
/// errors are ignored. Use this instead of calling AppTheme directly in tests.
ThemeData buildTestTheme(Brightness brightness) {
  final theme = runIgnoringMissingFonts(
    () => brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
  );
  if (theme == null) {
    throw StateError('Building the test theme failed (error reported above).');
  }
  return theme;
}

AccountRow makeAccountRow({
  String id = 'a1',
  String userId = 'user-1',
  String name = 'Cash',
  AccountType type = AccountType.bank,
  int startingBalance = 0,
  bool isArchived = false,
}) {
  return AccountRow(
    id: id,
    userId: userId,
    name: name,
    type: type,
    currency: 'INR',
    startingBalance: startingBalance,
    isArchived: isArchived,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

AccountWithBalance makeAccount({
  String id = 'a1',
  String name = 'Cash',
  AccountType type = AccountType.bank,
  int balance = 0,
  bool isArchived = false,
}) {
  final row = makeAccountRow(
    id: id,
    name: name,
    type: type,
    startingBalance: balance,
    isArchived: isArchived,
  );
  return AccountWithBalance(
    account: row,
    balancePaise: computeBalancePaise(startingBalancePaise: balance),
  );
}

/// Overrides accountsWithBalanceProvider with a fixed list.
Override accountsOverride(List<AccountWithBalance> accounts) {
  return accountsWithBalanceProvider.overrideWith(
    (ref) => Stream.value(accounts),
  );
}

/// Overrides recentTransactionsProvider with a fixed list.
Override recentTransactionsOverride(List<TransactionListItem> items) {
  return recentTransactionsProvider.overrideWith((ref) => Stream.value(items));
}

/// A transaction row as the Finance home shows it, without a database.
///
/// For a transfer the category is ignored and [toAccountName] defaults to
/// 'Visa'. [occurredAt] defaults to now.
TransactionListItem makeTransactionItem({
  String id = 't1',
  TransactionType type = TransactionType.expense,
  int amount = 100,
  String? note,
  String? categoryName = 'Food & Dining',
  String? categoryIcon = 'fork_knife',
  String accountName = 'Bank',
  String? toAccountName,
  DateTime? occurredAt,
}) {
  final at = occurredAt ?? DateTime.now();
  final isTransfer = type == TransactionType.transfer;
  return TransactionListItem(
    transaction: TransactionRow(
      id: id,
      userId: 'user-1',
      accountId: 'a1',
      toAccountId: isTransfer ? 'a2' : null,
      categoryId: isTransfer ? null : 'c1',
      amount: amount,
      type: type,
      note: note,
      occurredAt: at,
      sourceType: null,
      sourceId: null,
      createdAt: at,
      updatedAt: at,
    ),
    categoryName: isTransfer ? null : categoryName,
    categoryIcon: isTransfer ? null : categoryIcon,
    accountName: accountName,
    toAccountName: isTransfer ? (toAccountName ?? 'Visa') : null,
  );
}

/// Pumps [home] in a MaterialApp with the real Vesper themes.
///
/// [size] is in logical pixels (device pixel ratio 1). [textScale] is
/// applied through MediaQuery.
Future<void> pumpUi(
  WidgetTester tester,
  Widget home, {
  List<Override> overrides = const [],
  Size size = const Size(800, 600),
  double textScale = 1.0,
  Brightness brightness = Brightness.light,
  ProviderContainer? container,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final app = MaterialApp(
    theme: buildTestTheme(Brightness.light),
    darkTheme: buildTestTheme(Brightness.dark),
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: home,
  );

  await tester.pumpWidget(
    container == null
        ? ProviderScope(overrides: overrides, child: app)
        : UncontrolledProviderScope(container: container, child: app),
  );
  // Let the override stream emit, then rebuild.
  await tester.pump();
  await tester.pump();
}

/// Lets real async work (in-memory Drift) and fake-async timers both move:
/// alternates a short real delay with a pump.
Future<void> settle(WidgetTester tester, {int rounds = 25}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Waits, one real-time-plus-pump round at a time, until [condition] holds
/// (at most [maxRounds]). Not a blind delay: it stops as soon as the
/// condition is true. Use it after the action that first shows data from a
/// lazily loaded provider (a Drift query behind localUserIdProvider).
Future<void> settleUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maxRounds = 40,
}) async {
  for (var i = 0; i < maxRounds && !condition(); i++) {
    await settle(tester, rounds: 1);
  }
}

/// Scrolls [target] into view, taps it and pumps once. (Data that loads
/// lazily needs settle/settleUntil afterwards; a bare pump is not enough.)
Future<void> tapChip(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pump();
}

/// An in-memory database + container for DB-backed widget tests. Nothing is
/// seeded and no bootstrap runs (the fresh-install situation).
class DbHarness {
  DbHarness()
    : container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith(InMemoryAppDatabaseNotifier.new),
        ],
      );

  final ProviderContainer container;

  AppDatabase get db => container.read(appDatabaseProvider);

  /// Tears everything down cleanly: removes the widget tree (cancelling
  /// stream listeners), then disposes the container and closes the database.
  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      container.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    // Drift's StreamQueryStore.markAsClosed schedules a zero-duration timer
    // (Timer.run) when a query stream loses its last listener, and
    // db.close() waits for it. That timer is created in the fake-async zone,
    // whose clock only moves when the test pumps, so the real-time delay
    // above never runs it. Pump 1 ms so it fires before the end-of-test
    // "no pending timers" check.
    await tester.pump(const Duration(milliseconds: 1));
  }
}