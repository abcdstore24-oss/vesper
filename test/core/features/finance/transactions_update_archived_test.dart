import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/core/db/db_bootstrap.dart';
import 'package:vesper/features/finance/data/accounts_dao.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/data/categories_dao.dart';
import 'package:vesper/features/finance/data/transactions_dao.dart';
import 'package:vesper/features/finance/data/transactions_table.dart';

/// Task 4b-2b: the ONE DAO rule change. On update, an ARCHIVED category is
/// accepted when it is the row's current category; everything else about
/// categories and accounts is unchanged, and insert() is unchanged.
Matcher _fails(TransactionValidationError expected) => throwsA(
  isA<TransactionValidationException>().having(
    (e) => e.error,
    'error',
    expected,
  ),
);

void main() {
  late AppDatabase db;
  late String userId;
  late TransactionsDao dao;
  late String bank;
  late String cash;

  final now = DateTime(2026, 10, 17, 12, 0, 0);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await ensureBaselineData(db);
    userId = await ensureLocalUser(db);
    dao = TransactionsDao(db, clock: () => now);
    final accounts = AccountsDao(db);
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

  Future<String> cat(String seedKey) async =>
      (await CategoriesDao(db).getBySeedKey(userId, seedKey))!.id;

  Future<void> archiveCategory(String id) =>
      (db.update(db.categories)..where((c) => c.id.equals(id))).write(
        const CategoriesCompanion(isArchived: Value(true)),
      );

  Future<void> archiveAccount(String id) =>
      (db.update(db.accounts)..where((a) => a.id.equals(id))).write(
        const AccountsCompanion(isArchived: Value(true)),
      );

  Future<String> expense({String? category, int paise = 1000}) async =>
      dao.insert(
        userId: userId,
        accountId: bank,
        type: TransactionType.expense,
        amountPaise: paise,
        categoryId: category ?? await cat('exp_food'),
        note: 'orig',
        occurredAt: now,
      );

  Future<void> update(
    String id, {
    String? account,
    TransactionType type = TransactionType.expense,
    String? category,
    String? toAccount,
    int paise = 1000,
    String? note = 'edited',
  }) async {
    final categoryId =
        category ??
        (type == TransactionType.transfer ? null : await cat('exp_food'));
    await dao.update(
      id,
      accountId: account ?? bank,
      type: type,
      amountPaise: paise,
      categoryId: categoryId,
      toAccountId: toAccount,
      note: note,
      occurredAt: now,
    );
  }

  test('an archived CURRENT category is accepted on update', () async {
    final food = await cat('exp_food');
    final id = await expense(category: food);
    await archiveCategory(food);

    await update(id, category: food, paise: 2500, note: 'new note');

    final row = (await dao.getById(id))!;
    expect(row.categoryId, food);
    expect(row.amount, 2500);
    expect(row.note, 'new note');
  });

  test('a DIFFERENT archived category is still rejected', () async {
    final food = await cat('exp_food');
    final transport = await cat('exp_transport');
    final id = await expense(category: food);
    await archiveCategory(transport);

    await expectLater(
      update(id, category: transport),
      _fails(TransactionValidationError.categoryInvalid),
    );
    // Even when the row's own category is archived too.
    await archiveCategory(food);
    await expectLater(
      update(id, category: transport),
      _fails(TransactionValidationError.categoryInvalid),
    );
    expect((await dao.getById(id))!.categoryId, food);
  });

  test('switching from an archived category to an ACTIVE one works', () async {
    final food = await cat('exp_food');
    final id = await expense(category: food);
    await archiveCategory(food);

    final transport = await cat('exp_transport');
    await update(id, category: transport);
    expect((await dao.getById(id))!.categoryId, transport);
  });

  test('the kept category must still match the type (type switch)', () async {
    final food = await cat('exp_food');
    final id = await expense(category: food);
    await archiveCategory(food);

    // Same (archived) expense category, but the row becomes income.
    await expectLater(
      update(id, type: TransactionType.income, category: food),
      _fails(TransactionValidationError.categoryInvalid),
    );
    final row = (await dao.getById(id))!;
    expect(row.type, TransactionType.expense);
    expect(row.categoryId, food);
  });

  test(
    'a system category is still rejected for a row without a source',
    () async {
      final id = await expense();
      await expectLater(
        update(id, category: await cat('sys_loan_given')),
        _fails(TransactionValidationError.categoryInvalid),
      );
    },
  );

  test('sourced rows are still rejected (linkedToSource)', () async {
    final sys = await cat('sys_loan_given');
    final linked = await dao.insert(
      userId: userId,
      accountId: bank,
      type: TransactionType.expense,
      amountPaise: 700,
      categoryId: sys,
      occurredAt: now,
      source: TransactionSource.loan,
      sourceId: 'loan-1',
    );
    await archiveCategory(sys);

    await expectLater(
      update(linked, category: sys, paise: 700),
      _fails(TransactionValidationError.linkedToSource),
    );
    expect((await dao.getById(linked))!.amount, 700);
  });

  test(
    'an ARCHIVED account is rejected on update; an active one works',
    () async {
      final id = await expense();
      await archiveAccount(bank);

      await expectLater(
        update(id),
        _fails(TransactionValidationError.accountArchived),
      );
      expect((await dao.getById(id))!.accountId, bank);

      await update(id, account: cash, category: await cat('exp_food'));
      expect((await dao.getById(id))!.accountId, cash);
    },
  );

  test('an archived category is NOT allowed on insert', () async {
    final food = await cat('exp_food');
    await archiveCategory(food);

    await expectLater(
      dao.insert(
        userId: userId,
        accountId: bank,
        type: TransactionType.expense,
        amountPaise: 100,
        categoryId: food,
        occurredAt: now,
      ),
      _fails(TransactionValidationError.categoryInvalid),
    );
    expect(await db.select(db.transactions).get(), isEmpty);
  });

  test('update of a missing row is notFound', () async {
    await expectLater(
      update('no-such-id', category: await cat('exp_food')),
      _fails(TransactionValidationError.notFound),
    );
  });
}
