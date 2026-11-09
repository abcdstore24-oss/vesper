import 'package:flutter/widgets.dart';

import '../data/transaction_queries.dart';
import 'widgets/locked_transaction_sheet.dart';
import 'widgets/transaction_form_sheet.dart';

/// What tapping a transaction row does, shared by Recent transactions and the
/// full Transactions list so the rule lives in one place:
/// no source -> the edit sheet; a source (loan/investment) -> the read-only
/// explanation.
Future<void> openTransaction(BuildContext context, TransactionListItem item) {
  if (item.transaction.sourceType != null) {
    return showLockedTransactionSheet(context, item);
  }
  return showTransactionFormSheet(context, existing: item);
}
