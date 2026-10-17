import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/core/db/db_provider.dart';

/// [AppDatabaseNotifier] that builds a fresh in-memory database instead of
/// the encrypted on-disk one. Nothing is seeded and no bootstrap runs.
class InMemoryAppDatabaseNotifier extends AppDatabaseNotifier {
  @override
  AppDatabase build() {
    final db = AppDatabase(NativeDatabase.memory());
    ref.onDispose(db.close);
    return db;
  }
}

/// A container whose database is a fresh, empty, in-memory one. Disposed
/// automatically at the end of the test.
ProviderContainer makeInMemoryContainer() {
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWith(InMemoryAppDatabaseNotifier.new),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Lets the event loop run until [condition] is true, or fails after
/// [timeout]. Used to wait for Drift stream emissions.
Future<void> pumpUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for condition');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
