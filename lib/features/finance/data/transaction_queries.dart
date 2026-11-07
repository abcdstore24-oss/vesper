import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'transactions_table.dart';

/// A transaction together with the names the UI needs to describe it, so a
/// row can say what it was (not just "Bills 300").
class TransactionListItem {
  const TransactionListItem({
    required this.transaction,
    this.categoryName,
    this.categoryIcon,
    required this.accountName,
    this.toAccountName,
  });

  final TransactionRow transaction;

  /// Null for transfers (and if the category is missing).
  final String? categoryName;

  /// The category's Phosphor icon KEY (e.g. 'fork_knife'), or null.
  final String? categoryIcon;

  /// The account money leaves/enters (for a transfer, the FROM account).
  final String accountName;

  /// The destination account of a transfer; null otherwise.
  final String? toAccountName;
}

/// [userId]'s transactions with category and account names, newest first:
/// by occurred_at, then created_at, then rowid (all descending).
///
/// - [type]: only rows of that type (null = all). Filtered in SQL.
/// - [limit]: at most that many rows (null = no limit). The Finance home
///   passes 5; the full Transactions list passes null.
///
/// Timestamps are whole seconds, so rows made in the same second would tie;
/// the rowid tiebreak puts the most recently inserted one first.
///
/// The joins are LEFT joins and do not look at is_archived, so a row whose
/// category or account was archived (or is missing) still appears. Rows
/// created by loans/investments (a source) are included like any other.
///
/// The query reads from transactions, categories AND accounts, so `.watch()`
/// re-emits when any of them changes (for example a renamed account).
Selectable<TransactionListItem> selectRecentTransactions(
  AppDatabase db, {
  required String userId,
  TransactionType? type,
  int? limit,
}) {
  final variables = <Variable>[Variable.withString(userId)];
  final typeClause = type == null ? '' : '\n  AND t.type = ?';
  if (type != null) variables.add(Variable.withString(type.name));
  final limitClause = limit == null ? '' : '\nLIMIT ?';
  if (limit != null) variables.add(Variable.withInt(limit));

  return db
      .customSelect(
        '''
SELECT t.*,
       c.name AS category_name,
       c.icon AS category_icon,
       fa.name AS account_name,
       ta.name AS to_account_name
FROM transactions t
LEFT JOIN categories c ON c.id = t.category_id
LEFT JOIN accounts fa ON fa.id = t.account_id
LEFT JOIN accounts ta ON ta.id = t.to_account_id
WHERE t.user_id = ?$typeClause
ORDER BY t.occurred_at DESC, t.created_at DESC, t.rowid DESC$limitClause''',
        variables: variables,
        readsFrom: {db.transactions, db.categories, db.accounts},
      )
      .map(
        (row) => TransactionListItem(
          transaction: db.transactions.map(row.data),
          categoryName: row.readNullable<String>('category_name'),
          categoryIcon: row.readNullable<String>('category_icon'),
          accountName:
              row.readNullable<String>('account_name') ?? 'Unknown account',
          toAccountName: row.readNullable<String>('to_account_name'),
        ),
      );
}
