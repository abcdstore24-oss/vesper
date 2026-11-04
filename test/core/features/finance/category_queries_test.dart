import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/core/db/db_bootstrap.dart';
import 'package:vesper/features/finance/data/accounts_dao.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/data/categories_dao.dart';
import 'package:vesper/features/finance/data/categories_table.dart';
import 'package:vesper/features/finance/data/category_queries.dart';
import 'package:vesper/features/finance/data/category_seeder.dart';
import 'package:vesper/features/finance/data/transactions_dao.dart';
import 'package:vesper/features/finance/data/transactions_table.dart';

import '../../../support/test_db.dart';

void main() {
  late AppDatabase db;
  late String userId;
  late TransactionsDao dao;
  late String account;

  // Whole seconds, because Drift stores DateTime as whole seconds.
  final now = DateTime(2026, 10, 17, 12, 0, 0);
  DateTime oct(int day) => DateTime(2026, 10, day, 12);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await ensureBaselineData(db);
    userId = await ensureLocalUser(db);
    dao = TransactionsDao(db, clock: () => now);
    account = await AccountsDao(db).insert(
      userId: userId,
      name: 'Main bank',
      type: AccountType.bank,
      startingBalancePaise: 10000000,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> categoryId(String seedKey, {String? user}) async =>
      (await CategoriesDao(db).getBySeedKey(user ?? userId, seedKey))!.id;

  Future<void> add(
    String seedKey,
    DateTime at, {
    TransactionType type = TransactionType.expense,
    TransactionSource? source,
  }) async {
    await dao.insert(
      userId: userId,
      accountId: account,
      type: type,
      amountPaise: 100,
      categoryId: await categoryId(seedKey),
      occurredAt: at,
      source: source,
      sourceId: source == null ? null : 'src-1',
    );
  }

  Future<List<String>> recentNames({
    CategoryKind kind = CategoryKind.expense,
    int limit = 5,
    String? user,
  }) async {
    final rows = await selectRecentCategories(
      db,
      userId: user ?? userId,
      kind: kind,
      limit: limit,
    ).get();
    return rows.map((c) => c.name).toList();
  }

  test('newest use first; each category once; ties by created_at then rowid', () async {
    await add('exp_food', oct(10));
    await add('exp_rent', oct(12));
    await add('exp_food', oct(11)); // Food again, still older than Rent
    await add('exp_bills', oct(12)); // same day as Rent, added later

    expect(await recentNames(), [
      'Bills & Utilities',
      'Rent',
      'Food & Dining',
    ]);
  });

  test('the latest use of a category is what counts', () async {
    await add('exp_food', oct(1));
    await add('exp_rent', oct(5));
    await add('exp_food', oct(9)); // Food is now the most recently used

    expect(await recentNames(), ['Food & Dining', 'Rent']);
  });

  test('at most the limit (default 5), distinct categories', () async {
    const keys = [
      'exp_food',
      'exp_groceries',
      'exp_transport',
      'exp_bills',
      'exp_rent',
      'exp_shopping',
      'exp_health',
    ];
    for (var i = 0; i < keys.length; i++) {
      await add(keys[i], oct(i + 1));
      await add(keys[i], oct(i + 1)); // used twice: still listed once
    }

    final five = await recentNames();
    expect(five, hasLength(5));
    expect(five, ['Health', 'Shopping', 'Rent', 'Bills & Utilities', 'Transport']);
    expect(await recentNames(limit: 2), ['Health', 'Shopping']);
    expect(await recentNames(limit: 50), hasLength(7));
  });

  test('archived categories are dropped', () async {
    await add('exp_food', oct(10));
    await add('exp_rent', oct(11));
    await (db.update(db.categories)..where((t) => t.seedKey.equals('exp_rent')))
        .write(const CategoriesCompanion(isArchived: Value(true)));

    expect(await recentNames(), ['Food & Dining']);
  });

  test('rows with a source (and system categories) are ignored', () async {
    await add('exp_food', oct(10));
    await add('sys_loan_given', oct(12), source: TransactionSource.loan);
    await add(
      'sys_investment_sell',
      oct(13),
      type: TransactionType.income,
      source: TransactionSource.investment,
    );

    expect(await recentNames(), ['Food & Dining']);
    expect(await recentNames(kind: CategoryKind.income), isEmpty);
  });

  test('the kind matches: income and expense lists are separate', () async {
    await add('exp_food', oct(10));
    await add('inc_salary', oct(11), type: TransactionType.income);
    await add('inc_gifts', oct(12), type: TransactionType.income);

    expect(await recentNames(), ['Food & Dining']);
    expect(await recentNames(kind: CategoryKind.income), ['Gifts', 'Salary']);
  });

  test('transfers and never-used categories do not appear', () async {
    final other = await AccountsDao(db).insert(
      userId: userId,
      name: 'Cash',
      type: AccountType.cash,
      startingBalancePaise: 0,
    );
    await dao.insert(
      userId: userId,
      accountId: account,
      toAccountId: other,
      type: TransactionType.transfer,
      amountPaise: 500,
      occurredAt: oct(12),
    );
    await add('exp_travel', oct(10));

    expect(await recentNames(), ['Travel']);
    expect(await recentNames(kind: CategoryKind.income), isEmpty);
  });

  test('other users\' use is not counted', () async {
    await add('exp_food', oct(10));

    await seedDefaultCategories(db, 'other-user');
    final theirAccount = await AccountsDao(db).insert(
      userId: 'other-user',
      name: 'Theirs',
      type: AccountType.bank,
      startingBalancePaise: 1000,
    );
    await dao.insert(
      userId: 'other-user',
      accountId: theirAccount,
      type: TransactionType.expense,
      amountPaise: 100,
      categoryId: await categoryId('exp_rent', user: 'other-user'),
      occurredAt: oct(15),
    );

    expect(await recentNames(), ['Food & Dining']);
    expect(await recentNames(user: 'other-user'), ['Rent']);
  });

  test('the stream re-emits when a transaction is added or a category archived', () async {
    final emissions = <List<String>>[];
    final subscription = selectRecentCategories(
      db,
      userId: userId,
      kind: CategoryKind.expense,
    ).watch().listen((rows) => emissions.add([for (final c in rows) c.name]));
    addTearDown(subscription.cancel);

    await pumpUntil(() => emissions.isNotEmpty);
    expect(emissions.last, isEmpty);

    await add('exp_food', oct(10));
    await pumpUntil(() => emissions.last.length == 1);
    expect(emissions.last, ['Food & Dining']);

    await add('exp_rent', oct(11));
    await pumpUntil(() => emissions.last.length == 2);
    expect(emissions.last, ['Rent', 'Food & Dining']);

    await (db.update(db.categories)..where((t) => t.seedKey.equals('exp_rent')))
        .write(const CategoriesCompanion(isArchived: Value(true)));
    await pumpUntil(() => emissions.last.length == 1);
    expect(emissions.last, ['Food & Dining']);
  });
}
