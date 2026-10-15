import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show kDebugMode;

import '../../features/finance/data/category_seeder.dart';
import 'app_database.dart';

/// A baseline-data seeder. Must be idempotent (safe on every start) and
/// must not open its own transaction; [ensureBaselineData] wraps all
/// seeders in one.
typedef BaselineSeeder = Future<void> Function(AppDatabase db, String userId);

/// Every registered seeder, run in order. Later modules add their own
/// seeder here.
const List<BaselineSeeder> baselineSeeders = <BaselineSeeder>[
  seedDefaultCategories,
];

/// Guarantees the baseline data exists before any screen is built:
///
/// 1. the device-local user row ([ensureLocalUser]);
/// 2. every registered seeder, all inside ONE transaction, so a failure
///    leaves no half-seeded state.
///
/// Call once from main(), awaited, after the database is opened and
/// before runApp. After the first start it costs two small reads and no
/// writes.
///
/// On failure: rethrows when [failFast] (default: debug builds). In
/// release it swallows the error so the app still opens, and the next
/// start retries. Nothing is logged: no user data leaves this function.
Future<void> ensureBaselineData(
  AppDatabase db, {
  List<BaselineSeeder> seeders = baselineSeeders,
  bool failFast = kDebugMode,
}) async {
  try {
    final userId = await ensureLocalUser(db);
    await db.transaction(() async {
      for (final seeder in seeders) {
        await seeder(db, userId);
      }
    });
  } catch (_) {
    if (failFast) rethrow;
  }
}

/// Returns the device-local user id, creating the user_profile row first
/// if the table is empty.
///
/// Per DATABASE.md rule 3 the local user id is a device-generated UUID
/// held in `user_profile.user_id` until/unless an account exists.
/// Before this function nothing in the app created that row. Also fills
/// in `user_id` if a row exists without one. An existing id is never
/// changed.
Future<String> ensureLocalUser(AppDatabase db) {
  return db.transaction(() async {
    final existing = await (db.select(db.userProfile)..limit(1))
        .getSingleOrNull();

    if (existing == null) {
      final userId = generateId();
      await db
          .into(db.userProfile)
          .insert(
            UserProfileCompanion.insert(
              id: generateId(),
              userId: Value(userId),
            ),
          );
      return userId;
    }

    final current = existing.userId;
    if (current != null && current.isNotEmpty) return current;

    final userId = generateId();
    await (db.update(db.userProfile)..where((t) => t.id.equals(existing.id)))
        .write(
          UserProfileCompanion(
            userId: Value(userId),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return userId;
  });
}