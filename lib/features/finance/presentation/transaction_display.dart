import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/utils/app_dates.dart';
import '../../../shared/widgets/amount_text.dart';
import '../data/transaction_queries.dart';
import '../data/transactions_table.dart';
import 'category_display.dart';

/// What a transaction row shows. Pure data, no BuildContext.
class TransactionDisplay {
  const TransactionDisplay({
    required this.title,
    required this.subtitle,
    required this.dateLabel,
    required this.paise,
    required this.tone,
    required this.icon,
  });

  final String title;

  /// Income/expense: "category · account" (just the account when the title
  /// already is the category); transfer: "from → to". No date.
  final String subtitle;

  /// "Today", "Yesterday", "5 Oct", "5 Oct 2025": shown under the amount.
  final String dateLabel;

  /// Pass straight to AmountText: negative for an expense.
  final int paise;
  final AmountTone tone;
  final IconData icon;
}

/// Describes a transaction so a row says what it was.
///
/// - title: the note if there is one; else the category name; a transfer
///   without a note is "Transfer"; no category name at all is
///   "Uncategorised".
/// - subtitle: income/expense "category · account" (the category is dropped
///   when the title already IS the category name, and when there is none);
///   transfer "from → to". The date is NOT part of the subtitle: it is
///   [TransactionDisplay.dateLabel], shown under the amount.
/// - amount: expense negative + negative tone; income positive + positive
///   tone; transfer plain + neutral.
/// - icon: the category's icon; a swap icon for a transfer.
///
/// [now] is for tests (it decides "Today" / "Yesterday").
TransactionDisplay transactionDisplay(
  TransactionListItem item, {
  DateTime? now,
}) {
  final t = item.transaction;
  final rawNote = t.note?.trim();
  final String? note = (rawNote == null || rawNote.isEmpty) ? null : rawNote;
  final category = item.categoryName;
  final date = AppDates.format(t.occurredAt, now: now);

  if (t.type == TransactionType.transfer) {
    final to = item.toAccountName ?? 'Unknown account';
    return TransactionDisplay(
      title: note ?? 'Transfer',
      subtitle: '${item.accountName} \u2192 $to',
      dateLabel: date,
      paise: t.amount,
      tone: AmountTone.neutral,
      icon: PhosphorIconsRegular.arrowsLeftRight,
    );
  }

  final title = note ?? category ?? 'Uncategorised';
  final parts = <String>[
    if (category != null && title != category) category,
    item.accountName,
  ];

  final isExpense = t.type == TransactionType.expense;
  return TransactionDisplay(
    title: title,
    subtitle: parts.join(' \u00B7 '),
    dateLabel: date,
    paise: isExpense ? -t.amount : t.amount,
    tone: isExpense ? AmountTone.negative : AmountTone.positive,
    icon: categoryIcon(item.categoryIcon),
  );
}