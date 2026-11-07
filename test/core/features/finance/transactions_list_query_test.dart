import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/core/db/db_bootstrap.dart';
import 'package:vesper/features/finance/data/accounts_dao.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/data/categories_dao.dart';
import 'package:vesper/features/finance/data/category_seeder.dart';
import 'package:vesper/features/finance/data/transaction_queries.dart';
import 'package:vesper/features/finance/data/transactions_dao.dart';
import 'package:vesper/features/finance/data/transactions_table.dart';

import '../../../support/test_db.dart';

/// The generalised query (type + limit) and TransactionsDao.watchAll, for
/// the full Transactions list (Task 4b-2a). The Recent behaviour itself stays
/// covered, untouched, by transaction_queries_test.dart.
void main() {
  late AppDatabase db;
  late String userId;
  late TransactionsDao dao;
  late AccountsDao accounts;
  late String bank;
  late String cash;

  final now = DateTime(2026, 10, 17, 12, 0, 0);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await ensureBaselineData(db);
    userId = await ensureLocalUser(db);
    dao = TransactionsDao(db, clock: () => now);
    accounts = AccountsDao(db);
    bank = await accounts.insert(
      userId: userId,
      name: 'Main bank',
      type: AccountType.bank,
      startingBalancePaise: 1000000,
    );
    cash = await accounts.insert(
      userId: userId,
      name: 'Wallet cash',
      type: AccountType.cash,
      startingBalancePaise: 0,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> categoryId(String seedKey, {String? user}) async =>
      (await CategoriesDao(db).getBySeedKey(user ?? userId, seedKey))!.id;

  Future<String> expense({String? note, DateTime? at, int paise = 100}) async =>
      dao.insert(
        userId: userId,
        accountId: bank,
        type: TransactionType.expense,
        amountPaise: paise,
        categoryId: await categoryId('exp_food'),
        note: note,
        occurredAt: at ?? now,
      );

  Future<String> income({String? note, DateTime? at}) async => dao.insert(
    userId: userId,
    accountId: bank,
    type: TransactionType.income,
    amountPaise: 500,
    categoryId: await categoryId('inc_salary'),
    note: note,
    occurredAt: at ?? now,
  );

  Future<String> transfer({String? note, DateTime? at}) async => dao.insert(
    userId: userId,
    accountId: bank,
    toAccountId: cash,
    type: TransactionType.transfer,
    amountPaise: 300,
    note: note,
    occurredAt: at ?? now,
  );

  Future<List<String?>> notes({TransactionType? type}) async {
    final items = await dao.watchAll(userId, type: type).first;
    return items.map((i) => i.transaction.note).toList();
  }

  test(
    'watchAll returns every row, newest first, with a rowid tiebreak',
    () async {
      final same = DateTime(2026, 10, 17, 9, 15, 30);
      await expense(note: 'older day', at: DateTime(2026, 10, 1));
      await expense(note: 'same1', at: same);
      await expense(note: 'same2', at: same);
      await expense(note: 'same3', at: same);
      await expense(note: 'newest day', at: now);

      expect(await notes(), [
        'newest day',
        'same3',
        'same2',
        'same1',
        'older day',
      ]);
    },
  );

  test(
    'no limit: more than 5 rows come back (Recent still limits to 5)',
    () async {
      for (var i = 1; i <= 8; i++) {
        await expense(
          note: 'n$i',
          at: now.subtract(Duration(days: 9 - i)),
        );
      }

      expect(await notes(), hasLength(8));
      final recent = await dao.watchRecent(userId).first;
      expect(recent.map((i) => i.transaction.note), [
        'n8',
        'n7',
        'n6',
        'n5',
        'n4',
      ]);
      final two = await selectRecentTransactions(
        db,
        userId: userId,
        limit: 2,
      ).get();
      expect(two, hasLength(2));
    },
  );

  test('the type filter is applied in SQL', () async {
    await expense(note: 'e1');
    await income(note: 'i1');
    await transfer(note: 't1');
    await expense(note: 'e2');

    expect(await notes(type: TransactionType.expense), ['e2', 'e1']);
    expect(await notes(type: TransactionType.income), ['i1']);
    expect(await notes(type: TransactionType.transfer), ['t1']);
    expect(await notes(), hasLength(4));

    // Type and limit together.
    final limited = await selectRecentTransactions(
      db,
      userId: userId,
      type: TransactionType.expense,
      limit: 1,
    ).get();
    expect(limited.map((i) => i.transaction.note), ['e2']);
  });

  test("another user's rows are excluded", () async {
    await expense(note: 'mine');
    final theirAccount = await accounts.insert(
      userId: 'other-user',
      name: 'Theirs',
      type: AccountType.bank,
      startingBalancePaise: 1000,
    );
    await seedDefaultCategories(db, 'other-user');
    await dao.insert(
      userId: 'other-user',
      accountId: theirAccount,
      type: TransactionType.expense,
      amountPaise: 100,
      categoryId: await categoryId('exp_food', user: 'other-user'),
      note: 'theirs',
      occurredAt: now,
    );

    expect(await notes(), ['mine']);
    expect(await notes(type: TransactionType.expense), ['mine']);
  });

  test('rows with a source are included and filter by their type', () async {
    await dao.insert(
      userId: userId,
      accountId: bank,
      type: TransactionType.expense,
      amountPaise: 700,
      categoryId: await categoryId('sys_loan_given'),
      note: 'loan out',
      occurredAt: now,
      source: TransactionSource.loan,
      sourceId: 'loan-1',
    );
    await expense(note: 'plain', at: now.subtract(const Duration(days: 1)));

    expect(await notes(), ['loan out', 'plain']);
    expect(await notes(type: TransactionType.expense), ['loan out', 'plain']);
    expect(await notes(type: TransactionType.income), isEmpty);
    final first = (await dao.watchAll(userId).first).first;
    expect(first.transaction.sourceType, TransactionSource.loan);
  });

  test('archived category and account names are still shown', () async {
    final id = await expense(note: 'kept');
    final row = (await dao.getById(id))!;

    await (db.update(db.categories)..where((c) => c.id.equals(row.categoryId!)))
        .write(const CategoriesCompanion(isArchived: Value(true)));
    await (db.update(db.accounts)..where((a) => a.id.equals(bank))).write(
      const AccountsCompanion(isArchived: Value(true)),
    );

    final items = await dao.watchAll(userId).first;
    expect(items, hasLength(1));
    expect(items.single.categoryName, 'Food & Dining');
    expect(items.single.accountName, 'Main bank');
  });

  test('a missing category still shows the row (LEFT join)', () async {
    final id = await expense(note: 'orphan');
    await (db.update(db.transactions)..where((t) => t.id.equals(id))).write(
      const TransactionsCompanion(categoryId: Value('does-not-exist')),
    );

    final items = await dao.watchAll(userId).first;
    expect(items, hasLength(1));
    expect(items.single.categoryName, isNull);
  });

  test('the stream re-emits after insert, rename and delete', () async {
    final emissions = <List<TransactionListItem>>[];
    final subscription = dao.watchAll(userId).listen(emissions.add);
    addTearDown(subscription.cancel);

    await pumpUntil(() => emissions.isNotEmpty);
    expect(emissions.last, isEmpty);

    final first = await expense(note: 'first');
    await pumpUntil(() => emissions.last.length == 1);

    await expense(note: 'second');
    await pumpUntil(() => emissions.last.length == 2);
    expect(emissions.last.first.transaction.note, 'second');

    // Accounts and categories feed the names, so they re-emit too.
    await accounts.update(bank, name: 'Renamed bank');
    await pumpUntil(() => emissions.last.first.accountName == 'Renamed bank');
    await (db.update(db.categories)..where((c) => c.seedKey.equals('exp_food')))
        .write(const CategoriesCompanion(name: Value('Meals')));
    await pumpUntil(() => emissions.last.first.categoryName == 'Meals');

    await dao.delete(first);
    await pumpUntil(() => emissions.last.length == 1);
    expect(emissions.last.single.transaction.note, 'second');
  });
}
