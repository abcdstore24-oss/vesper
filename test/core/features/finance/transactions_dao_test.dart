import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/core/db/db_bootstrap.dart';
import 'package:vesper/core/utils/money.dart';
import 'package:vesper/features/finance/data/account_balance.dart';
import 'package:vesper/features/finance/data/accounts_dao.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/data/categories_dao.dart';
import 'package:vesper/features/finance/data/category_seeder.dart';
import 'package:vesper/features/finance/data/transactions_dao.dart';
import 'package:vesper/features/finance/data/transactions_table.dart';

Matcher fails(TransactionValidationError expected) => throwsA(
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
  late AccountsDao accounts;

  // Whole seconds, because Drift stores DateTime as whole seconds.
  final now = DateTime(2026, 10, 17, 12, 0, 0);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await ensureBaselineData(db); // local user + default categories
    userId = await ensureLocalUser(db);
    dao = TransactionsDao(db, clock: () => now);
    accounts = AccountsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> acct(
    String name, {
    AccountType type = AccountType.bank,
    int paise = 0,
    String? user,
  }) => accounts.insert(
    userId: user ?? userId,
    name: name,
    type: type,
    startingBalancePaise: paise,
  );

  Future<String> cat(String seedKey, {String? user}) async {
    final row = await CategoriesDao(db).getBySeedKey(user ?? userId, seedKey);
    return row!.id;
  }

  Future<String> expense(
    String account,
    int paise, {
    String seed = 'exp_food',
    DateTime? at,
    String? note,
  }) async => dao.insert(
    userId: userId,
    accountId: account,
    type: TransactionType.expense,
    amountPaise: paise,
    categoryId: await cat(seed),
    occurredAt: at ?? now,
    note: note,
  );

  Future<String> income(
    String account,
    int paise, {
    String seed = 'inc_salary',
    DateTime? at,
  }) async => dao.insert(
    userId: userId,
    accountId: account,
    type: TransactionType.income,
    amountPaise: paise,
    categoryId: await cat(seed),
    occurredAt: at ?? now,
  );

  Future<String> transfer(String from, String to, int paise) => dao.insert(
    userId: userId,
    accountId: from,
    toAccountId: to,
    type: TransactionType.transfer,
    amountPaise: paise,
    occurredAt: now,
  );

  Future<List<AccountWithBalance>> list() =>
      accounts.watchAccountsWithBalance(userId).first;

  Future<Map<String, int>> balances() async => {
    for (final a in await list()) a.account.id: a.balancePaise,
  };

  Future<int> txCount() async =>
      (await db.select(db.transactions).get()).length;

  Future<void> archiveAccount(String id) =>
      (db.update(db.accounts)..where((t) => t.id.equals(id))).write(
        const AccountsCompanion(isArchived: Value(true)),
      );

  group('balances move', () {
    test('income +, expense -, transfer both sides, exact', () async {
      final a = await acct('Bank', paise: 100000);
      final b = await acct('Cash', type: AccountType.cash);

      await income(a, 50000);
      expect(await balances(), {a: 150000, b: 0});

      await expense(a, 20000);
      expect(await balances(), {a: 130000, b: 0});

      await transfer(a, b, 30000);
      expect(await balances(), {a: 100000, b: 30000});
    });

    test('bank -> card transfer: total down, card dues down, nothing else', () async {
      final bank = await acct('Bank', paise: 100000);
      final cash = await acct('Cash', type: AccountType.cash, paise: 5000);
      final card = await acct(
        'Visa',
        type: AccountType.creditCard,
        paise: -30000,
      );

      var all = await list();
      expect(totalBalancePaise(all), 105000);
      expect(creditCardDuesPaise(all), 30000);

      await transfer(bank, card, 10000);

      all = await list();
      expect(await balances(), {bank: 90000, cash: 5000, card: -20000});
      expect(totalBalancePaise(all), 95000); // down by exactly 10000
      expect(creditCardDuesPaise(all), 20000); // down by exactly 10000
    });

    test('transfer between two non-card accounts leaves the total unchanged', () async {
      final a = await acct('Bank', paise: 100000);
      final b = await acct('Wallet', type: AccountType.wallet, paise: 2500);
      final before = totalBalancePaise(await list());

      await transfer(a, b, 40000);

      final after = totalBalancePaise(await list());
      expect(after, before);
      expect(await balances(), {a: 60000, b: 42500});
    });

    test('a card expense makes dues grow; paying it back shrinks them', () async {
      final bank = await acct('Bank', paise: 100000);
      final card = await acct('Visa', type: AccountType.creditCard);

      await expense(card, 7000);
      var all = await list();
      expect(creditCardDuesPaise(all), 7000);
      expect(totalBalancePaise(all), 100000);

      await transfer(bank, card, 7000);
      all = await list();
      expect(creditCardDuesPaise(all), 0);
      expect(totalBalancePaise(all), 93000);
    });

    test('Rs 1,00,000.00 + 1 paise sum exactly', () async {
      final a = await acct('Big', paise: 10000000);
      await income(a, 1);

      final balance = (await balances())[a]!;
      expect(balance, 10000001);
      expect(Money.format(balance), '\u20B91,00,000.01');
    });

    test('computeBalancePaise combines every part', () {
      expect(
        computeBalancePaise(
          startingBalancePaise: 100,
          incomePaise: 50,
          expensePaise: 20,
          transfersInPaise: 7,
          transfersOutPaise: 3,
        ),
        134,
      );
      expect(computeBalancePaise(startingBalancePaise: -5), -5);
    });

    test('other users\' transactions never count', () async {
      final mine = await acct('Mine', paise: 1000);
      final theirs = await acct('Theirs', paise: 1000, user: 'other-user');
      await seedDefaultCategories(db, 'other-user');
      await TransactionsDao(db, clock: () => now).insert(
        userId: 'other-user',
        accountId: theirs,
        type: TransactionType.expense,
        amountPaise: 400,
        categoryId: await cat('exp_food', user: 'other-user'),
        occurredAt: now,
      );

      expect(await balances(), {mine: 1000});
      expect(
        (await accounts.watchAccountsWithBalance('other-user').first)
            .single
            .balancePaise,
        600,
      );
    });
  });

  group('update and delete', () {
    test('update changes amount/account/type/date and balances follow', () async {
      final a = await acct('Bank', paise: 100000);
      final b = await acct('Cash', type: AccountType.cash);
      final id = await expense(a, 5000);
      expect(await balances(), {a: 95000, b: 0});

      final earlier = DateTime(2026, 10, 1, 9, 30, 0);
      await dao.update(
        id,
        accountId: b,
        type: TransactionType.income,
        amountPaise: 7000,
        categoryId: await cat('inc_salary'),
        occurredAt: earlier,
      );

      expect(await balances(), {a: 100000, b: 7000});
      final row = (await dao.getById(id))!;
      expect(row.accountId, b);
      expect(row.type, TransactionType.income);
      expect(row.amount, 7000);
      expect(row.occurredAt.isAtSameMomentAs(earlier), isTrue);
      expect(row.updatedAt.isAtSameMomentAs(now), isTrue);
    });

    test('update to a transfer and back', () async {
      final a = await acct('Bank', paise: 100000);
      final b = await acct('Cash', type: AccountType.cash);
      final id = await expense(a, 1000);

      await dao.update(
        id,
        accountId: a,
        toAccountId: b,
        type: TransactionType.transfer,
        amountPaise: 2500,
        occurredAt: now,
      );
      expect(await balances(), {a: 97500, b: 2500});
      expect((await dao.getById(id))!.categoryId, isNull);

      await dao.update(
        id,
        accountId: a,
        type: TransactionType.expense,
        amountPaise: 2500,
        categoryId: await cat('exp_food'),
        occurredAt: now,
      );
      expect(await balances(), {a: 97500, b: 0});
      expect((await dao.getById(id))!.toAccountId, isNull);
    });

    test('delete restores the balances', () async {
      final a = await acct('Bank', paise: 100000);
      final b = await acct('Cash', type: AccountType.cash, paise: 10);
      final t1 = await expense(a, 5000);
      final t2 = await transfer(a, b, 20000);
      expect(await balances(), {a: 75000, b: 20010});

      await dao.delete(t2);
      expect(await balances(), {a: 95000, b: 10});
      await dao.delete(t1);
      expect(await balances(), {a: 100000, b: 10});
      expect(await dao.getById(t1), isNull);
    });

    test('update validates like insert and a failed update changes nothing', () async {
      final a = await acct('Bank', paise: 100000);
      final id = await expense(a, 5000, note: 'keep');

      await expectLater(
        dao.update(
          id,
          accountId: a,
          type: TransactionType.expense,
          amountPaise: 0,
          categoryId: await cat('exp_food'),
          occurredAt: now,
        ),
        fails(TransactionValidationError.invalidAmount),
      );
      await expectLater(
        dao.update(
          id,
          accountId: a,
          type: TransactionType.expense,
          amountPaise: 100,
          categoryId: await cat('inc_salary'),
          occurredAt: now,
        ),
        fails(TransactionValidationError.categoryInvalid),
      );
      await expectLater(
        dao.update(
          id,
          accountId: a,
          type: TransactionType.expense,
          amountPaise: 100,
          categoryId: await cat('exp_food'),
          occurredAt: DateTime(2026, 10, 18),
        ),
        fails(TransactionValidationError.futureDate),
      );

      final row = (await dao.getById(id))!;
      expect(row.amount, 5000);
      expect(row.note, 'keep');
      expect(await balances(), {a: 95000});
    });

    test('unknown id gives notFound', () async {
      final a = await acct('Bank');
      await expectLater(
        dao.update(
          'nope',
          accountId: a,
          type: TransactionType.expense,
          amountPaise: 1,
          categoryId: await cat('exp_food'),
          occurredAt: now,
        ),
        fails(TransactionValidationError.notFound),
      );
      await expectLater(
        dao.delete('nope'),
        fails(TransactionValidationError.notFound),
      );
      expect(await dao.getById('nope'), isNull);
    });
  });

  group('validation', () {
    late String a;
    late String b;
    late String food;
    late String salary;

    setUp(() async {
      a = await acct('Bank', paise: 100000);
      b = await acct('Cash', type: AccountType.cash);
      food = await cat('exp_food');
      salary = await cat('inc_salary');
    });

    Future<String> tryInsert({
      String? account,
      TransactionType type = TransactionType.expense,
      int amount = 100,
      String? categoryId,
      String? toAccountId,
      String? note,
      DateTime? at,
      TransactionSource? source,
      String? sourceId,
      String? user,
    }) {
      return dao.insert(
        userId: user ?? userId,
        accountId: account ?? a,
        type: type,
        amountPaise: amount,
        categoryId:
            categoryId ??
            (type == TransactionType.transfer
                ? null
                : (type == TransactionType.income ? salary : food)),
        toAccountId: toAccountId,
        note: note,
        occurredAt: at ?? now,
        source: source,
        sourceId: sourceId,
      );
    }

    test('amount must be 1..Money.maxPaise', () async {
      for (final bad in [0, -1, -100, Money.maxPaise + 1]) {
        await expectLater(
          tryInsert(amount: bad),
          fails(TransactionValidationError.invalidAmount),
          reason: '$bad',
        );
      }
      await tryInsert(amount: 1);
      expect(await txCount(), 1);
    });

    test('accounts must exist and belong to the user', () async {
      await expectLater(
        tryInsert(account: 'nope'),
        fails(TransactionValidationError.accountNotFound),
      );
      final foreign = await acct('Theirs', user: 'other-user');
      await expectLater(
        tryInsert(account: foreign),
        fails(TransactionValidationError.accountNotFound),
      );
      await expectLater(
        tryInsert(
          type: TransactionType.transfer,
          toAccountId: 'nope',
        ),
        fails(TransactionValidationError.toAccountNotFound),
      );
      await expectLater(
        tryInsert(
          type: TransactionType.transfer,
          toAccountId: foreign,
        ),
        fails(TransactionValidationError.toAccountNotFound),
      );
      expect(await txCount(), 0);
    });

    test('a transfer needs a destination; income/expense must not have one', () async {
      await expectLater(
        tryInsert(type: TransactionType.transfer),
        fails(TransactionValidationError.toAccountNotFound),
      );
      await expectLater(
        tryInsert(toAccountId: b),
        fails(TransactionValidationError.toAccountNotFound),
      );
      expect(await txCount(), 0);
    });

    test('a transfer to the same account is rejected', () async {
      await expectLater(
        tryInsert(type: TransactionType.transfer, toAccountId: a),
        fails(TransactionValidationError.sameAccount),
      );
    });

    test('archived accounts are rejected (from and to)', () async {
      final archived = await acct('Old');
      await archiveAccount(archived);

      await expectLater(
        tryInsert(account: archived),
        fails(TransactionValidationError.accountArchived),
      );
      await expectLater(
        tryInsert(type: TransactionType.transfer, toAccountId: archived),
        fails(TransactionValidationError.accountArchived),
      );
      expect(await txCount(), 0);
    });

    test('income/expense need a category', () async {
      await expectLater(
        dao.insert(
          userId: userId,
          accountId: a,
          type: TransactionType.expense,
          amountPaise: 100,
          occurredAt: now,
        ),
        fails(TransactionValidationError.categoryRequired),
      );
      await expectLater(
        dao.insert(
          userId: userId,
          accountId: a,
          type: TransactionType.income,
          amountPaise: 100,
          occurredAt: now,
        ),
        fails(TransactionValidationError.categoryRequired),
      );
    });

    test('category must exist, belong to the user, be active and match the type', () async {
      // Unknown.
      await expectLater(
        tryInsert(categoryId: 'nope'),
        fails(TransactionValidationError.categoryInvalid),
      );
      // Wrong kind, both ways.
      await expectLater(
        tryInsert(categoryId: salary),
        fails(TransactionValidationError.categoryInvalid),
      );
      await expectLater(
        tryInsert(type: TransactionType.income, categoryId: food),
        fails(TransactionValidationError.categoryInvalid),
      );
      // Another user's category.
      await seedDefaultCategories(db, 'other-user');
      await expectLater(
        tryInsert(categoryId: await cat('exp_food', user: 'other-user')),
        fails(TransactionValidationError.categoryInvalid),
      );
      // Archived.
      await (db.update(db.categories)..where((t) => t.id.equals(food))).write(
        const CategoriesCompanion(isArchived: Value(true)),
      );
      await expectLater(
        tryInsert(categoryId: food),
        fails(TransactionValidationError.categoryInvalid),
      );
      expect(await txCount(), 0);
    });

    test('a system category without a source is rejected', () async {
      final sys = await cat('sys_loan_given');
      await expectLater(
        tryInsert(categoryId: sys),
        fails(TransactionValidationError.categoryInvalid),
      );
      await expectLater(
        tryInsert(type: TransactionType.income, categoryId: sys),
        fails(TransactionValidationError.categoryInvalid),
      );
    });

    test('a transfer cannot have a category', () async {
      await expectLater(
        tryInsert(
          type: TransactionType.transfer,
          toAccountId: b,
          categoryId: food,
        ),
        fails(TransactionValidationError.categoryNotAllowed),
      );
    });

    test('note: trimmed, empty becomes null, 100 ok, 101 rejected', () async {
      final id1 = await tryInsert(note: '  lunch  ');
      expect((await dao.getById(id1))!.note, 'lunch');

      final id2 = await tryInsert(note: '   ');
      expect((await dao.getById(id2))!.note, isNull);
      final id3 = await tryInsert(note: '');
      expect((await dao.getById(id3))!.note, isNull);
      final id4 = await tryInsert();
      expect((await dao.getById(id4))!.note, isNull);

      final id5 = await tryInsert(note: 'a' * 100);
      expect((await dao.getById(id5))!.note, 'a' * 100);
      // Length is counted after trimming.
      final id6 = await tryInsert(note: '  ${'b' * 100}  ');
      expect((await dao.getById(id6))!.note, 'b' * 100);

      await expectLater(
        tryInsert(note: 'c' * 101),
        fails(TransactionValidationError.noteTooLong),
      );
      // Code points, not UTF-16 units.
      final id7 = await tryInsert(note: '\u{1F600}' * 100);
      expect((await dao.getById(id7))!.note, '\u{1F600}' * 100);
      await expectLater(
        tryInsert(note: '\u{1F600}' * 101),
        fails(TransactionValidationError.noteTooLong),
      );
      expect(await txCount(), 7);
    });

    test('future dates are rejected using the injected clock', () async {
      // Until the end of today (local time) is fine.
      await tryInsert(at: DateTime(2026, 10, 17, 23, 59, 59));
      await tryInsert(at: now);
      await tryInsert(at: DateTime(2020, 1, 1));

      await expectLater(
        tryInsert(at: DateTime(2026, 10, 18)),
        fails(TransactionValidationError.futureDate),
      );
      await expectLater(
        tryInsert(at: DateTime(2026, 10, 18, 0, 0, 1)),
        fails(TransactionValidationError.futureDate),
      );
      await expectLater(
        tryInsert(at: DateTime(2027, 1, 1)),
        fails(TransactionValidationError.futureDate),
      );
      expect(await txCount(), 3);
    });

    test('source_type and source_id are both set or both null', () async {
      final sys = await cat('sys_loan_given');
      await expectLater(
        tryInsert(categoryId: sys, source: TransactionSource.loan),
        fails(TransactionValidationError.sourceIncomplete),
      );
      await expectLater(
        tryInsert(categoryId: sys, sourceId: 'loan-1'),
        fails(TransactionValidationError.sourceIncomplete),
      );
      await expectLater(
        tryInsert(
          categoryId: sys,
          source: TransactionSource.loan,
          sourceId: '  ',
        ),
        fails(TransactionValidationError.sourceIncomplete),
      );
      // A transfer cannot carry a source (reported the same way).
      await expectLater(
        tryInsert(
          type: TransactionType.transfer,
          toAccountId: b,
          source: TransactionSource.investment,
          sourceId: 'inv-1',
        ),
        fails(TransactionValidationError.sourceIncomplete),
      );
      expect(await txCount(), 0);
    });

    test('with a source the category must be a system category', () async {
      await expectLater(
        tryInsert(
          categoryId: food,
          source: TransactionSource.loan,
          sourceId: 'loan-1',
        ),
        fails(TransactionValidationError.categoryInvalid),
      );
      await expectLater(
        dao.insert(
          userId: userId,
          accountId: a,
          type: TransactionType.expense,
          amountPaise: 100,
          occurredAt: now,
          source: TransactionSource.loan,
          sourceId: 'loan-1',
        ),
        fails(TransactionValidationError.categoryRequired),
      );

      final id = await tryInsert(
        categoryId: await cat('sys_loan_given'),
        source: TransactionSource.loan,
        sourceId: 'loan-1',
      );
      final row = (await dao.getById(id))!;
      expect(row.sourceType, TransactionSource.loan);
      expect(row.sourceId, 'loan-1');
    });

    test('rows move balances whether or not they have a source', () async {
      await tryInsert(
        amount: 4000,
        categoryId: await cat('sys_investment_buy'),
        source: TransactionSource.investment,
        sourceId: 'inv-1',
      );
      expect((await balances())[a], 96000);
    });
  });

  group('linked rows (source set)', () {
    late String a;
    late String linked;

    setUp(() async {
      a = await acct('Bank', paise: 100000);
      linked = await dao.insert(
        userId: userId,
        accountId: a,
        type: TransactionType.expense,
        amountPaise: 10000,
        categoryId: await cat('sys_loan_given'),
        occurredAt: now,
        source: TransactionSource.loan,
        sourceId: 'loan-1',
      );
    });

    test('cannot be updated or deleted normally', () async {
      await expectLater(
        dao.update(
          linked,
          accountId: a,
          type: TransactionType.expense,
          amountPaise: 20000,
          categoryId: await cat('sys_loan_given'),
          occurredAt: now,
        ),
        fails(TransactionValidationError.linkedToSource),
      );
      await expectLater(
        dao.delete(linked),
        fails(TransactionValidationError.linkedToSource),
      );
      expect((await dao.getById(linked))!.amount, 10000);
      expect((await balances())[a], 90000);
    });

    test('can be updated and deleted with bySource: true', () async {
      await dao.update(
        linked,
        accountId: a,
        type: TransactionType.expense,
        amountPaise: 25000,
        categoryId: await cat('sys_loan_given'),
        occurredAt: now,
        bySource: true,
      );
      final row = (await dao.getById(linked))!;
      expect(row.amount, 25000);
      // The source link itself can't be changed.
      expect(row.sourceType, TransactionSource.loan);
      expect(row.sourceId, 'loan-1');
      expect((await balances())[a], 75000);

      await dao.delete(linked, bySource: true);
      expect(await dao.getById(linked), isNull);
      expect((await balances())[a], 100000);
    });

    test('bySource skips ONLY the link check, not the other rules', () async {
      await expectLater(
        dao.update(
          linked,
          accountId: a,
          type: TransactionType.expense,
          amountPaise: 0,
          categoryId: await cat('sys_loan_given'),
          occurredAt: now,
          bySource: true,
        ),
        fails(TransactionValidationError.invalidAmount),
      );
      await expectLater(
        dao.update(
          linked,
          accountId: a,
          type: TransactionType.expense,
          amountPaise: 100,
          categoryId: await cat('exp_food'),
          occurredAt: now,
          bySource: true,
        ),
        fails(TransactionValidationError.categoryInvalid),
      );
    });
  });

  group('balanceOutOfRange', () {
    test('an expense past -maxPaise is rejected and nothing is written', () async {
      final a = await acct('Deep', paise: -Money.maxPaise + 100);

      await expense(a, 100); // exactly -maxPaise: allowed
      expect((await balances())[a], -Money.maxPaise);

      await expectLater(
        expense(a, 1),
        fails(TransactionValidationError.balanceOutOfRange),
      );
      expect(await txCount(), 1);
      expect((await balances())[a], -Money.maxPaise);
    });

    test('an income past +maxPaise is rejected', () async {
      final a = await acct('Full');
      await income(a, Money.maxPaise); // exactly +maxPaise: allowed
      await expectLater(
        income(a, 1),
        fails(TransactionValidationError.balanceOutOfRange),
      );
      expect(await txCount(), 1);
      expect((await balances())[a], Money.maxPaise);
    });

    test('a transfer that overfills the destination writes nothing', () async {
      final from = await acct('From', paise: 1000);
      final to = await acct('To', paise: Money.maxPaise);

      await expectLater(
        transfer(from, to, 1),
        fails(TransactionValidationError.balanceOutOfRange),
      );
      expect(await txCount(), 0);
      expect(await balances(), {from: 1000, to: Money.maxPaise});
    });

    test('an update past the limit is rejected and the row is unchanged', () async {
      final a = await acct('Near', paise: Money.maxPaise - 5);
      final id = await income(a, 5); // exactly +maxPaise

      await expectLater(
        dao.update(
          id,
          accountId: a,
          type: TransactionType.income,
          amountPaise: 6,
          categoryId: await cat('inc_salary'),
          occurredAt: now,
        ),
        fails(TransactionValidationError.balanceOutOfRange),
      );
      expect((await dao.getById(id))!.amount, 5);
      expect((await balances())[a], Money.maxPaise);
    });

    test('a delete that would leave the range is rejected', () async {
      final a = await acct('Edge', paise: -Money.maxPaise);
      final inc = await income(a, Money.maxPaise); // balance 0
      await expense(a, Money.maxPaise); // balance -maxPaise

      await expectLater(
        dao.delete(inc),
        fails(TransactionValidationError.balanceOutOfRange),
      );
      expect(await txCount(), 2);
      expect((await balances())[a], -Money.maxPaise);
    });
  });

  group('rows and schema', () {
    test('type and source are stored by name', () async {
      final a = await acct('Bank', paise: 100000);
      await expense(a, 100);
      await dao.insert(
        userId: userId,
        accountId: a,
        type: TransactionType.expense,
        amountPaise: 100,
        categoryId: await cat('sys_investment_sell'),
        occurredAt: now,
        source: TransactionSource.investment,
        sourceId: 'inv-1',
      );

      final rows = await db
          .customSelect(
            'SELECT type, source_type FROM transactions ORDER BY source_type',
          )
          .get();
      expect(rows.map((r) => r.read<String>('type')).toSet(), {'expense'});
      expect(rows.map((r) => r.readNullable<String>('source_type')), [
        null,
        'investment',
      ]);
    });

    test('getById returns every field', () async {
      final a = await acct('Bank', paise: 100000);
      final b = await acct('Cash', type: AccountType.cash);
      final at = DateTime(2026, 10, 3, 18, 45, 30);
      final id = await dao.insert(
        userId: userId,
        accountId: a,
        toAccountId: b,
        type: TransactionType.transfer,
        amountPaise: 12345,
        note: 'rent share',
        occurredAt: at,
      );

      final row = (await dao.getById(id))!;
      expect(row.userId, userId);
      expect(row.accountId, a);
      expect(row.toAccountId, b);
      expect(row.categoryId, isNull);
      expect(row.amount, 12345);
      expect(row.type, TransactionType.transfer);
      expect(row.note, 'rent share');
      expect(row.occurredAt.isAtSameMomentAs(at), isTrue);
      expect(row.sourceType, isNull);
      expect(row.sourceId, isNull);
    });

    test('table and both indexes exist; transactions is in allTables', () async {
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE tbl_name = 'transactions'",
          )
          .get();
      final names = rows.map((r) => r.read<String>('name')).toSet();
      expect(
        names,
        containsAll([
          'transactions',
          'transactions_user_date_idx',
          'transactions_account_idx',
        ]),
      );
      // The data export iterates allTables, so it picks the new table up.
      expect(
        db.allTables.map((t) => t.actualTableName),
        contains('transactions'),
      );
    });
  });

  group('source guard', () {
    test('new money files use no floating point', () {
      for (final path in [
        'lib/features/finance/data/transactions_dao.dart',
        'lib/features/finance/data/transactions_table.dart',
        'lib/features/finance/data/balance_queries.dart',
        'lib/features/finance/data/account_balance.dart',
      ]) {
        final code = File(path)
            .readAsStringSync()
            .split('\n')
            .where((l) => !l.trim().startsWith('//'))
            .join('\n');
        expect(RegExp(r'\bdouble\b').hasMatch(code), isFalse, reason: path);
        expect(RegExp(r'\bnum\b').hasMatch(code), isFalse, reason: path);
        expect(code.contains('.toDouble'), isFalse, reason: path);
        expect(code.contains('.round('), isFalse, reason: path);
        expect(code.contains('toStringAsFixed'), isFalse, reason: path);
      }
    });
  });
}
