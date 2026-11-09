import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../shared/widgets/amount_text.dart';
import '../../data/transaction_queries.dart';
import '../../data/transactions_table.dart';
import '../transaction_display.dart';

/// Opens the read-only explanation for a transaction created by a loan or an
/// investment (one with a source).
Future<void> showLockedTransactionSheet(
  BuildContext context,
  TransactionListItem item,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => LockedTransactionSheet(item: item),
  );
}

/// Read-only details of a row that belongs to a loan or an investment, with
/// where to edit it. No fields and no Save or Delete: the owning module
/// changes these rows (no Loans/Investments screens exist yet, so the
/// pointer is text only).
///
/// Registered in COMPONENTS.md.
class LockedTransactionSheet extends StatelessWidget {
  const LockedTransactionSheet({super.key, required this.item});

  final TransactionListItem item;

  /// "Edit it from Loans" / "Edit it from Investments".
  static String editHint(TransactionSource source) => switch (source) {
    TransactionSource.loan => 'Edit it from Loans',
    TransactionSource.investment => 'Edit it from Investments',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final t = item.transaction;
    final display = transactionDisplay(item);
    final source = t.sourceType;
    final note = t.note?.trim();

    final typeLabel = switch (t.type) {
      TransactionType.expense => 'Expense',
      TransactionType.income => 'Income',
      TransactionType.transfer => 'Transfer',
    };
    final fromLabel = switch (t.type) {
      TransactionType.expense => 'Paid from',
      TransactionType.income => 'Received in',
      TransactionType.transfer => 'From',
    };

    Widget field(String label, Widget value) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: AppSpacing.xs),
          value,
        ],
      ),
    );
    Widget text(String value) => Text(value, style: theme.textTheme.bodyLarge);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsRegular.lock, size: 20, color: muted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Transaction', style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          field('Type', text(typeLabel)),
          field(
            'Amount',
            AmountText(
              display.paise,
              tone: display.tone,
              style: theme.textTheme.titleMedium,
            ),
          ),
          if (t.type != TransactionType.transfer)
            field('Category', text(item.categoryName ?? 'Uncategorised')),
          field(fromLabel, text(item.accountName)),
          if (t.type == TransactionType.transfer)
            field('To', text(item.toAccountName ?? 'Unknown account')),
          if (note != null && note.isNotEmpty) field('Note', text(note)),
          field('Date', text(AppDates.format(t.occurredAt))),
          const SizedBox(height: AppSpacing.sm),
          if (source != null)
            Text(
              editHint(source),
              key: const ValueKey('locked_edit_hint'),
              style: theme.textTheme.bodyLarge,
            ),
        ],
      ),
    );
  }
}
