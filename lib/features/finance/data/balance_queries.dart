import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'account_balance.dart';

// One row per account with its transaction sums, computed in SQL. Every
// amount is an integer, so SUM is exact. Two passes over the user's rows:
// the first half counts what each account itself recorded (income, expense,
// and the FROM side of transfers), the second half the TO side of transfers.
// SQLite's SUM raises an error on 64-bit overflow instead of wrapping; with
// each row <= Money.maxPaise (1e14) that needs more than 92,000 maximum-size
// rows on one account in one direction, which is not reachable in practice.
//
// The three "?" in the query are all the user id, in this order: the two
// halves below, then the outer WHERE.
const String _sumsSubquery = '''
SELECT acc_id,
       SUM(income) AS income,
       SUM(expense) AS expense,
       SUM(transfer_out) AS transfer_out,
       SUM(transfer_in) AS transfer_in
FROM (
  SELECT account_id AS acc_id,
         CASE WHEN type = 'income' THEN amount ELSE 0 END AS income,
         CASE WHEN type = 'expense' THEN amount ELSE 0 END AS expense,
         CASE WHEN type = 'transfer' THEN amount ELSE 0 END AS transfer_out,
         0 AS transfer_in
  FROM transactions
  WHERE user_id = ?
  UNION ALL
  SELECT to_account_id AS acc_id, 0, 0, 0, amount
  FROM transactions
  WHERE user_id = ? AND type = 'transfer' AND to_account_id IS NOT NULL
)
GROUP BY acc_id''';

/// [userId]'s accounts with their computed balances, oldest first, then by
/// name. When [accountIds] is given, only those accounts.
///
/// The balance formula lives in [computeBalancePaise]; this only fetches the
/// numbers. The query reads from `accounts` AND `transactions`, so
/// `.watch()` re-emits when either table changes.
///
/// Used by AccountsDao.watchAccountsWithBalance and by TransactionsDao's
/// balance-range check.
Selectable<AccountWithBalance> selectAccountsWithBalance(
  AppDatabase db, {
  required String userId,
  Iterable<String>? accountIds,
}) {
  final ids = accountIds?.toSet().toList();
  assert(ids == null || ids.isNotEmpty, 'accountIds must not be empty');
  final idFilter = ids == null
      ? ''
      : ' AND a.id IN (${List.filled(ids.length, '?').join(', ')})';

  final sql =
      '''
SELECT a.*,
       COALESCE(s.income, 0) AS sum_income,
       COALESCE(s.expense, 0) AS sum_expense,
       COALESCE(s.transfer_in, 0) AS sum_transfer_in,
       COALESCE(s.transfer_out, 0) AS sum_transfer_out
FROM accounts a
LEFT JOIN ($_sumsSubquery) s ON s.acc_id = a.id
WHERE a.user_id = ?$idFilter
ORDER BY a.created_at ASC, a.name ASC''';

  return db
      .customSelect(
        sql,
        variables: [
          Variable.withString(userId),
          Variable.withString(userId),
          Variable.withString(userId),
          if (ids != null) for (final id in ids) Variable.withString(id),
        ],
        readsFrom: {db.accounts, db.transactions},
      )
      .map(
        (row) => AccountWithBalance(
          account: db.accounts.map(row.data),
          balancePaise: computeBalancePaise(
            startingBalancePaise: row.read<int>('starting_balance'),
            incomePaise: row.read<int>('sum_income'),
            expensePaise: row.read<int>('sum_expense'),
            transfersInPaise: row.read<int>('sum_transfer_in'),
            transfersOutPaise: row.read<int>('sum_transfer_out'),
          ),
        ),
      );
}
