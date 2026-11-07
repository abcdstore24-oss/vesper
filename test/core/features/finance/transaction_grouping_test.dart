import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/features/finance/presentation/transaction_grouping.dart';

import '../../../support/ui_test_helpers.dart';

void main() {
  // Saturday 17 Oct 2026, evening.
  final now = DateTime(2026, 10, 17, 18);

  List<String> shape(List<TransactionListEntry> entries) => [
    for (final e in entries)
      switch (e) {
        TransactionDateHeader(:final label) => 'H:$label',
        TransactionRowEntry(:final item) => 'R:${item.transaction.id}',
      },
  ];

  test('empty input gives no entries', () {
    expect(groupTransactionsByDate(const [], now: now), isEmpty);
  });

  test('Today, Yesterday, this year and another year', () {
    final entries = groupTransactionsByDate([
      makeTransactionItem(id: 'a', occurredAt: DateTime(2026, 10, 17, 9)),
      makeTransactionItem(id: 'b', occurredAt: DateTime(2026, 10, 16, 12)),
      makeTransactionItem(id: 'c', occurredAt: DateTime(2026, 10, 5, 12)),
      makeTransactionItem(id: 'd', occurredAt: DateTime(2025, 10, 5, 12)),
    ], now: now);

    expect(shape(entries), [
      'H:Today',
      'R:a',
      'H:Yesterday',
      'R:b',
      'H:5 Oct',
      'R:c',
      'H:5 Oct 2025',
      'R:d',
    ]);
  });

  test('several rows on one day share one header, order is kept', () {
    final entries = groupTransactionsByDate([
      makeTransactionItem(id: 'a', occurredAt: DateTime(2026, 10, 17, 17)),
      makeTransactionItem(id: 'b', occurredAt: DateTime(2026, 10, 17, 9)),
      makeTransactionItem(id: 'c', occurredAt: DateTime(2026, 10, 17, 0, 0, 1)),
      makeTransactionItem(id: 'd', occurredAt: DateTime(2026, 10, 16, 23)),
      makeTransactionItem(id: 'e', occurredAt: DateTime(2026, 10, 16, 1)),
    ], now: now);

    expect(shape(entries), [
      'H:Today',
      'R:a',
      'R:b',
      'R:c',
      'H:Yesterday',
      'R:d',
      'R:e',
    ]);
  });

  test('the midnight boundary splits days exactly', () {
    final entries = groupTransactionsByDate([
      makeTransactionItem(id: 'a', occurredAt: DateTime(2026, 10, 17)),
      makeTransactionItem(
        id: 'b',
        occurredAt: DateTime(2026, 10, 16, 23, 59, 59),
      ),
    ], now: now);

    expect(shape(entries), ['H:Today', 'R:a', 'H:Yesterday', 'R:b']);
  });

  test('"now" just after midnight moves Today/Yesterday with it', () {
    final justAfterMidnight = DateTime(2026, 10, 18, 0, 0, 5);
    final entries = groupTransactionsByDate([
      makeTransactionItem(id: 'a', occurredAt: DateTime(2026, 10, 17, 23, 59)),
    ], now: justAfterMidnight);

    expect(shape(entries), ['H:Yesterday', 'R:a']);
  });

  test('a UTC timestamp is grouped by its LOCAL day', () {
    final local = DateTime(2026, 10, 17, 9);
    final entries = groupTransactionsByDate([
      makeTransactionItem(id: 'a', occurredAt: local.toUtc()),
    ], now: now);

    expect(shape(entries), ['H:Today', 'R:a']);
  });

  test('without now, the current day is Today', () {
    final entries = groupTransactionsByDate([
      makeTransactionItem(id: 'a', occurredAt: DateTime.now()),
    ]);
    expect(shape(entries), ['H:Today', 'R:a']);
  });
}
