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

/// Task 4b-2c: a row on an ARCHIVED account can be deleted. (A delete that
/// would leave the balance range is already covered in
/// transactions_dao_test.dart: "a delete that would leave the range is
/// rejected".)
void main() {
  late AppDatabase db;
  late String userId;
  late TransactionsDao dao;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await ensureBaselineData(db);
    userId = await ensureLocalUser(db);
    dao = TransactionsDao(db, clock: () => DateTime(2026, 10, 17, 12));
  });

  tearDown(() async {
    await db.close();
  });

  test('a row on an archived account can be deleted', () async {
    final accounts = AccountsDao(db);
    final bank = await accounts.insert(
      userId: userId,
      name: 'Old bank',
      type: AccountType.bank,
      startingBalancePaise: 100000,
    );
    final cash = await accounts.insert(
      userId: userId,
      name: 'Cash',
      type: AccountType.cash,
      startingBalancePaise: 0,
    );
    final food = (await CategoriesDao(db).getBySeedKey(userId, 'exp_food'))!.id;
    final expense = await dao.insert(
      userId: userId,
      accountId: bank,
      type: TransactionType.expense,
      amountPaise: 30000,
      categoryId: food,
      occurredAt: DateTime(2026, 10, 17, 9),
    );
    final transfer = await dao.insert(
      userId: userId,
      accountId: bank,
      toAccountId: cash,
      type: TransactionType.transfer,
      amountPaise: 20000,
      occurredAt: DateTime(2026, 10, 17, 10),
    );
    await (db.update(db.accounts)..where((a) => a.id.equals(bank))).write(
      const AccountsCompanion(isArchived: Value(true)),
    );

    await dao.delete(expense);
    await dao.delete(transfer);

    expect(await db.select(db.transactions).get(), isEmpty);
    final balances = {
      for (final a in await accounts.watchAccountsWithBalance(userId).first)
        a.account.id: a.balancePaise,
    };
    expect(balances[bank], 100000);
    expect(balances[cash], 0);
  });
}
