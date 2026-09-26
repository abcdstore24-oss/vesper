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

/// DATABASE.md `accounts`: (id, user_id, name, type, currency,
/// starting_balance) + created_at/updated_at per rule 3.
///
/// `user_id` here is NOT nullable, unlike `user_profile.userId` above.
/// DATABASE.md rule 3 describes `user_id` as nullable "when no account
/// exists yet" — but `user_profile`'s column predates the local-UUID
/// mechanism actually existing. Now that it does (local_user_id.dart,
/// added this task), every row this task creates is always stamped
/// with a real local id at insert time, so there's no state where it
/// would legitimately be null. `user_profile.userId` itself is
/// untouched (out of scope this task) and stays nullable.
@DataClassName('AccountRow')
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();

  /// AccountType.name — cash/bank/card/other. Fixed enum, not free
  /// text (task response flag, confirmed by owner).
  TextColumn get type => text()();

  TextColumn get currency => text()();

   /// Integer minor units (cents), NEVER a float — money is never
  /// stored as double/Real in this project, to avoid rounding drift
  /// once Task 2.2 sums many transactions into a live balance. Named
  /// explicitly `...Cents`, not `startingBalance`, so nothing
  /// downstream can accidentally treat this as a decimal-dollar value.
  /// This is now the standing convention for every money field project-
  /// wide (Transactions.amount, Budgets.limit_amount,
  /// Investments.cost_basis/current_value in later tasks) — see
  /// DECISIONS.md.
  IntColumn get startingBalanceCents =>
      integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

/// DATABASE.md `categories`: (id, user_id, name, icon, color,
/// kind[income/expense]) + created_at/updated_at.
///
/// `color` stores only the light-mode hex (canonical) from the fixed
/// 8-swatch palette in domain/category_style.dart — the dark-mode hex
/// is derived via `CategoryPalette.darkHexFor` at render time, never
/// stored per-row. This is CLAUDE.md Section 3's explicitly named
/// exception ("category colors in Finance charts are the one
/// deliberate exception") to the one-accent rule — see the DATABASE.md
/// addition flagged in the task response. Not enforced as a DB-level
/// constraint; the picker UI (category_form_sheet.dart) is what
/// restricts entry to the fixed swatch set, for both defaults and
/// custom categories.
@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();

  /// Key into domain/category_style.dart's CategoryIcons.options map.
  TextColumn get icon => text()();

  /// Light-mode hex, e.g. '#966E40'. See class doc above.
  TextColumn get color => text()();

  /// CategoryKind.name — income/expense.
  TextColumn get kind => text()();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

/// DATABASE.md `transactions`: (id, user_id, account_id, category_id,
/// amount, type[income/expense], note, occurred_at, is_recurring) +
/// created_at/updated_at.
@DataClassName('TransactionRow')
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();

  /// References accounts.id / categories.id by convention only — no
  /// Drift-level FK constraint (see DECISIONS.md: app-layer deletion
  /// blocking in accounts_dao.dart/categories_dao.dart is the
  /// integrity mechanism for now; revisit if PowerSync sync is wired
  /// up for Finance, since a server-side merge could write around the
  /// DAO layer).
  TextColumn get accountId => text()();
  TextColumn get categoryId => text()();

  /// Integer minor units (cents), ALWAYS stored positive. Sign is
  /// applied only at balance-computation time based on `type`, never
  /// stored negative. Same convention as
  /// accounts.startingBalanceCents.
  IntColumn get amountCents => integer()();

  /// CategoryKind.name ('income'/'expense') — auto-derived from the
  /// selected category's kind at creation/edit time (locked decision,
  /// Task 2.2). Stamped historically: editing the source category's
  /// kind later does NOT recalculate existing transactions.
  TextColumn get type => text()();

  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get occurredAt => dateTime()();

  /// Plain boolean toggle only — no recurrence rule, no
  /// auto-generation, no scheduling. Separate future TODO.md item.
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}
@DriftDatabase(tables: [UserProfile, RemoteStatusCache, Accounts, Categories, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // Cumulative, additive-only. Each branch creates only what
      // didn't exist yet at that version — never touches
      // user_profile or remote_status_cache, and (from Task 2.2 on)
      // never touches accounts or categories either.
      if (from < 2) {
        await m.createTable(accounts);
        await m.createTable(categories);
      }
      if (from < 3) {
        await m.createTable(transactions);
      }
    },
  );
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
