import '../../../core/utils/app_dates.dart';
import '../data/transaction_queries.dart';

/// One entry of the flattened Transactions list: a date header or a row.
sealed class TransactionListEntry {
  const TransactionListEntry();
}

/// A day header: [label] is "Today", "Yesterday", "5 Oct" or "5 Oct 2025".
final class TransactionDateHeader extends TransactionListEntry {
  const TransactionDateHeader(this.label);

  final String label;
}

/// One transaction row under the most recent header.
final class TransactionRowEntry extends TransactionListEntry {
  const TransactionRowEntry(this.item);

  final TransactionListItem item;
}

/// Flattens [items] (already newest first) into header and row entries for a
/// lazy ListView.builder: a header, then that day's rows, then the next day.
///
/// Days are LOCAL calendar days of occurred_at (a UTC value is converted
/// first). The input order is kept: a new header starts whenever the day
/// changes from the previous row, so sorted input gives one header per day.
/// Header text is AppDates.format(date, now: now); [now] defaults to the
/// current time, read once so one call never straddles midnight.
///
/// Pure: no BuildContext, no providers.
List<TransactionListEntry> groupTransactionsByDate(
  List<TransactionListItem> items, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final entries = <TransactionListEntry>[];
  DateTime? currentDay;

  for (final item in items) {
    final at = item.transaction.occurredAt;
    final local = at.isUtc ? at.toLocal() : at;
    final day = DateTime(local.year, local.month, local.day);
    if (currentDay == null || day != currentDay) {
      currentDay = day;
      entries.add(TransactionDateHeader(AppDates.format(day, now: clock)));
    }
    entries.add(TransactionRowEntry(item));
  }
  return entries;
}
