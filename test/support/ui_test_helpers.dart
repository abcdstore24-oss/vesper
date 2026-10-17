import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/core/db/db_provider.dart';
import 'package:vesper/core/theme/app_theme.dart';
import 'package:vesper/features/finance/data/account_balance.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/presentation/providers/accounts_providers.dart';

import 'test_db.dart';

/// Call once per test file (setUpAll). Stops google_fonts from trying the
/// network in tests; it then fails quietly and text falls back to the test
/// font (Ahem: every glyph is a 1em square, so widths are very pessimistic).
void disableFontFetching() {
  GoogleFonts.config.allowRuntimeFetching = false;
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
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
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