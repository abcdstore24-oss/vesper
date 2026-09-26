import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/categories_dao.dart';
import '../data/transactions_dao.dart';
import '../domain/category_style.dart';
import '../domain/month_summary.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _goPrevMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year -= 1;
      } else {
        _month -= 1;
      }
    });
  }

  void _goNextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year += 1;
      } else {
        _month += 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(categoriesSeedProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final successColor = isDark ? AppColors.dark.success : AppColors.light.success;
    final dangerColor = isDark ? AppColors.dark.danger : AppColors.light.danger;

    final summaryAsync = ref.watch(monthSummaryProvider((_year, _month)));
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: _goPrevMonth, icon: const Icon(Icons.chevron_left)),
              Text('${_monthNames[_month - 1]} $_year', style: theme.textTheme.titleMedium),
              IconButton(onPressed: _goNextMonth, icon: const Icon(Icons.chevron_right)),
            ],
          ),
        ),
        Expanded(
          child: summaryAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text("Couldn't load summary: $e")),
            data: (summary) {
              if (summary.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'No transactions in ${_monthNames[_month - 1]} $_year',
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Couldn't load categories: $e")),
                data: (categoryList) {
                  final categoriesById = {for (final c in categoryList) c.id: c};

                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Income',
                              cents: summary.totalIncomeCents,
                              color: successColor,
                              signPrefix: '+',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _StatCard(
                              label: 'Expense',
                              cents: summary.totalExpenseCents,
                              color: dangerColor,
                              signPrefix: '-',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _StatCard(
                              label: 'Net',
                              cents: summary.netCents,
                              color: summary.netCents >= 0 ? successColor : dangerColor,
                              signPrefix: summary.netCents >= 0 ? '+' : '-',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('By category', style: theme.textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.sm),
                      for (final ct in summary.categoryTotals)
                        _CategoryTotalTile(
                          total: ct,
                          category: categoriesById[ct.categoryId],
                          isDark: isDark,
                          successColor: successColor,
                          dangerColor: dangerColor,
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.cents,
    required this.color,
    required this.signPrefix,
  });

  final String label;
  final int cents;
  final Color color;
  final String signPrefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decimal = (cents.abs() / 100).toStringAsFixed(2);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.xs),
            // Fixed: was maxLines: 1 + overflow: ellipsis, which
            // silently truncated long amounts (e.g. "-2800.00" ->
            // "-2800..."). A finance app must never cut off part of a
            // real number — FittedBox shrinks the whole string to fit
            // instead, so it's always fully visible, just smaller.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '$signPrefix$decimal',
                style: theme.textTheme.titleMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTotalTile extends StatelessWidget {
  const _CategoryTotalTile({
    required this.total,
    required this.category,
    required this.isDark,
    required this.successColor,
    required this.dangerColor,
  });

  final CategoryMonthTotal total;
  final CategoryRow? category;
  final bool isDark;
  final Color successColor;
  final Color dangerColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNetIncome = total.netCents >= 0;

    final hex = category == null
        ? null
        : (isDark ? CategoryPalette.darkHexFor(category!.color) : category!.color);
    final avatarColor = hex != null ? CategoryPalette.colorFromHex(hex) : theme.colorScheme.onSurfaceVariant;

    final decimal = (total.netCents.abs() / 100).toStringAsFixed(2);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: avatarColor.withValues(alpha: 0.16),
          foregroundColor: avatarColor,
          child: Icon(category != null ? CategoryIcons.forKey(category!.icon) : Icons.category_outlined),
        ),
        title: Text(category?.name ?? 'Category', style: theme.textTheme.bodyLarge),
        subtitle: Text(
          '${total.transactionCount} transaction${total.transactionCount == 1 ? '' : 's'}',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        // No maxLines/overflow was set here — this one didn't have
        // the bug, left as-is per task response.
        trailing: Text(
          '${isNetIncome ? '+' : '-'}$decimal',
          style: theme.textTheme.titleMedium?.copyWith(color: isNetIncome ? successColor : dangerColor),
        ),
      ),
    );
  }
}