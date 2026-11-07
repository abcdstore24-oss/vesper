import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/db/db_provider.dart';
import 'package:vesper/core/db/local_user_provider.dart';
import 'package:vesper/features/finance/data/account_balance.dart';
import 'package:vesper/features/finance/data/accounts_dao.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/presentation/providers/accounts_providers.dart';

import '../../../support/test_db.dart';

void main() {
  group('accountsWithBalanceProvider', () {
    test('FIRST LAUNCH: an account added on a fresh install shows up in the '
        'same listener without recreating the container', () async {
      final container = makeInMemoryContainer();
      final db = container.read(appDatabaseProvider);

      // Fresh database and NO bootstrap: no user row, no categories.
      expect(await db.select(db.userProfile).get(), isEmpty);
      expect(await db.select(db.categories).get(), isEmpty);

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

      // 1. Starts empty.
      await pumpUntil(() => emissions.isNotEmpty);
      expect(emissions.last, isEmpty);

      // 2. First account, created with the id from localUserIdProvider.
      final userId = await container.read(localUserIdProvider.future);
      final dao = AccountsDao(db);
      await dao.insert(
        userId: userId,
        name: 'Cash',
        type: AccountType.cash,
        startingBalancePaise: 50000,
      );

      // The SAME listener must receive it (no restart, no new container).
      await pumpUntil(() => emissions.last.length == 1);
      expect(emissions.last.single.account.name, 'Cash');
      expect(emissions.last.single.balancePaise, 50000);
      expect(container.read(totalBalanceProvider).value, 50000);

      // 3. Second insert, same listener again.
      await dao.insert(
        userId: userId,
        name: 'Visa',
        type: AccountType.creditCard,
        startingBalancePaise: -12000,
      );
      await pumpUntil(() => emissions.last.length == 2);
      expect(emissions.last.map((a) => a.account.name), ['Cash', 'Visa']);
      expect(emissions.last.map((a) => a.balancePaise), [50000, -12000]);
      // The card is NOT in Total Balance; it shows up as card dues.
      await pumpUntil(
        () => container.read(creditCardDuesProvider).value == 12000,
      );
      expect(container.read(totalBalanceProvider).value, 50000);

      // 4. Updates flow through the same stream too.
      await dao.update(emissions.last.first.account.id, name: 'Pocket cash');
      await pumpUntil(
        () => emissions.last.any((a) => a.account.name == 'Pocket cash'),
      );

      expect(errors, isEmpty);
      expect(identical(container.read(appDatabaseProvider), db), isTrue);

      // Exactly one local user row was created, by the provider.
      expect(await db.select(db.userProfile).get(), hasLength(1));
    });

    test('a different user\'s accounts never appear', () async {
      final container = makeInMemoryContainer();
      final db = container.read(appDatabaseProvider);
      final dao = AccountsDao(db);
      await dao.insert(
        userId: 'someone-else',
        name: 'Not mine',
        type: AccountType.bank,
        startingBalancePaise: 1,
      );

      final list = await container.read(accountsWithBalanceProvider.future);
      expect(list, isEmpty);
    });
  });

  group('totalBalanceProvider', () {
    test('is 0 with no accounts and follows inserts', () async {
      final container = makeInMemoryContainer();
      final db = container.read(appDatabaseProvider);

      final subscription = container.listen<AsyncValue<int>>(
        totalBalanceProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await pumpUntil(() => container.read(totalBalanceProvider).hasValue);
      expect(container.read(totalBalanceProvider).value, 0);

      final userId = await container.read(localUserIdProvider.future);
      final dao = AccountsDao(db);
      await dao.insert(
        userId: userId,
        name: 'Big',
        type: AccountType.bank,
        startingBalancePaise: 10000000,
      );
      await dao.insert(
        userId: userId,
        name: 'Tiny',
        type: AccountType.wallet,
        startingBalancePaise: 1,
      );

      await pumpUntil(
        () => container.read(totalBalanceProvider).value == 10000001,
      );
    });
  });

  group('creditCardDuesProvider', () {
    test('is 0 with no cards and follows card inserts', () async {
      final container = makeInMemoryContainer();
      final db = container.read(appDatabaseProvider);

      final subscription = container.listen<AsyncValue<int>>(
        creditCardDuesProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await pumpUntil(() => container.read(creditCardDuesProvider).hasValue);
      expect(container.read(creditCardDuesProvider).value, 0);

      final userId = await container.read(localUserIdProvider.future);
      final dao = AccountsDao(db);
      await dao.insert(
        userId: userId,
        name: 'Bank',
        type: AccountType.bank,
        startingBalancePaise: 90000,
      );
      await dao.insert(
        userId: userId,
        name: 'Visa',
        type: AccountType.creditCard,
        startingBalancePaise: -10000000,
      );
      await dao.insert(
        userId: userId,
        name: 'Amex',
        type: AccountType.creditCard,
        startingBalancePaise: -1,
      );

      await pumpUntil(
        () => container.read(creditCardDuesProvider).value == 10000001,
      );
      expect(container.read(totalBalanceProvider).value, 90000);
    });
  });

  group('localUserIdProvider', () {
    test(
      'returns the same id on every read, with one user_profile row',
      () async {
        final container = makeInMemoryContainer();
        final db = container.read(appDatabaseProvider);

        final first = await container.read(localUserIdProvider.future);
        final second = await container.read(localUserIdProvider.future);
        expect(first, isNotEmpty);
        expect(second, first);
        expect(await db.select(db.userProfile).get(), hasLength(1));

        // Re-running the provider (as after a restart of just this provider)
        // finds the existing row; it never makes a second one.
        container.invalidate(localUserIdProvider);
        final third = await container.read(localUserIdProvider.future);
        expect(third, first);

        final rows = await db.select(db.userProfile).get();
        expect(rows, hasLength(1));
        expect(rows.single.userId, first);
      },
    );

    test('returns the id of an existing user_profile row', () async {
      final container = makeInMemoryContainer();
      final db = container.read(appDatabaseProvider);
      await db.customStatement(
        "INSERT INTO user_profile (id, user_id, created_at, updated_at) "
        "VALUES ('p1', 'existing-user', 1700000000, 1700000000)",
      );

      expect(await container.read(localUserIdProvider.future), 'existing-user');
      expect(await db.select(db.userProfile).get(), hasLength(1));
    });
  });
}
