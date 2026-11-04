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

void main() {
  late AppDatabase db;
  late String userId;
  late TransactionsDao dao;
  late AccountsDao accounts;
  late String bank;
  late String cash;

  // Whole seconds, because Drift stores DateTime as whole seconds.
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

  Future<String> expense({
    String? note,
    DateTime? at,
    int paise = 100,
    String seed = 'exp_food',
  }) async => dao.insert(
    userId: userId,
    accountId: bank,
    type: TransactionType.expense,
    amountPaise: paise,
    categoryId: await categoryId(seed),
    note: note,
    occurredAt: at ?? now,
  );

  Future<List<TransactionListItem>> recent({int limit = 5}) =>
      selectRecentTransactions(db, userId: userId, limit: limit).get();

  test('joins the category and account names', () async {
    await expense(note: 'Lunch', seed: 'exp_food');
    await dao.insert(
      userId: userId,
      accountId: bank,
      toAccountId: cash,
      type: TransactionType.transfer,
      amountPaise: 5000,
      occurredAt: now.subtract(const Duration(hours: 1)),
    );

    final items = await recent();
    expect(items, hasLength(2));

    final expenseItem = items.first;
    expect(expenseItem.transaction.note, 'Lunch');
    expect(expenseItem.categoryName, 'Food & Dining');
    expect(expenseItem.categoryIcon, 'fork_knife');
    expect(expenseItem.accountName, 'Main bank');
    expect(expenseItem.toAccountName, isNull);

    final transferItem = items.last;
    expect(transferItem.transaction.type, TransactionType.transfer);
    expect(transferItem.categoryName, isNull);
    expect(transferItem.categoryIcon, isNull);
    expect(transferItem.accountName, 'Main bank');
    expect(transferItem.toAccountName, 'Wallet cash');
  });

  test('the limit is applied, newest first', () async {
    for (var i = 1; i <= 7; i++) {
      await expense(
        note: 'n$i',
        at: now.subtract(Duration(days: 8 - i)), // n7 is the newest day
      );
    }

    final five = await recent();
    expect(five.map((i) => i.transaction.note), ['n7', 'n6', 'n5', 'n4', 'n3']);

    final two = await recent(limit: 2);
    expect(two.map((i) => i.transaction.note), ['n7', 'n6']);

    final watched = await dao.watchRecent(userId).first;
    expect(watched, hasLength(5));
  });

  test('occurred_at decides before insertion order', () async {
    await expense(note: 'newer date, added first', at: DateTime(2026, 10, 10));
    await expense(note: 'older date, added last', at: DateTime(2026, 10, 1));

    final items = await recent();
    expect(items.map((i) => i.transaction.note), [
      'newer date, added first',
      'older date, added last',
    ]);
  });

  test('rows in the same second come out newest-first (rowid tiebreak)', () async {
    final same = DateTime(2026, 10, 17, 9, 15, 30);
    for (var i = 1; i <= 4; i++) {
      await expense(note: 'same$i', at: same);
    }

    final items = await recent();
    expect(items.map((i) => i.transaction.note), [
      'same4',
      'same3',
      'same2',
      'same1',
    ]);
  });

  test('other users\' transactions are excluded', () async {
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

    final mine = await recent();
    expect(mine.map((i) => i.transaction.note), ['mine']);
    final theirs = await selectRecentTransactions(
      db,
      userId: 'other-user',
      limit: 5,
    ).get();
    expect(theirs.map((i) => i.transaction.note), ['theirs']);
  });

  test('the stream re-emits on insert and when an account is renamed', () async {
    final emissions = <List<TransactionListItem>>[];
    final subscription = dao.watchRecent(userId).listen(emissions.add);
    addTearDown(subscription.cancel);

    await pumpUntil(() => emissions.isNotEmpty);
    expect(emissions.last, isEmpty);

    await expense(note: 'first');
    await pumpUntil(() => emissions.last.length == 1);
    expect(emissions.last.single.transaction.note, 'first');

    await expense(note: 'second');
    await pumpUntil(() => emissions.last.length == 2);
    expect(emissions.last.first.transaction.note, 'second');

    await accounts.update(bank, name: 'Renamed bank');
    await pumpUntil(() => emissions.last.first.accountName == 'Renamed bank');
  });
}
