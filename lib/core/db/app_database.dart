import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Generates a random, UUID-v4-*shaped* identifier without depending on
/// the `uuid` package (not confirmed present in pubspec.yaml — see task
/// response, flag #2). Cryptographically random via [Random.secure],
/// formatted as `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx` to match the
/// UUID shape DATABASE.md calls for, without claiming RFC 4122
/// compliance.
String generateId() {
  final random = Random.secure();
  String hex(int byteCount) => List.generate(
    byteCount,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  final timeLow = hex(4);
  final timeMid = hex(2);
  final timeHiAndVersion = '4${hex(2).substring(1)}'; // version 4
  final variantByte = (random.nextInt(64) + 128).toRadixString(16); // variant 10xx
  final clockSeq = '$variantByte${hex(1)}';
  final node = hex(6);

  return '$timeLow-$timeMid-$timeHiAndVersion-$clockSeq-$node';
}

/// DATABASE.md `user_profile`:
/// (id, user_id, display_name, birthdate, theme_preference,
/// app_lock_mode) + the general id/user_id/created_at/updated_at
/// columns every table gets per DATABASE.md's Non-negotiable Rule 3.
///
/// `theme_preference`/`app_lock_mode` are stored as plain text (the
/// relevant enum's `.name`) rather than a SQL-level enum/CHECK
/// constraint — validated in application code. See task response
/// flag #3.
@DataClassName('UserProfileRow')
class UserProfile extends Table {
  TextColumn get id => text()();

  // Nullable locally when no account exists yet, per DATABASE.md rule 3.
  TextColumn get userId => text().nullable()();

  // Nullable: unset until the (not-yet-built) onboarding flow sets it.
  // See task response flag #1.
  TextColumn get displayName => text().nullable()();
  DateTimeColumn get birthdate => dateTime().nullable()();

  // Free-form enum name (e.g. "light" / "dark" / "system"), matching
  // the ThemeMode persistence convention already used in
  // theme_mode_provider.dart.
  TextColumn get themePreference => text().nullable()();

  // DATABASE.md gives explicit values: [os/pin/off].
  TextColumn get appLockMode => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

/// DATABASE.md `remote_status_cache`:
/// (id, last_checked_at, maintenance_mode, maintenance_message,
/// kill_switch, last_known_good).
///
/// DATABASE.md explicitly calls this table out as "intentionally not
/// user-scoped in the same way" as every other table — no `user_id`
/// column here. Following DATABASE.md's literal field list for this
/// table (no `created_at`/`updated_at` either, since `last_checked_at`
/// covers that role and the table's own field list is fully spelled
/// out). See task response flag #1 — please confirm this reading.
@DataClassName('RemoteStatusCacheRow')
class RemoteStatusCache extends Table {
  TextColumn get id => text()();

  // Null = never successfully checked, per API.md's offline rule.
  DateTimeColumn get lastCheckedAt => dateTime().nullable()();

  BoolColumn get maintenanceMode =>
      boolean().withDefault(const Constant(false))();
  TextColumn get maintenanceMessage => text().nullable()();
  BoolColumn get killSwitch => boolean().withDefault(const Constant(false))();

  // DATABASE.md doesn't specify this column's type. Interpreted as: has
  // a successful, connected check ever confirmed a good status?
  // Defaults true so a device that has never checked in is never
  // treated as blocked — matching API.md's offline-safe rule ("absence
  // of a successful check = fall back to cached status = normal
  // operation"). See task response flag #4.
  BoolColumn get lastKnownGood =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [UserProfile, RemoteStatusCache])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'vesper.sqlite'));
    final key = await _DbKeyStore.getOrCreateKey();

    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        // sqlcipher_flutter_libs replaces the plain sqlite3 native
        // binary with a SQLCipher-capable one, so this PRAGMA is what
        // actually turns encryption on. Must run before any other
        // statement on this connection.
        rawDb.execute("PRAGMA key = '$key';");
      },
    );
  });
}

/// Generates and persists the SQLCipher passphrase.
///
/// Treated as sensitive per CLAUDE.md Section 8 rule 5: stored only in
/// flutter_secure_storage (Keystore/Keychain-backed), never in the
/// database file itself, never in plain SharedPreferences, never
/// logged.
class _DbKeyStore {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'vesper.db_encryption_key';

  static Future<String> getOrCreateKey() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null) return existing;

    final generated = _generateKey();
    await _storage.write(key: _keyName, value: generated);
    return generated;
  }

  /// 256-bit random key, hex-encoded.
  static String _generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
