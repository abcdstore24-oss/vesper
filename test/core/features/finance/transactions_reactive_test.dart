import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/core/db/db_provider.dart';
import 'package:vesper/core/db/local_user_provider.dart';
import 'package:vesper/features/finance/data/account_balance.dart';
import 'package:vesper/features/finance/data/accounts_dao.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/data/categories_dao.dart';
import 'package:vesper/features/finance/data/categories_table.dart';
import 'package:vesper/features/finance/data/transactions_dao.dart';
import 'package:vesper/features/finance/data/transactions_table.dart';
import 'package:vesper/features/finance/presentation/providers/accounts_providers.dart';

import '../../../support/test_db.dart';

void main() {
  test(
    'REACTIVE: the same listener sees balances move after insert, update '
    'and delete (fresh database, no bootstrap, one container)',
    () async {
      final container = makeInMemoryContainer();
      final db = container.read(appDatabaseProvider);

      final emissions = <List<AccountWithBalance>>[];
      final errors = <Object>[];
      final subscription = container
          .listen<AsyncValue<List<AccountWithBalance>>>(
            accountsWithBalanceProvider,
            (previous, next) {
              if (next.hasValue) emissions.add(next.requireValue);
              if (next.hasError) errors.add(next.error!);
            },
            fireImmediately: true,
          );
      addTearDown(subscription.close);

      await pumpUntil(() => emissions.isNotEmpty);
      expect(emissions.last, isEmpty);

      // No bootstrap here, so add the one category this test needs by hand.
      final userId = await container.read(localUserIdProvider.future);
      await CategoriesDao(db).insert(
        CategoriesCompanion.insert(
          id: 'cat-food',
          userId: userId,
          name: 'Food',
          icon: 'fork_knife',
          color: 0xFFC97B84,
          kind: CategoryKind.expense,
        ),
      );

      final accounts = AccountsDao(db);
      final bank = await accounts.insert(
        userId: userId,
        name: 'Bank',
        type: AccountType.bank,
        startingBalancePaise: 100000,
      );
      final card = await accounts.insert(
        userId: userId,
        name: 'Visa',
        type: AccountType.creditCard,
        startingBalancePaise: -30000,
      );

      int balanceOf(String id) => emissions.last
          .firstWhere((a) => a.account.id == id)
          .balancePaise;

      await pumpUntil(() => emissions.last.length == 2);
      expect(balanceOf(bank), 100000);

      final transactions = TransactionsDao(db);

      // Insert: the balance moves in the SAME listener.
      final expenseId = await transactions.insert(
        userId: userId,
        accountId: bank,
        type: TransactionType.expense,
        amountPaise: 2500,
        categoryId: 'cat-food',
        occurredAt: DateTime.now(),
      );
      await pumpUntil(() => balanceOf(bank) == 97500);
      expect(container.read(totalBalanceProvider).value, 97500);

      // A transfer moves both accounts; dues shrink, the total drops.
      final transferId = await transactions.insert(
        userId: userId,
        accountId: bank,
        toAccountId: card,
        type: TransactionType.transfer,
        amountPaise: 10000,
        occurredAt: DateTime.now(),
      );
      await pumpUntil(() => balanceOf(card) == -20000);
      expect(balanceOf(bank), 87500);
      await pumpUntil(
        () => container.read(creditCardDuesProvider).value == 20000,
      );
      expect(container.read(totalBalanceProvider).value, 87500);

      // Update.
      await transactions.update(
        expenseId,
        accountId: bank,
        type: TransactionType.expense,
        amountPaise: 4000,
        categoryId: 'cat-food',
        occurredAt: DateTime.now(),
      );
      await pumpUntil(() => balanceOf(bank) == 86000);

      // Delete: balances return.
      await transactions.delete(transferId);
      await pumpUntil(() => balanceOf(card) == -30000);
      expect(balanceOf(bank), 96000);

      await transactions.delete(expenseId);
      await pumpUntil(() => balanceOf(bank) == 100000);
      await pumpUntil(
        () => container.read(creditCardDuesProvider).value == 30000,
      );

      expect(errors, isEmpty);
    },
  );
}
