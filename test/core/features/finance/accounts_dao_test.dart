import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/core/utils/money.dart';
import 'package:vesper/features/finance/data/account_balance.dart';
import 'package:vesper/features/finance/data/accounts_dao.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';

Matcher invalidName(AccountValidationError expected) => throwsA(
  isA<AccountValidationException>().having(
    (e) => e.error,
    'error',
    expected,
  ),
);

void main() {
  late AppDatabase db;
  late AccountsDao dao;
  const userId = 'user-1';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = AccountsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> add(
    String name, {
    int paise = 0,
    AccountType type = AccountType.bank,
    String user = userId,
  }) => dao.insert(
    userId: user,
    name: name,
    type: type,
    startingBalancePaise: paise,
  );

  Future<void> setTimes(String id, DateTime created) =>
      (db.update(db.accounts)..where((t) => t.id.equals(id))).write(
        AccountsCompanion(
          createdAt: Value(created),
          updatedAt: Value(created),
        ),
      );

  group('insert', () {
    test('stores a trimmed name and sensible defaults', () async {
      final id = await add(
        '  Cash  ',
        paise: 12345,
        type: AccountType.cash,
      );

      final row = (await dao.getById(id))!;
      expect(row.name, 'Cash');
      expect(row.userId, userId);
      expect(row.type, AccountType.cash);
      expect(row.currency, 'INR');
      expect(row.startingBalance, 12345);
      expect(row.isArchived, isFalse);
    });

    test('type is stored by name', () async {
      await add('Visa', type: AccountType.creditCard);
      final rows = await db.customSelect('SELECT type FROM accounts').get();
      expect(rows.single.read<String>('type'), 'creditCard');
    });

    test('rejects empty and whitespace-only names', () async {
      await expectLater(add(''), invalidName(AccountValidationError.emptyName));
      await expectLater(
        add('   \t '),
        invalidName(AccountValidationError.emptyName),
      );
      expect(await dao.getAll(userId), isEmpty);
    });

    test('40 characters is allowed, 41 is rejected', () async {
      await add('a' * 40);
      await expectLater(
        add('b' * 41),
        invalidName(AccountValidationError.nameTooLong),
      );
      // Length is counted after trimming.
      await add('  ${'c' * 40}  ');
      expect(await dao.getAll(userId), hasLength(2));
    });

    test('length counts characters, not UTF-16 units', () async {
      await add('\u{1F600}' * 40); // 40 emoji = 80 UTF-16 units
      await expectLater(
        add('\u{1F601}' * 41),
        invalidName(AccountValidationError.nameTooLong),
      );
    });

    test('duplicate name for the same user is rejected, ignoring case', () async {
      await add('Cash');
      for (final dup in ['Cash', 'cash', 'CASH', '  cAsH  ']) {
        await expectLater(
          add(dup),
          invalidName(AccountValidationError.duplicateName),
        );
      }
      await add('\u00C9lan');
      await expectLater(
        add('\u00E9LAN'),
        invalidName(AccountValidationError.duplicateName),
      );
      expect(await dao.getAll(userId), hasLength(2));
    });

    test('another user may reuse a name', () async {
      await add('Cash');
      await add('Cash', user: 'user-2');
      expect(await dao.getAll(userId), hasLength(1));
      expect(await dao.getAll('user-2'), hasLength(1));
    });

    test('negative starting balance is allowed (credit card)', () async {
      final id = await add(
        'Visa',
        paise: -4500000,
        type: AccountType.creditCard,
      );
      expect((await dao.getById(id))!.startingBalance, -4500000);
    });

    test('|starting balance| above Money.maxPaise is rejected', () async {
      await expectLater(
        add('Too big', paise: Money.maxPaise + 1),
        throwsArgumentError,
      );
      await expectLater(
        add('Too small', paise: -Money.maxPaise - 1),
        throwsArgumentError,
      );
      expect(await dao.getAll(userId), isEmpty);

      // The limits themselves are fine.
      await add('Max', paise: Money.maxPaise);
      await add('Min', paise: -Money.maxPaise);
      expect(await dao.getAll(userId), hasLength(2));
    });
  });

  group('update', () {
    test('changes fields, trims, and sets updated_at but not created_at', () async {
      final id = await add('Cash', paise: 100, type: AccountType.cash);
      final past = DateTime.utc(2020, 1, 1);
      await setTimes(id, past);

      await dao.update(
        id,
        name: '  Wallet  ',
        type: AccountType.wallet,
        startingBalancePaise: 250,
      );

      final row = (await dao.getById(id))!;
      expect(row.name, 'Wallet');
      expect(row.type, AccountType.wallet);
      expect(row.startingBalance, 250);
      expect(row.createdAt.isAtSameMomentAs(past), isTrue);
      expect(row.updatedAt.isAfter(past), isTrue);
    });

    test('null fields are left unchanged', () async {
      final id = await add('Cash', paise: 100, type: AccountType.cash);
      await dao.update(id, startingBalancePaise: 999);

      final row = (await dao.getById(id))!;
      expect(row.name, 'Cash');
      expect(row.type, AccountType.cash);
      expect(row.startingBalance, 999);
    });

    test('renaming to its own current name is fine (any case)', () async {
      final id = await add('Cash');
      await dao.update(id, name: 'Cash');
      await dao.update(id, name: 'CASH');
      await dao.update(id, name: ' cash ');
      expect((await dao.getById(id))!.name, 'cash');
    });

    test('renaming to another account\'s name is rejected', () async {
      await add('Cash');
      final id = await add('Bank');

      await expectLater(
        dao.update(id, name: 'cash'),
        invalidName(AccountValidationError.duplicateName),
      );
      expect((await dao.getById(id))!.name, 'Bank');
    });

    test('same validation as insert; a failed update changes nothing', () async {
      final id = await add('Cash', paise: 100);

      await expectLater(
        dao.update(id, name: '  '),
        invalidName(AccountValidationError.emptyName),
      );
      await expectLater(
        dao.update(id, name: 'x' * 41),
        invalidName(AccountValidationError.nameTooLong),
      );
      await expectLater(
        dao.update(id, startingBalancePaise: Money.maxPaise + 1),
        throwsArgumentError,
      );
      await expectLater(
        dao.update(id, name: 'Fine', startingBalancePaise: -Money.maxPaise - 1),
        throwsArgumentError,
      );

      final row = (await dao.getById(id))!;
      expect(row.name, 'Cash');
      expect(row.startingBalance, 100);
    });

    test('negative balance is allowed on update', () async {
      final id = await add('Visa');
      await dao.update(id, startingBalancePaise: -1);
      expect((await dao.getById(id))!.startingBalance, -1);
    });

    test('unknown id is an ArgumentError', () async {
      await expectLater(dao.update('nope', name: 'X'), throwsArgumentError);
    });
  });

  group('reads and balances', () {
    test('getById returns null for an unknown id', () async {
      expect(await dao.getById('nope'), isNull);
    });

    test('getAll and the stream order by created_at, then name', () async {
      final a = await add('A late');
      final b = await add('B early');
      final z = await add('Zed same time');
      final al = await add('Alpha same time');
      await setTimes(b, DateTime.utc(2020, 1, 1));
      await setTimes(a, DateTime.utc(2020, 1, 2));
      await setTimes(z, DateTime.utc(2020, 1, 3));
      await setTimes(al, DateTime.utc(2020, 1, 3));
      await add('Other user', user: 'user-2');

      const expected = ['B early', 'A late', 'Alpha same time', 'Zed same time'];
      expect((await dao.getAll(userId)).map((r) => r.name), expected);

      final streamed = await dao.watchAccountsWithBalance(userId).first;
      expect(streamed.map((a) => a.account.name), expected);
    });

    test('balance equals starting_balance (no transactions yet)', () async {
      await add('Cash', paise: 12345);
      await add('Visa', paise: -500000, type: AccountType.creditCard);

      final list = await dao.watchAccountsWithBalance(userId).first;
      expect(list.map((a) => a.balancePaise), [12345, -500000]);
      expect(
        computeBalancePaise(startingBalancePaise: 777),
        777,
      );
    });

    test('total excludes archived accounts and credit cards; empty gives 0', () async {
      expect(totalBalancePaise(const []), 0);
      expect(creditCardDuesPaise(const []), 0);
      final empty = await dao.watchAccountsWithBalance(userId).first;
      expect(totalBalancePaise(empty), 0);
      expect(creditCardDuesPaise(empty), 0);

      final cash = await add('Cash', paise: 100000, type: AccountType.cash);
      await add('Bank', paise: 250050);
      await add('Visa', paise: -30000, type: AccountType.creditCard);
      await add('Old', paise: 999999999);
      await (db.update(db.accounts)..where((t) => t.name.equals('Old')))
          .write(const AccountsCompanion(isArchived: Value(true)));

      final list = await dao.watchAccountsWithBalance(userId).first;
      expect(list, hasLength(4)); // archived accounts are still listed
      expect(totalBalancePaise(list), 100000 + 250050); // no Visa, no Old
      expect(creditCardDuesPaise(list), 30000);

      await dao.update(cash, startingBalancePaise: 0);
      final after = await dao.watchAccountsWithBalance(userId).first;
      expect(totalBalancePaise(after), 250050);
      expect(creditCardDuesPaise(after), 30000);
    });

    test('only a credit card: total is 0 and dues are -balance', () async {
      await add('Visa', paise: -45000, type: AccountType.creditCard);

      final list = await dao.watchAccountsWithBalance(userId).first;
      expect(totalBalancePaise(list), 0);
      expect(creditCardDuesPaise(list), 45000);
    });

    test('an overpaid card (+5000) alone: dues 0, total 0', () async {
      await add('Visa', paise: 5000, type: AccountType.creditCard);

      final list = await dao.watchAccountsWithBalance(userId).first;
      expect(totalBalancePaise(list), 0);
      expect(creditCardDuesPaise(list), 0);
    });

    test('an overpaid card does not hide another card\'s debt', () async {
      await add('Visa', paise: 5000, type: AccountType.creditCard);
      await add('Amex', paise: -3000, type: AccountType.creditCard);

      final list = await dao.watchAccountsWithBalance(userId).first;
      expect(creditCardDuesPaise(list), 3000);
      expect(totalBalancePaise(list), 0);
    });

    test('a paid-up card (balance 0) adds nothing to dues', () async {
      await add('Visa', paise: 0, type: AccountType.creditCard);
      await add('Amex', paise: -700, type: AccountType.creditCard);

      expect(
        creditCardDuesPaise(await dao.watchAccountsWithBalance(userId).first),
        700,
      );
    });

    test('dues sum several cards; an archived card is ignored', () async {
      await add('Visa', paise: -1000, type: AccountType.creditCard);
      await add('Amex', paise: -2500, type: AccountType.creditCard);
      await add('Old card', paise: -777, type: AccountType.creditCard);
      await (db.update(db.accounts)..where((t) => t.name.equals('Old card')))
          .write(const AccountsCompanion(isArchived: Value(true)));

      final list = await dao.watchAccountsWithBalance(userId).first;
      expect(creditCardDuesPaise(list), 3500);
      expect(totalBalancePaise(list), 0);

      // Archived-only cards leave dues at 0.
      await (db.update(db.accounts)
            ..where((t) => t.type.equalsValue(AccountType.creditCard)))
          .write(const AccountsCompanion(isArchived: Value(true)));
      final archivedAll = await dao.watchAccountsWithBalance(userId).first;
      expect(creditCardDuesPaise(archivedAll), 0);
    });

    test('cash, bank, wallet and other all count in the total', () async {
      await add('Cash', paise: 1, type: AccountType.cash);
      await add('Bank', paise: 2, type: AccountType.bank);
      await add('Wallet', paise: 4, type: AccountType.wallet);
      await add('Misc', paise: 8, type: AccountType.other);
      await add('Visa', paise: -1000, type: AccountType.creditCard);

      final list = await dao.watchAccountsWithBalance(userId).first;
      expect(totalBalancePaise(list), 15);
      expect(creditCardDuesPaise(list), 1000);
    });

    test('Rs 1,00,000.00 and 1 paise sum exactly', () async {
      await add('Big', paise: 10000000);
      await add('Tiny', paise: 1);

      final total = totalBalancePaise(
        await dao.watchAccountsWithBalance(userId).first,
      );
      expect(total, 10000001);
      expect(Money.format(total), '\u20B91,00,000.01');
    });

    test('card dues of Rs 1,00,000.00 and 1 paise sum exactly', () async {
      await add('Card A', paise: -10000000, type: AccountType.creditCard);
      await add('Card B', paise: -1, type: AccountType.creditCard);
      await add('Bank', paise: 1);

      final list = await dao.watchAccountsWithBalance(userId).first;
      final dues = creditCardDuesPaise(list);
      expect(dues, 10000001);
      expect(Money.format(dues), '\u20B91,00,000.01');
      expect(totalBalancePaise(list), 1);
    });

    test('extreme balances cancel exactly', () async {
      await add('Max', paise: Money.maxPaise);
      await add('Min', paise: -Money.maxPaise);
      await add('One', paise: 1);

      expect(
        totalBalancePaise(await dao.watchAccountsWithBalance(userId).first),
        1,
      );
    });

    test('extreme card balances give exact dues', () async {
      await add('Card A', paise: -Money.maxPaise, type: AccountType.creditCard);
      await add('Card B', paise: Money.maxPaise, type: AccountType.creditCard);
      await add('Card C', paise: -1, type: AccountType.creditCard);

      // B's +maxPaise credit is ignored; A owes maxPaise and C owes 1.
      // The result deliberately exceeds Money.maxPaise: it proves the sum
      // is exact. Limiting what is displayed is the UI's job.
      expect(
        creditCardDuesPaise(await dao.watchAccountsWithBalance(userId).first),
        Money.maxPaise + 1,
      );
    });
  });

  group('schema and export', () {
    test('accounts and its index exist on a fresh database', () async {
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE tbl_name = 'accounts'",
          )
          .get();
      final names = rows.map((r) => r.read<String>('name')).toSet();
      expect(names, contains('accounts'));
      expect(names, contains('accounts_user_idx'));
    });

    test('accounts is in allTables, so data export picks it up', () {
      expect(
        db.allTables.map((t) => t.actualTableName),
        contains('accounts'),
      );
    });
  });

  group('source guard', () {
    test('AccountsDao offers no delete or archive', () {
      final source = File(
        'lib/features/finance/data/accounts_dao.dart',
      ).readAsStringSync();
      final code = source
          .split('\n')
          .where((l) => !l.trim().startsWith('//'))
          .join('\n');

      expect(code.contains('.delete('), isFalse);
      expect(code.toLowerCase().contains('archive'), isFalse);
      expect(
        RegExp(r'Future<[^>]*>\s+(delete|remove|archive)\w*\(').hasMatch(code),
        isFalse,
      );
    });

    test('money code uses no floating point', () {
      for (final path in [
        'lib/features/finance/data/accounts_dao.dart',
        'lib/features/finance/data/account_balance.dart',
        'lib/features/finance/data/accounts_table.dart',
      ]) {
        final code = File(path)
            .readAsStringSync()
            .split('\n')
            .where((l) => !l.trim().startsWith('//'))
            .join('\n');
        expect(RegExp(r'\bdouble\b').hasMatch(code), isFalse, reason: path);
        expect(RegExp(r'\bnum\b').hasMatch(code), isFalse, reason: path);
        expect(code.contains('.toDouble'), isFalse, reason: path);
      }
    });
  });
}