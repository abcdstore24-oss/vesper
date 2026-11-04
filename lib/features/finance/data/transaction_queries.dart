import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

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

/// [userId]'s most recent [limit] transactions with category and account
/// names, newest first: by occurred_at, then created_at, then rowid.
///
/// Timestamps are whole seconds, so rows made in the same second would tie;
/// the rowid tiebreak puts the most recently inserted one first.
///
/// The query reads from transactions, categories AND accounts, so `.watch()`
/// re-emits when any of them changes (for example a renamed account).
Selectable<TransactionListItem> selectRecentTransactions(
  AppDatabase db, {
  required String userId,
  required int limit,
}) {
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
WHERE t.user_id = ?
ORDER BY t.occurred_at DESC, t.created_at DESC, t.rowid DESC
LIMIT ?''',
        variables: [Variable.withString(userId), Variable.withInt(limit)],
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
