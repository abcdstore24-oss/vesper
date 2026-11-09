import 'package:drift/drift.dart' show Value;
import 'package:vesper/features/finance/data/transaction_queries.dart';
import 'package:vesper/features/finance/data/transactions_table.dart';

/// [item] as a row created by a loan or an investment (it has a source), for
/// tests of locked rows. Everything else is unchanged.
TransactionListItem withSource(
  TransactionListItem item,
  TransactionSource source, {
  String sourceId = 'source-1',
}) {
  return TransactionListItem(
    transaction: item.transaction.copyWith(
      sourceType: Value(source),
      sourceId: Value(sourceId),
    ),
    categoryName: item.categoryName,
    categoryIcon: item.categoryIcon,
    accountName: item.accountName,
    toAccountName: item.toAccountName,
  );
}
