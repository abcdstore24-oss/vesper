import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Exposes a single, app-lifetime [AppDatabase] instance.
///
/// Consistent with the NotifierProvider pattern already used in
/// theme_mode_provider.dart. The database itself doesn't need mutable
/// state — Drift's LazyDatabase already defers opening the SQLCipher
/// connection until first query — so this provider's only job is to
/// hold exactly one [AppDatabase] for the app's lifetime and close it
/// when the provider is disposed.
class AppDatabaseNotifier extends Notifier<AppDatabase> {
  @override
  AppDatabase build() {
    final db = AppDatabase();
    ref.onDispose(db.close);
    return db;
  }
}

final appDatabaseProvider = NotifierProvider<AppDatabaseNotifier, AppDatabase>(
  AppDatabaseNotifier.new,
);
