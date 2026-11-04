import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'categories_table.dart';

/// The categories of [kind] (income or expense) that [userId] used most
/// recently, newest use first, at most [limit]. Each category appears once.
///
/// - Only ordinary transactions count: rows with a source (loan/investment
///   payments) are ignored, and so are transfers and rows without a category.
/// - Only the matching kind: an expense list contains expense categories
///   only (a `system` category can never match).
/// - Archived categories are dropped (the join keeps only active ones).
/// - "Latest use" is MAX(occurred_at), then MAX(created_at), then MAX(rowid),
///   each descending, per category.
///
/// The query reads from transactions AND categories, so `.watch()` re-emits
/// when either changes. Kept out of CategoriesDao so that DAO stays free of
/// anything but plain reads and an insert.
Selectable<CategoryRow> selectRecentCategories(
  AppDatabase db, {
  required String userId,
  required CategoryKind kind,
  int limit = 5,
}) {
  assert(kind != CategoryKind.system, 'recent categories are income/expense');

  return db
      .customSelect(
        '''
SELECT c.*
FROM categories c
JOIN (
  SELECT category_id,
         MAX(occurred_at) AS last_occurred,
         MAX(created_at) AS last_created,
         MAX(rowid) AS last_rowid
  FROM transactions
  WHERE user_id = ? AND type = ? AND source_type IS NULL
        AND category_id IS NOT NULL
  GROUP BY category_id
) u ON u.category_id = c.id
WHERE c.user_id = ? AND c.is_archived = 0 AND c.kind = ?
ORDER BY u.last_occurred DESC, u.last_created DESC, u.last_rowid DESC
LIMIT ?''',
        variables: [
          Variable.withString(userId),
          // TransactionType.income/expense and CategoryKind.income/expense
          // share their stored names.
          Variable.withString(kind.name),
          Variable.withString(userId),
          Variable.withString(kind.name),
          Variable.withInt(limit),
        ],
        readsFrom: {db.transactions, db.categories},
      )
      .map((row) => db.categories.map(row.data));
}
