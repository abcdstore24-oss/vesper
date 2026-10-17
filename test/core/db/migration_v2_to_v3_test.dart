import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/core/db/db_bootstrap.dart';
import 'package:vesper/features/finance/data/accounts_dao.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';

/// The exact SQL Drift generates for the four schema entities that make up
/// version 2 (user_profile, remote_status_cache, categories and its index),
/// read from sqlite_master of a database freshly created by the real
/// generated code. `accounts` is deliberately NOT included: it is the v3
/// addition.
///
/// If a LATER migration alters one of these four tables, this stops being a
/// true v2 snapshot: at that point replace this helper with literal DDL
/// copied from the last release that shipped v2.
Future<List<String>> generatedV2Ddl() async {
  final scratch = AppDatabase(NativeDatabase.memory());
  try {
    final rows = await scratch
        .customSelect(
          "SELECT sql FROM sqlite_master WHERE sql IS NOT NULL AND name IN "
          "('user_profile', 'remote_status_cache', 'categories', "
          "'categories_user_kind_idx') "
          "ORDER BY CASE type WHEN 'table' THEN 0 ELSE 1 END, name",
        )
        .get();
    return rows.map((r) => r.read<String>('sql')).toList();
  } finally {
    await scratch.close();
  }
}

void main() {
  late AppDatabase db;

  tearDown(() async {
    await db.close();
  });

  test('v2 -> v3 adds accounts + its index and keeps every old row', () async {
    final ddl = await generatedV2Ddl();
    expect(ddl, hasLength(4));
    expect(ddl.any((s) => s.contains('accounts')), isFalse);

    db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          for (final statement in ddl) {
            raw.execute(statement);
          }
          raw.execute(
            "INSERT INTO user_profile (id, user_id, display_name, "
            "created_at, updated_at) VALUES "
            "('p1', 'old-user', 'Asha', 1700000000, 1700000000)",
          );
          raw.execute(
            "INSERT INTO remote_status_cache (id, kill_switch) "
            "VALUES ('r1', 0)",
          );
          raw.execute(
            "INSERT INTO categories (id, user_id, name, icon, color, kind, "
            "seed_key, created_at, updated_at) VALUES "
            "('c1', 'old-user', 'Eating out', 'fork_knife', 4291132292, "
            "'expense', 'exp_food', 1700000000, 1700000000), "
            "('c2', 'old-user', 'Pet care', 'paw_print', 4279312947, "
            "'expense', NULL, 1700000000, 1700000000)",
          );
          raw.execute('PRAGMA user_version = 2');
        },
      ),
    );

    // First query opens the database and runs the v2 -> v3 upgrade.
    expect(await db.select(db.accounts).get(), isEmpty);

    // Old rows survived untouched.
    final profile = await db.select(db.userProfile).getSingle();
    expect(profile.id, 'p1');
    expect(profile.userId, 'old-user');
    expect(profile.displayName, 'Asha');
    expect(await db.select(db.remoteStatusCache).get(), hasLength(1));
    final categories = await db.select(db.categories).get();
    expect(categories.map((c) => c.id).toSet(), {'c1', 'c2'});
    expect(
      categories.firstWhere((c) => c.id == 'c1').name,
      'Eating out',
    );

    // New table and index exist; the old index is still there.
    final schema = await db
        .customSelect('SELECT name FROM sqlite_master')
        .get();
    final names = schema.map((r) => r.read<String>('name')).toSet();
    expect(names, containsAll(['accounts', 'accounts_user_idx']));
    expect(names, contains('categories_user_kind_idx'));

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 3);

    // The new table is usable.
    final id = await AccountsDao(db).insert(
      userId: 'old-user',
      name: 'Cash',
      type: AccountType.cash,
      startingBalancePaise: 1000,
    );
    expect((await AccountsDao(db).getById(id))!.name, 'Cash');

    // Bootstrap after the upgrade adds only the missing seeds: the renamed
    // built-in c1 is found (not recreated) and the user-made c2 is kept.
    await ensureBaselineData(db);
    expect(await db.select(db.categories).get(), hasLength(2 + 26 - 1));
    expect(await db.select(db.userProfile).get(), hasLength(1));
  });
}