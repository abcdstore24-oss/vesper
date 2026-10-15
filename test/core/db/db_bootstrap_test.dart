import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/core/db/db_bootstrap.dart';
import 'package:vesper/features/finance/data/categories_dao.dart';
import 'package:vesper/features/finance/data/categories_table.dart';
import 'package:vesper/features/finance/data/category_seeder.dart';

const Set<String> systemSeedKeys = {
  'sys_loan_given',
  'sys_loan_repayment_received',
  'sys_loan_taken',
  'sys_loan_repayment_made',
  'sys_investment_buy',
  'sys_investment_sell',
};

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<List<CategoryRow>> allRows() => db.select(db.categories).get();

  Future<CategoryRow> bySeedKey(String key) => (db.select(
    db.categories,
  )..where((t) => t.seedKey.equals(key))).getSingle();

  group('seeding', () {
    test('empty DB gets exactly 26 rows (14 expense, 6 income, 6 system)', () async {
      await ensureBaselineData(db);

      final rows = await allRows();
      expect(rows, hasLength(26));
      expect(rows.where((r) => r.kind == CategoryKind.expense), hasLength(14));
      expect(rows.where((r) => r.kind == CategoryKind.income), hasLength(6));
      expect(rows.where((r) => r.kind == CategoryKind.system), hasLength(6));
      expect(rows.map((r) => r.seedKey).toSet(), hasLength(26));
      expect(rows.every((r) => !r.isArchived), isTrue);
    });

    test('seed values match the spec', () async {
      await ensureBaselineData(db);

      final food = await bySeedKey('exp_food');
      expect(food.name, 'Food & Dining');
      expect(food.icon, 'fork_knife');
      expect(food.color, 0xFFC97B84);
      expect(food.kind, CategoryKind.expense);

      final refunds = await bySeedKey('inc_refunds');
      expect(refunds.name, 'Refunds');
      expect(refunds.icon, 'arrow_u_up_left');
      expect(refunds.color, 0xFFB5A06A);
      expect(refunds.kind, CategoryKind.income);

      for (final c in defaultCategories) {
        expect(c.color >> 24, 0xFF, reason: '${c.seedKey} must be opaque');
      }
    });

    test('kind is stored by name, not index', () async {
      await ensureBaselineData(db);

      final rows = await db
          .customSelect('SELECT DISTINCT kind FROM categories')
          .get();
      final kinds = rows.map((r) => r.read<String>('kind')).toSet();
      expect(kinds, {'income', 'expense', 'system'});
    });

    test('the six system categories match the spec', () async {
      await ensureBaselineData(db);

      const expected = <String, List<String>>{
        'sys_loan_given': ['Loan given', 'arrow_up_right'],
        'sys_loan_repayment_received': ['Repayment received', 'arrow_down_left'],
        'sys_loan_taken': ['Loan taken', 'hand_coins'],
        'sys_loan_repayment_made': ['Loan repayment made', 'handshake'],
        'sys_investment_buy': ['Investment purchase', 'trend_up'],
        'sys_investment_sell': ['Investment sale', 'trend_down'],
      };
      expect(expected.keys.toSet(), systemSeedKeys);

      final icons = <String>{};
      for (final entry in expected.entries) {
        final row = await bySeedKey(entry.key);
        expect(row.name, entry.value[0]);
        expect(row.icon, entry.value[1]);
        expect(row.color, 0xFF9C95A8);
        expect(row.kind, CategoryKind.system);
        expect(row.isArchived, isFalse);
        icons.add(row.icon);
      }
      expect(icons, hasLength(6), reason: 'six distinct icon keys');
    });

    test(
      'an install seeded with only the original 20 gains the 6 system rows; '
      'the original 20 are byte-for-byte unchanged',
      () async {
        final userId = await ensureLocalUser(db);
        final originals = defaultCategories
            .where((c) => c.kind != CategoryKind.system)
            .toList();
        expect(originals, hasLength(20));

        // State written by the previous app version, with fixed ids and
        // timestamps, plus a user rename + archive on one of them.
        final fixed = DateTime.utc(2026, 1, 1);
        for (final c in originals) {
          await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              id: 'old-${c.seedKey}',
              userId: userId,
              name: c.name,
              icon: c.icon,
              color: c.color,
              kind: c.kind,
              seedKey: Value(c.seedKey),
              createdAt: Value(fixed),
              updatedAt: Value(fixed),
            ),
          );
        }
        await (db.update(db.categories)..where((t) => t.seedKey.equals('exp_food')))
            .write(
          const CategoriesCompanion(
            name: Value('Eating out'),
            isArchived: Value(true),
          ),
        );

        Future<List<Map<String, dynamic>>> rawRows() async => (await db
                .customSelect('SELECT * FROM categories ORDER BY id')
                .get())
            .map((r) => r.data)
            .toList();

        final before = await rawRows();
        expect(before, hasLength(20));

        await ensureBaselineData(db);

        final after = await rawRows();
        expect(after, hasLength(26));

        bool isOld(Map<String, dynamic> r) =>
            (r['id'] as String).startsWith('old-');
        expect(after.where(isOld).toList(), before);

        final added = after.where((r) => !isOld(r)).toList();
        expect(added.map((r) => r['seed_key']).toSet(), systemSeedKeys);
        expect(
          added.every((r) => r['kind'] == 'system' && r['user_id'] == userId),
          isTrue,
        );
      },
    );

    test('running bootstrap twice still gives 26, no duplicates', () async {
      await ensureBaselineData(db);
      await ensureBaselineData(db);

      final rows = await allRows();
      expect(rows, hasLength(26));
      expect(rows.map((r) => r.seedKey).toSet(), hasLength(26));
    });

    test('second run does not rewrite existing rows', () async {
      await ensureBaselineData(db);
      final before = {for (final r in await allRows()) r.id: r};

      await ensureBaselineData(db);
      final after = {for (final r in await allRows()) r.id: r};

      expect(after.keys.toSet(), before.keys.toSet());
      for (final id in before.keys) {
        expect(after[id], before[id]);
      }
    });

    test('an archived seeded category is not recreated or un-archived', () async {
      await ensureBaselineData(db);
      await (db.update(db.categories)..where((t) => t.seedKey.equals('exp_food')))
          .write(const CategoriesCompanion(isArchived: Value(true)));

      await ensureBaselineData(db);

      expect(await allRows(), hasLength(26));
      expect((await bySeedKey('exp_food')).isArchived, isTrue);
    });

    test('a renamed seeded category keeps its new name', () async {
      await ensureBaselineData(db);
      await (db.update(db.categories)..where((t) => t.seedKey.equals('exp_rent')))
          .write(const CategoriesCompanion(name: Value('Home loan EMI')));

      await ensureBaselineData(db);

      expect(await allRows(), hasLength(26));
      expect((await bySeedKey('exp_rent')).name, 'Home loan EMI');
    });

    test('a missing seed key is added back without touching the rest', () async {
      await ensureBaselineData(db);
      // Simulates a later app version adding a new default category.
      await (db.delete(db.categories)..where((t) => t.seedKey.equals('inc_other')))
          .go();
      await (db.update(db.categories)..where((t) => t.seedKey.equals('exp_food')))
          .write(const CategoriesCompanion(name: Value('Eating out')));

      await ensureBaselineData(db);

      expect(await allRows(), hasLength(26));
      expect((await bySeedKey('exp_food')).name, 'Eating out');
    });

    test('two different user_ids each get their own full set', () async {
      await seedDefaultCategories(db, 'user-a');
      await seedDefaultCategories(db, 'user-b');

      final dao = CategoriesDao(db);
      expect(await dao.getAll('user-a'), hasLength(26));
      expect(await dao.getAll('user-b'), hasLength(26));
      expect(await allRows(), hasLength(52));

      // Same seed_key exists once per user, with different row ids.
      final foodRows = await (db.select(
        db.categories,
      )..where((t) => t.seedKey.equals('exp_food'))).get();
      expect(foodRows, hasLength(2));
      expect(foodRows[0].id, isNot(foodRows[1].id));
    });

    test('a user-created category (seed_key null) is untouched', () async {
      final userId = await ensureLocalUser(db);
      final dao = CategoriesDao(db);
      await dao.insert(
        CategoriesCompanion.insert(
          id: generateId(),
          userId: userId,
          name: 'Pet care',
          icon: 'paw_print',
          color: 0xFF112233,
          kind: CategoryKind.expense,
        ),
      );
      // Several NULL seed_keys for one user must be allowed.
      await dao.insert(
        CategoriesCompanion.insert(
          id: generateId(),
          userId: userId,
          name: 'Side gig',
          icon: 'briefcase',
          color: 0xFF445566,
          kind: CategoryKind.income,
        ),
      );

      await ensureBaselineData(db);
      await ensureBaselineData(db);

      final rows = await allRows();
      expect(rows, hasLength(28));
      final mine = rows.where((r) => r.seedKey == null).toList();
      expect(mine.map((r) => r.name).toSet(), {'Pet care', 'Side gig'});
      expect(mine.firstWhere((r) => r.name == 'Pet care').color, 0xFF112233);
    });

    test('unique (user_id, seed_key) rejects a duplicate insert', () async {
      final userId = await ensureLocalUser(db);
      await seedDefaultCategories(db, userId);

      await expectLater(
        CategoriesDao(db).insert(
          CategoriesCompanion.insert(
            id: generateId(),
            userId: userId,
            name: 'Food again',
            icon: 'fork_knife',
            color: 0xFFC97B84,
            kind: CategoryKind.expense,
            seedKey: const Value('exp_food'),
          ),
        ),
        throwsA(anything),
      );
    });
  });

  group('local user row', () {
    test('is created when missing and not duplicated when present', () async {
      expect(await db.select(db.userProfile).get(), isEmpty);

      await ensureBaselineData(db);
      final first = await db.select(db.userProfile).get();
      expect(first, hasLength(1));
      expect(first.single.userId, isNotNull);
      expect(first.single.userId, isNotEmpty);

      await ensureBaselineData(db);
      final second = await db.select(db.userProfile).get();
      expect(second, hasLength(1));
      expect(second.single.id, first.single.id);
      expect(second.single.userId, first.single.userId);
    });

    test('categories are scoped to the local user id', () async {
      await ensureBaselineData(db);

      final profile = await db.select(db.userProfile).getSingle();
      final rows = await allRows();
      expect(rows.every((r) => r.userId == profile.userId), isTrue);
    });

    test('an existing row with a user_id is reused and left intact', () async {
      await db.into(db.userProfile).insert(
        UserProfileCompanion.insert(
          id: 'profile-1',
          userId: const Value('existing-user'),
          displayName: const Value('Asha'),
          birthdate: Value(DateTime(1995, 4, 12)),
        ),
      );

      await ensureBaselineData(db);

      final profiles = await db.select(db.userProfile).get();
      expect(profiles, hasLength(1));
      expect(profiles.single.userId, 'existing-user');
      expect(profiles.single.displayName, 'Asha');
      expect(profiles.single.birthdate, DateTime(1995, 4, 12));
      expect(
        (await allRows()).every((r) => r.userId == 'existing-user'),
        isTrue,
      );
    });

    test('an existing row with NULL user_id gets one, keeping its data', () async {
      await db.into(db.userProfile).insert(
        UserProfileCompanion.insert(
          id: 'profile-1',
          displayName: const Value('Asha'),
        ),
      );

      await ensureBaselineData(db);

      final profiles = await db.select(db.userProfile).get();
      expect(profiles, hasLength(1));
      expect(profiles.single.id, 'profile-1');
      expect(profiles.single.displayName, 'Asha');
      expect(profiles.single.userId, isNotNull);
      expect(profiles.single.userId, isNotEmpty);
    });
  });

  group('failure handling', () {
    Future<void> failingSeeder(AppDatabase db, String userId) async {
      throw StateError('boom');
    }

    test('failFast rethrows and rolls the seeders back as one', () async {
      await expectLater(
        ensureBaselineData(
          db,
          failFast: true,
          seeders: [seedDefaultCategories, failingSeeder],
        ),
        throwsStateError,
      );

      // First seeder's inserts were rolled back with the failure...
      expect(await allRows(), isEmpty);
      // ...but the local user row (created before the transaction) stays.
      expect(await db.select(db.userProfile).get(), hasLength(1));
    });

    test('release behaviour swallows the error and retries next start', () async {
      await ensureBaselineData(
        db,
        failFast: false,
        seeders: [seedDefaultCategories, failingSeeder],
      );
      expect(await allRows(), isEmpty);

      // "Next start": the normal seeders succeed.
      await ensureBaselineData(db, failFast: false);
      expect(await allRows(), hasLength(26));
      expect(await db.select(db.userProfile).get(), hasLength(1));
    });
  });

  group('CategoriesDao', () {
    late CategoriesDao dao;
    late String userId;

    setUp(() async {
      dao = CategoriesDao(db);
      userId = await ensureLocalUser(db);
      await seedDefaultCategories(db, userId);
    });

    test('watchByKind returns only that kind, sorted by name', () async {
      final income = await dao.watchByKind(userId, CategoryKind.income).first;
      expect(income, hasLength(6));
      expect(income.every((c) => c.kind == CategoryKind.income), isTrue);
      final names = income.map((c) => c.name).toList();
      expect(names, [...names]..sort());

      final expense = await dao.watchByKind(userId, CategoryKind.expense).first;
      expect(expense, hasLength(14));
    });

    test('watchByKind hides archived unless asked', () async {
      await (db.update(db.categories)..where((t) => t.seedKey.equals('exp_food')))
          .write(const CategoriesCompanion(isArchived: Value(true)));

      final hidden = await dao.watchByKind(userId, CategoryKind.expense).first;
      expect(hidden, hasLength(13));
      expect(hidden.any((c) => c.seedKey == 'exp_food'), isFalse);

      final all = await dao
          .watchByKind(userId, CategoryKind.expense, includeArchived: true)
          .first;
      expect(all, hasLength(14));
    });

    test('watchByKind is scoped to the user', () async {
      await seedDefaultCategories(db, 'someone-else');
      final mine = await dao.watchByKind(userId, CategoryKind.expense).first;
      expect(mine, hasLength(14));
      expect(mine.every((c) => c.userId == userId), isTrue);
    });

    test('income/expense never return system rows; system returns the six', () async {
      for (final includeArchived in [false, true]) {
        final income = await dao
            .watchByKind(userId, CategoryKind.income, includeArchived: includeArchived)
            .first;
        final expense = await dao
            .watchByKind(userId, CategoryKind.expense, includeArchived: includeArchived)
            .first;
        expect(income.every((c) => c.kind == CategoryKind.income), isTrue);
        expect(expense.every((c) => c.kind == CategoryKind.expense), isTrue);
        expect(
          [...income, ...expense].any((c) => systemSeedKeys.contains(c.seedKey)),
          isFalse,
        );
      }

      final system = await dao.watchByKind(userId, CategoryKind.system).first;
      expect(system, hasLength(6));
      expect(system.map((c) => c.seedKey).toSet(), systemSeedKeys);
      expect(system.every((c) => c.kind == CategoryKind.system), isTrue);
    });

    test('getBySeedKey: right row, null for unknown key or other user', () async {
      final food = await dao.getBySeedKey(userId, 'exp_food');
      expect(food, isNotNull);
      expect(food!.name, 'Food & Dining');
      expect(food.userId, userId);

      final loan = await dao.getBySeedKey(userId, 'sys_loan_given');
      expect(loan?.kind, CategoryKind.system);
      expect(loan?.name, 'Loan given');

      expect(await dao.getBySeedKey(userId, 'no_such_key'), isNull);
      // Another user has no rows yet.
      expect(await dao.getBySeedKey('someone-else', 'exp_food'), isNull);

      await seedDefaultCategories(db, 'someone-else');
      final theirs = await dao.getBySeedKey('someone-else', 'exp_food');
      expect(theirs, isNotNull);
      expect(theirs!.userId, 'someone-else');
      expect(theirs.id, isNot(food.id));
      expect(await dao.getBySeedKey(userId, 'exp_food'), food);
    });

    test('getById and getAll', () async {
      final food = await bySeedKey('exp_food');
      expect((await dao.getById(food.id))?.name, 'Food & Dining');
      expect(await dao.getById('no-such-id'), isNull);

      await (db.update(db.categories)..where((t) => t.seedKey.equals('exp_food')))
          .write(const CategoriesCompanion(isArchived: Value(true)));
      expect(await dao.getAll(userId), hasLength(26)); // archived included
      expect(await dao.getAll('someone-else'), isEmpty);
    });
  });

  group('migration v1 -> v2', () {
    test('adds categories and index, keeps existing data', () async {
      await db.close(); // replace the default per-test database

      db = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            // The exact v1 schema: user_profile + remote_status_cache.
            raw.execute('''
              CREATE TABLE user_profile (
                id TEXT NOT NULL,
                user_id TEXT NULL,
                display_name TEXT NULL,
                birthdate INTEGER NULL,
                theme_preference TEXT NULL,
                app_lock_mode TEXT NULL,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                PRIMARY KEY (id)
              )''');
            raw.execute('''
              CREATE TABLE remote_status_cache (
                id TEXT NOT NULL,
                last_checked_at INTEGER NULL,
                maintenance_mode INTEGER NOT NULL DEFAULT 0,
                maintenance_message TEXT NULL,
                kill_switch INTEGER NOT NULL DEFAULT 0,
                last_known_good INTEGER NOT NULL DEFAULT 1,
                PRIMARY KEY (id)
              )''');
            raw.execute(
              "INSERT INTO user_profile (id, user_id, display_name, "
              "created_at, updated_at) VALUES "
              "('p1', 'old-user', 'Asha', 1700000000, 1700000000)",
            );
            raw.execute(
              "INSERT INTO remote_status_cache (id, kill_switch) "
              "VALUES ('r1', 0)",
            );
            raw.execute('PRAGMA user_version = 1');
          },
        ),
      );

      await ensureBaselineData(db);

      // Old data survived.
      final profile = await db.select(db.userProfile).getSingle();
      expect(profile.id, 'p1');
      expect(profile.userId, 'old-user');
      expect(profile.displayName, 'Asha');
      expect(await db.select(db.remoteStatusCache).get(), hasLength(1));

      // New table is usable and seeded for the pre-existing user.
      final rows = await allRows();
      expect(rows, hasLength(26));
      expect(rows.every((r) => r.userId == 'old-user'), isTrue);

      // Table and index exist.
      final schema = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE tbl_name = 'categories'",
          )
          .get();
      final names = schema.map((r) => r.read<String>('name')).toSet();
      expect(names, contains('categories'));
      expect(names, contains('categories_user_kind_idx'));
    });
  });

  group('source guard', () {
    test('CategoriesDao offers no delete or update', () {
      // Built-ins may be renamed/archived but never deleted, and there is no
      // edit UI yet, so the DAO must not expose either.
      final source = File(
        'lib/features/finance/data/categories_dao.dart',
      ).readAsStringSync();
      final code = source
          .split('\n')
          .where((l) => !l.trim().startsWith('//'))
          .join('\n');

      expect(code.contains('.delete('), isFalse);
      expect(code.contains('.update('), isFalse);
      expect(RegExp(r'Future<[^>]*>\s+(delete|update|remove)\w*\(').hasMatch(code), isFalse);
    });
  });
}