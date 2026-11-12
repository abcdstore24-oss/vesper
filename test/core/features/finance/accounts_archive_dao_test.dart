import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/core/db/db_bootstrap.dart';
import 'package:vesper/features/finance/data/account_balance.dart';
import 'package:vesper/features/finance/data/accounts_dao.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/data/categories_dao.dart';
import 'package:vesper/features/finance/data/transactions_dao.dart';
import 'package:vesper/features/finance/data/transactions_table.dart';

/// Task 4d: hasTransactions / archive / restore / delete and their rules.
Matcher _fails(AccountValidationError expected) => throwsA(
  isA<AccountValidationException>().having((e) => e.error, 'error', expected),
);

void main() {
  late AppDatabase db;
  late String userId;
  late AccountsDao dao;
  late TransactionsDao txs;
  late String foodId;
  late String salaryId;

  final at = DateTime(2026, 10, 17, 12);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await ensureBaselineData(db);
    userId = await ensureLocalUser(db);
    dao = AccountsDao(db);
    txs = TransactionsDao(db, clock: () => DateTime(2026, 10, 18, 12));
    final categories = CategoriesDao(db);
    foodId = (await categories.getBySeedKey(userId, 'exp_food'))!.id;
    salaryId = (await categories.getBySeedKey(userId, 'inc_salary'))!.id;
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> account(
    String name, {
    AccountType type = AccountType.bank,
    int start = 0,
  }) => dao.insert(
    userId: userId,
    name: name,
    type: type,
    startingBalancePaise: start,
  );

  Future<String> expense(String accountId, int paise) => txs.insert(
    userId: userId,
    accountId: accountId,
    type: TransactionType.expense,
    amountPaise: paise,
    categoryId: foodId,
    occurredAt: at,
  );

  Future<String> income(String accountId, int paise) => txs.insert(
    userId: userId,
    accountId: accountId,
    type: TransactionType.income,
    amountPaise: paise,
    categoryId: salaryId,
    occurredAt: at,
  );

  Future<String> transfer(String from, String to, int paise) => txs.insert(
    userId: userId,
    accountId: from,
    toAccountId: to,
    type: TransactionType.transfer,
    amountPaise: paise,
    occurredAt: at,
  );

  Future<AccountRow> row(String id) async => (await dao.getById(id))!;

  Future<int> balanceOf(String id) async =>
      (await dao.watchAccountsWithBalance(userId).first)
          .firstWhere((a) => a.account.id == id)
          .balancePaise;

  group('hasTransactions', () {
    test('false for an account nothing refers to', () async {
      final id = await account('Unused');
      expect(await dao.hasTransactions(id), isFalse);
    });

    test('true as the From account (income, expense, transfer)', () async {
      final a = await account('A', start: 100000);
      final b = await account('B');
      final c = await account('C', start: 100000);
      final d = await account('D', start: 100000);
      await income(a, 100);
      await expense(c, 100);
      await transfer(d, b, 100);

      expect(await dao.hasTransactions(a), isTrue);
      expect(await dao.hasTransactions(c), isTrue);
      expect(await dao.hasTransactions(d), isTrue);
    });

    test('true as the To account of a transfer', () async {
      final from = await account('From', start: 100000);
      final to = await account('To');
      await transfer(from, to, 500);

      expect(await dao.hasTransactions(to), isTrue);
    });

    test('an unrelated account stays false', () async {
      final a = await account('A', start: 100000);
      final b = await account('B');
      final other = await account('Other');
      await transfer(a, b, 500);

      expect(await dao.hasTransactions(other), isFalse);
    });
  });

  group('archive', () {
    test('allowed at a zero balance with no transactions', () async {
      final id = await account('Spare');
      await dao.archive(id);
      expect((await row(id)).isArchived, isTrue);
    });

    test('allowed when income, expense and a transfer net to zero', () async {
      final id = await account('Net');
      final other = await account('Other');
      await income(id, 10000);
      await expense(id, 2500);
      await transfer(id, other, 7500);
      expect(await balanceOf(id), 0);

      await dao.archive(id);
      expect((await row(id)).isArchived, isTrue);
    });

    test('allowed for a credit card at zero', () async {
      final card = await account('Visa', type: AccountType.creditCard);
      await dao.archive(card);
      expect((await row(card)).isArchived, isTrue);

      // Dues paid off exactly: -5000 start, 5000 transferred in.
      final owing = await account(
        'Amex',
        type: AccountType.creditCard,
        start: -5000,
      );
      final bank = await account('Bank', start: 100000);
      await transfer(bank, owing, 5000);
      expect(await balanceOf(owing), 0);
      await dao.archive(owing);
      expect((await row(owing)).isArchived, isTrue);
    });

    test('refused for a positive balance', () async {
      final id = await account('Rich', start: 100);
      await expectLater(
        dao.archive(id),
        _fails(AccountValidationError.balanceNotZero),
      );
      expect((await row(id)).isArchived, isFalse);
    });

    test('refused for a negative balance', () async {
      final id = await account('Overdrawn', start: -100);
      await expectLater(
        dao.archive(id),
        _fails(AccountValidationError.balanceNotZero),
      );
      expect((await row(id)).isArchived, isFalse);
    });

    test('refused for a card with dues, and a card with credit', () async {
      final dues = await account(
        'Dues',
        type: AccountType.creditCard,
        start: -5000,
      );
      final credit = await account(
        'Credit',
        type: AccountType.creditCard,
        start: 5000,
      );
      await expectLater(
        dao.archive(dues),
        _fails(AccountValidationError.balanceNotZero),
      );
      await expectLater(
        dao.archive(credit),
        _fails(AccountValidationError.balanceNotZero),
      );
    });

    test(
      'uses the balance WITH transactions, not the starting balance',
      () async {
        final id = await account('Starts rich', start: 5000);
        await expense(id, 5000);
        expect(await balanceOf(id), 0);
        await dao.archive(id);
        expect((await row(id)).isArchived, isTrue);

        final starts0 = await account('Starts zero');
        await income(starts0, 100);
        await expectLater(
          dao.archive(starts0),
          _fails(AccountValidationError.balanceNotZero),
        );
      },
    );

    test('is idempotent and does not touch an archived row again', () async {
      final id = await account('Spare');
      await dao.archive(id);
      final old = DateTime(2020, 1, 1, 12);
      await (db.update(db.accounts)..where((a) => a.id.equals(id))).write(
        AccountsCompanion(updatedAt: Value(old)),
      );

      await dao.archive(id); // no error, nothing written
      expect((await row(id)).isArchived, isTrue);
      expect((await row(id)).updatedAt, old);
    });

    test('sets updated_at', () async {
      final id = await account('Spare');
      final old = DateTime(2020, 1, 1, 12);
      await (db.update(db.accounts)..where((a) => a.id.equals(id))).write(
        AccountsCompanion(updatedAt: Value(old)),
      );
      await dao.archive(id);
      expect((await row(id)).updatedAt.isAfter(old), isTrue);
    });

    test(
      'Total Balance and card dues are unchanged by archiving a zero account',
      () async {
        final bank = await account('Bank', start: 123400);
        await account('Visa', type: AccountType.creditCard, start: -5000);
        final zero = await account('Zero');
        final before = await dao.watchAccountsWithBalance(userId).first;
        final totalBefore = totalBalancePaise(before);
        final duesBefore = creditCardDuesPaise(before);
        expect(totalBefore, 123400);
        expect(duesBefore, 5000);

        await dao.archive(zero);

        final after = await dao.watchAccountsWithBalance(userId).first;
        expect(totalBalancePaise(after), totalBefore);
        expect(creditCardDuesPaise(after), duesBefore);
        expect(after.map((a) => a.account.id), contains(bank));
      },
    );

    test('nothing is deleted: the row and its transactions remain', () async {
      final id = await account('Zero');
      final inId = await income(id, 1000);
      final outId = await expense(id, 1000);

      await dao.archive(id);

      expect(await dao.getById(id), isNotNull);
      expect(await txs.getById(inId), isNotNull);
      expect(await txs.getById(outId), isNotNull);
      expect(await dao.hasTransactions(id), isTrue);
    });

    test('an unknown id is notFound', () async {
      await expectLater(
        dao.archive('no-such-id'),
        _fails(AccountValidationError.notFound),
      );
    });
  });

  group('restore', () {
    test('clears is_archived and sets updated_at', () async {
      final id = await account('Spare');
      await dao.archive(id);
      final old = DateTime(2020, 1, 1, 12);
      await (db.update(db.accounts)..where((a) => a.id.equals(id))).write(
        AccountsCompanion(updatedAt: Value(old)),
      );

      await dao.restore(id);

      expect((await row(id)).isArchived, isFalse);
      expect((await row(id)).updatedAt.isAfter(old), isTrue);
    });

    test(
      'names of archived accounts stay reserved, so a restore never clashes',
      () async {
        final id = await account('Spare');
        await dao.archive(id);

        await expectLater(
          account('spare'),
          _fails(AccountValidationError.duplicateName),
        );
        await expectLater(
          dao.update(await account('Other'), name: 'SPARE'),
          _fails(AccountValidationError.duplicateName),
        );

        await dao.restore(id);
        expect((await row(id)).name, 'Spare');
      },
    );

    test('an unknown id is notFound', () async {
      await expectLater(
        dao.restore('no-such-id'),
        _fails(AccountValidationError.notFound),
      );
    });
  });

  group('delete', () {
    test('removes an unused account and only that row', () async {
      final keep = await account('Keep', start: 5000);
      final other = await account('Other');
      final gone = await account('Gone');
      await income(keep, 100);

      await dao.delete(gone);

      expect(await dao.getById(gone), isNull);
      expect(await dao.getById(keep), isNotNull);
      expect(await dao.getById(other), isNotNull);
      expect(await db.select(db.transactions).get(), hasLength(1));
      expect(await dao.getAll(userId), hasLength(2));
    });

    test('an archived unused account can be deleted too', () async {
      final id = await account('Spare');
      await dao.archive(id);
      await dao.delete(id);
      expect(await dao.getById(id), isNull);
    });

    test('refused when a transaction refers to it as From', () async {
      final id = await account('Used', start: 5000);
      await expense(id, 100);

      await expectLater(
        dao.delete(id),
        _fails(AccountValidationError.hasTransactions),
      );
      expect(await dao.getById(id), isNotNull);
      expect(await db.select(db.transactions).get(), hasLength(1));
    });

    test('refused when a transfer refers to it as To', () async {
      final from = await account('From', start: 5000);
      final to = await account('To');
      await transfer(from, to, 100);

      await expectLater(
        dao.delete(to),
        _fails(AccountValidationError.hasTransactions),
      );
      expect(await dao.getById(to), isNotNull);
      expect(await db.select(db.transactions).get(), hasLength(1));
    });

    test('an unknown id is notFound', () async {
      await expectLater(
        dao.delete('no-such-id'),
        _fails(AccountValidationError.notFound),
      );
    });

    test('a deleted name can be used again', () async {
      final id = await account('Spare');
      await dao.delete(id);
      await account('Spare');
    });
  });

  group('update keeps its ArgumentError behaviour', () {
    test('an unknown id still throws ArgumentError', () async {
      await expectLater(
        dao.update('no-such-id', name: 'X'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
