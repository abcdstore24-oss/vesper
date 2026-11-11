import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/core/db/db_bootstrap.dart';
import 'package:vesper/features/finance/data/categories_dao.dart';
import 'package:vesper/features/finance/data/categories_table.dart';

/// Task: manage categories. create / edit / setArchived and their rules.
/// (That the DAO never offers a delete is the "source guard" test in
/// test/core/db/db_bootstrap_test.dart.)
Matcher _fails(CategoryValidationError expected) => throwsA(
  isA<CategoryValidationException>().having((e) => e.error, 'error', expected),
);

void main() {
  late AppDatabase db;
  late String userId;
  late CategoriesDao dao;

  const green = 0xFF8FB38A;
  const rose = 0xFFC97B84;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await ensureBaselineData(db);
    userId = await ensureLocalUser(db);
    dao = CategoriesDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> make(
    String name, {
    CategoryKind kind = CategoryKind.expense,
    String icon = 'tag',
    int color = rose,
    String? user,
  }) => dao.create(
    userId: user ?? userId,
    name: name,
    kind: kind,
    icon: icon,
    color: color,
  );

  Future<CategoryRow> row(String id) async => (await dao.getById(id))!;

  group('create', () {
    test('creates a user category and returns its id', () async {
      final id = await make('Pets', icon: 'paw_print', color: green);

      final r = await row(id);
      expect(r.userId, userId);
      expect(r.name, 'Pets');
      expect(r.kind, CategoryKind.expense);
      expect(r.icon, 'paw_print');
      expect(r.color, green);
      expect(r.seedKey, isNull);
      expect(r.isArchived, isFalse);
      expect(id, isNotEmpty);
    });

    test('an income category works too', () async {
      final id = await make('Freelance', kind: CategoryKind.income);
      expect((await row(id)).kind, CategoryKind.income);
    });

    test('the name is trimmed', () async {
      final id = await make('  Pets  ');
      expect((await row(id)).name, 'Pets');
    });

    test('empty and whitespace-only names are rejected', () async {
      await expectLater(make(''), _fails(CategoryValidationError.emptyName));
      await expectLater(make('   '), _fails(CategoryValidationError.emptyName));
    });

    test('40 characters are fine, 41 are not', () async {
      await make('a' * 40);
      await expectLater(
        make('b' * 41),
        _fails(CategoryValidationError.nameTooLong),
      );
    });

    test('a duplicate name is rejected, ignoring case and spaces', () async {
      await make('Pets');
      await expectLater(
        make('pets'),
        _fails(CategoryValidationError.duplicateName),
      );
      await expectLater(
        make('  PETS '),
        _fails(CategoryValidationError.duplicateName),
      );
      // A built-in name counts too.
      await expectLater(
        make('food & dining'),
        _fails(CategoryValidationError.duplicateName),
      );
    });

    test('an ARCHIVED duplicate is rejected with its own error', () async {
      final id = await make('Pets');
      await dao.setArchived(id, true);

      await expectLater(
        make('pets'),
        _fails(CategoryValidationError.duplicateNameArchived),
      );
    });

    test('the same name in the OTHER kind is allowed', () async {
      await make('Gifts'); // expense (a built-in income "Gifts" exists too)
      final id = await make('Bonus');
      final income = await make('Bonus', kind: CategoryKind.income);
      expect(income, isNot(id));
    });

    test('a system category cannot be created', () async {
      await expectLater(
        make('Loan thing', kind: CategoryKind.system),
        _fails(CategoryValidationError.kindNotAllowed),
      );
    });

    test('icon: a snake_case key, at most 40 characters', () async {
      for (final bad in [
        '',
        'Tag',
        'fork-knife',
        '1tag',
        'tag!',
        'a b',
        '_x',
      ]) {
        await expectLater(
          make('Icon test', icon: bad),
          _fails(CategoryValidationError.invalidIcon),
          reason: 'icon "$bad"',
        );
      }
      await expectLater(
        make('Icon test', icon: 'a' * 41),
        _fails(CategoryValidationError.invalidIcon),
      );
      await make('Icon ok', icon: 'a' * 40);
      await make('Icon ok 2', icon: 'a1_b2');
    });

    test('colour: opaque 0xFFRRGGBB only', () async {
      for (final bad in [0, 0x00123456, 0x80123456, 0xFEFFFFFF, -1]) {
        await expectLater(
          make('Colour test', color: bad),
          _fails(CategoryValidationError.invalidColor),
          reason: 'colour $bad',
        );
      }
      await make('Colour ok', color: 0xFF000000);
      await make('Colour ok 2', color: 0xFFFFFFFF);
    });

    test('a failed create writes nothing', () async {
      final before = (await dao.getAll(userId)).length;
      await expectLater(make(''), throwsA(isA<CategoryValidationException>()));
      expect((await dao.getAll(userId)).length, before);
    });
  });

  group('edit', () {
    test('changes name, icon and colour; kind and seed_key stay', () async {
      final id = await make('Pets');
      await dao.edit(id, name: 'Animals', icon: 'house', color: green);

      final r = await row(id);
      expect(r.name, 'Animals');
      expect(r.icon, 'house');
      expect(r.color, green);
      expect(r.kind, CategoryKind.expense);
      expect(r.seedKey, isNull);
    });

    test('null fields stay unchanged', () async {
      final id = await make('Pets', icon: 'paw_print', color: green);
      await dao.edit(id, name: 'Animals');

      final r = await row(id);
      expect(r.name, 'Animals');
      expect(r.icon, 'paw_print');
      expect(r.color, green);
    });

    test('the name is trimmed', () async {
      final id = await make('Pets');
      await dao.edit(id, name: '  Animals ');
      expect((await row(id)).name, 'Animals');
    });

    test('keeping its own name (even in another case) is fine', () async {
      final id = await make('Pets');
      await dao.edit(id, name: 'Pets');
      await dao.edit(id, name: 'PETS');
      expect((await row(id)).name, 'PETS');
    });

    test('another row\'s name is rejected, archived or not', () async {
      final a = await make('Pets');
      final b = await make('Animals');
      await expectLater(
        dao.edit(a, name: 'animals'),
        _fails(CategoryValidationError.duplicateName),
      );
      await dao.setArchived(b, true);
      await expectLater(
        dao.edit(a, name: 'Animals'),
        _fails(CategoryValidationError.duplicateNameArchived),
      );
      expect((await row(a)).name, 'Pets');
    });

    test(
      'empty and over-long names, bad icon and colour are rejected',
      () async {
        final id = await make('Pets');
        await expectLater(
          dao.edit(id, name: ' '),
          _fails(CategoryValidationError.emptyName),
        );
        await expectLater(
          dao.edit(id, name: 'x' * 41),
          _fails(CategoryValidationError.nameTooLong),
        );
        await expectLater(
          dao.edit(id, icon: 'Not Valid'),
          _fails(CategoryValidationError.invalidIcon),
        );
        await expectLater(
          dao.edit(id, color: 0x00FFFFFF),
          _fails(CategoryValidationError.invalidColor),
        );
        expect((await row(id)).name, 'Pets');
      },
    );

    test(
      'a built-in can be renamed and restyled; seed_key never changes',
      () async {
        final food = (await dao.getBySeedKey(userId, 'exp_food'))!;
        await dao.edit(food.id, name: 'Meals', icon: 'tag', color: green);

        final r = await row(food.id);
        expect(r.name, 'Meals');
        expect(r.icon, 'tag');
        expect(r.color, green);
        expect(r.seedKey, 'exp_food');
        expect(r.kind, CategoryKind.expense);
        // The seeder still finds it by its seed key and does not recreate it.
        await ensureBaselineData(db);
        expect((await dao.getBySeedKey(userId, 'exp_food'))!.name, 'Meals');
      },
    );

    test('a system category is refused', () async {
      final system = (await dao.getBySeedKey(userId, 'sys_loan_given'))!;
      await expectLater(
        dao.edit(system.id, name: 'Hacked'),
        _fails(CategoryValidationError.systemCategory),
      );
      expect((await row(system.id)).name, 'Loan given');
    });

    test('updated_at changes, created_at does not', () async {
      final id = await make('Pets');
      final old = DateTime(2020, 1, 1, 12);
      await (db.update(db.categories)..where((c) => c.id.equals(id))).write(
        CategoriesCompanion(updatedAt: Value(old)),
      );
      final created = (await row(id)).createdAt;

      await dao.edit(id, name: 'Animals');

      final r = await row(id);
      expect(r.updatedAt.isAfter(old), isTrue);
      expect(r.createdAt, created);
    });

    test('an unknown id is notFound', () async {
      await expectLater(
        dao.edit('no-such-id', name: 'X'),
        _fails(CategoryValidationError.notFound),
      );
    });
  });

  group('setArchived', () {
    test('archives and restores; nothing is deleted', () async {
      final id = await make('Pets');
      final before = (await dao.getAll(userId)).length;

      await dao.setArchived(id, true);
      expect((await row(id)).isArchived, isTrue);
      expect((await dao.getAll(userId)).length, before);

      await dao.setArchived(id, false);
      expect((await row(id)).isArchived, isFalse);
    });

    test('a built-in can be archived and restored', () async {
      final food = (await dao.getBySeedKey(userId, 'exp_food'))!;
      await dao.setArchived(food.id, true);
      expect((await row(food.id)).isArchived, isTrue);
      await dao.setArchived(food.id, false);
      expect((await row(food.id)).isArchived, isFalse);
    });

    test('a restore can never clash (archived names stay reserved)', () async {
      final id = await make('Pets');
      await dao.setArchived(id, true);
      // The name could not be reused meanwhile.
      await expectLater(
        make('Pets'),
        _fails(CategoryValidationError.duplicateNameArchived),
      );
      await dao.setArchived(id, false);
      expect((await row(id)).name, 'Pets');
    });

    test('updated_at changes', () async {
      final id = await make('Pets');
      final old = DateTime(2020, 1, 1, 12);
      await (db.update(db.categories)..where((c) => c.id.equals(id))).write(
        CategoriesCompanion(updatedAt: Value(old)),
      );
      await dao.setArchived(id, true);
      expect((await row(id)).updatedAt.isAfter(old), isTrue);
    });

    test('a system category is refused; an unknown id is notFound', () async {
      final system = (await dao.getBySeedKey(userId, 'sys_loan_taken'))!;
      await expectLater(
        dao.setArchived(system.id, true),
        _fails(CategoryValidationError.systemCategory),
      );
      expect((await row(system.id)).isArchived, isFalse);
      await expectLater(
        dao.setArchived('no-such-id', true),
        _fails(CategoryValidationError.notFound),
      );
    });

    test('archived rows are hidden from the active watch only', () async {
      final id = await make('Pets');
      await dao.setArchived(id, true);

      final active = await dao.watchByKind(userId, CategoryKind.expense).first;
      final all = await dao
          .watchByKind(userId, CategoryKind.expense, includeArchived: true)
          .first;
      expect(active.map((c) => c.id), isNot(contains(id)));
      expect(all.map((c) => c.id), contains(id));
    });
  });

  group('user scoping', () {
    test('another user\'s categories do not collide or leak', () async {
      await make('Pets');
      // The same name for a different user is fine.
      final other = await make('Pets', user: 'other-user');
      expect(other, isNotEmpty);

      final mine = await dao.getAll(userId);
      expect(mine.where((c) => c.name == 'Pets'), hasLength(1));
      final theirs = await dao.getAll('other-user');
      expect(theirs.map((c) => c.userId).toSet(), {'other-user'});
    });
  });
}
