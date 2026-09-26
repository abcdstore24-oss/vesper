import '../../../core/db/app_database.dart';
import 'category_kind.dart';

/// Aggregated totals for one calendar month, across all accounts.
/// All cents fields stay in integer minor units — conversion to a
/// decimal string happens only at render time in summary_screen.dart,
/// same convention as every other money display in this project.
class MonthSummary {
  const MonthSummary({
    required this.year,
    required this.month,
    required this.totalIncomeCents,
    required this.totalExpenseCents,
    required this.categoryTotals,
  });

  final int year;
  final int month;

  /// Always >= 0 — sum of every income-type transaction's (positive)
  /// amountCents this month.
  final int totalIncomeCents;

  /// Always >= 0 — sum of every expense-type transaction's (positive)
  /// amountCents this month. Sign is applied only when computing
  /// [netCents], never stored negative.
  final int totalExpenseCents;

  /// Only categories with >= 1 transaction this month — sorted by
  /// absolute netCents descending (biggest movers first), per spec.
  final List<CategoryMonthTotal> categoryTotals;

  /// Income minus expense. Positive = net gain for the month.
  int get netCents => totalIncomeCents - totalExpenseCents;

  bool get isEmpty =>
      totalIncomeCents == 0 && totalExpenseCents == 0 && categoryTotals.isEmpty;

  /// Builds a summary for (year, month) from an unfiltered transaction
  /// list — filtering and folding both happen here in Dart, per the
  /// locked "sum in Dart, not SQL SUM" decision, following the same
  /// shape as accountBalancesProvider (Task 2.2).
  factory MonthSummary.fromTransactions(
    List<TransactionRow> allTransactions, {
    required int year,
    required int month,
  }) {
    // DateTime(year, month + 1, 1) auto-normalizes: Dart's DateTime
    // constructor rolls an out-of-range month over into the next year
    // (month 13 -> year+1, month 1), so December -> January rollover
    // needs no special-case branch here.
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final monthTxns = allTransactions.where(
      (t) => !t.occurredAt.isBefore(start) && t.occurredAt.isBefore(end),
    );

    var totalIncome = 0;
    var totalExpense = 0;
    final byCategory = <String, _CategoryAccumulator>{};

    for (final t in monthTxns) {
      final isIncome = t.type == CategoryKind.income.name;
      if (isIncome) {
        totalIncome += t.amountCents;
      } else {
        totalExpense += t.amountCents;
      }

      final acc = byCategory.putIfAbsent(t.categoryId, () => _CategoryAccumulator());
      acc.netCents += isIncome ? t.amountCents : -t.amountCents;
      acc.transactionCount += 1;
    }

    final categoryTotals = [
      for (final entry in byCategory.entries)
        CategoryMonthTotal(
          categoryId: entry.key,
          netCents: entry.value.netCents,
          transactionCount: entry.value.transactionCount,
        ),
    ]..sort((a, b) => b.netCents.abs().compareTo(a.netCents.abs()));

    return MonthSummary(
      year: year,
      month: month,
      totalIncomeCents: totalIncome,
      totalExpenseCents: totalExpense,
      categoryTotals: categoryTotals,
    );
  }
}

class _CategoryAccumulator {
  int netCents = 0;
  int transactionCount = 0;
}

/// One category's net total for a given month.
class CategoryMonthTotal {
  const CategoryMonthTotal({
    required this.categoryId,
    required this.netCents,
    required this.transactionCount,
  });

  final String categoryId;

  /// Signed: positive if net income, negative if net expense for this
  /// category this month. Usually one consistent sign per category,
  /// but not enforced — a category's kind can change after some
  /// transactions were already stamped (Task 2.2 locked decision 2),
  /// so a category could in principle show mixed signs over time.
  final int netCents;
  final int transactionCount;
}