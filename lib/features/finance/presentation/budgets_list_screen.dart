import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/budgets_dao.dart';
import '../data/categories_dao.dart';
import '../domain/category_style.dart';
import '../domain/month_key.dart';
import 'budget_form_sheet.dart';

class BudgetsListScreen extends ConsumerStatefulWidget {
  const BudgetsListScreen({super.key});

  @override
  ConsumerState<BudgetsListScreen> createState() => _BudgetsListScreenState();
}

class _BudgetsListScreenState extends ConsumerState<BudgetsListScreen> {
  late String _monthKey;

  @override
  void initState() {
    super.initState();
    _monthKey = currentMonthKey();
  }

  void _goPrevMonth() => setState(() => _monthKey = previousMonthKey(_monthKey));
  void _goNextMonth() => setState(() => _monthKey = nextMonthKey(_monthKey));

  @override
  Widget build(BuildContext context) {
    ref.watch(categoriesSeedProvider);
    ref.watch(budgetsRolloverProvider(_monthKey));

    ref.listen<AsyncValue<int>>(budgetsRolloverProvider(_monthKey), (previous, next) {
      final count = next.asData?.value ?? 0;
      if (count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Copied $count budget${count == 1 ? '' : 's'} from ${monthKeyLabel(previousMonthKey(_monthKey))}',
            ),
          ),
        );
      }
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dangerColor = isDark ? AppColors.dark.danger : AppColors.light.danger;

    final budgetsAsync = ref.watch(budgetsProvider(_monthKey));
    final categoriesAsync = ref.watch(categoriesProvider);
    final spentAsync = ref.watch(categorySpentProvider(_monthKey));

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: _goPrevMonth, icon: const Icon(Icons.chevron_left)),
                Text(monthKeyLabel(_monthKey), style: theme.textTheme.titleMedium),
                IconButton(onPressed: _goNextMonth, icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ),
          Expanded(
            child: budgetsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("Couldn't load budgets: $e")),
              data: (budgetList) {
                if (budgetList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'No budgets set for ${monthKeyLabel(_monthKey)}. Tap + to add one.',
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
                    final spent = spentAsync.asData?.value ?? const <String, int>{};

                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: budgetList.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        final budget = budgetList[i];
                        final category = categoriesById[budget.categoryId];
                        final spentCents = spent[budget.categoryId] ?? 0;
                        final isOver = spentCents >= budget.limitAmountCents;
                        final remainingCents = budget.limitAmountCents - spentCents;
                        final progress = budget.limitAmountCents == 0
                            ? 1.0
                            : (spentCents / budget.limitAmountCents).clamp(0.0, 1.0);

                        final hex = category == null
                            ? null
                            : (isDark ? CategoryPalette.darkHexFor(category.color) : category.color);
                        final avatarColor =
                            hex != null ? CategoryPalette.colorFromHex(hex) : theme.colorScheme.onSurfaceVariant;

                        return Card(
                          child: InkWell(
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => BudgetFormSheet(monthKey: _monthKey, existing: budget),
                            ),
                            onLongPress: () => _confirmDelete(context, budget, category?.name ?? 'this category'),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: avatarColor.withValues(alpha: 0.16),
                                        foregroundColor: avatarColor,
                                        child: Icon(
                                          category != null ? CategoryIcons.forKey(category.icon) : Icons.category_outlined,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(category?.name ?? 'Category', style: theme.textTheme.bodyLarge),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            '${(spentCents / 100).toStringAsFixed(2)} / ${(budget.limitAmountCents / 100).toStringAsFixed(2)}',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: isOver ? dangerColor : theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      // Same fix as category_form_sheet.dart's
                                      // _IconChoice — surfaceContainerHighest
                                      // is now a real alias for the locked
                                      // surfaceVariant token, no ignore
                                      // comment needed.
                                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                      valueColor: AlwaysStoppedAnimation(isOver ? dangerColor : theme.colorScheme.primary),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        isOver
                                            ? 'Over by ${(remainingCents.abs() / 100).toStringAsFixed(2)}'
                                            : 'Remaining ${(remainingCents / 100).toStringAsFixed(2)}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: isOver ? dangerColor : theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => BudgetFormSheet(monthKey: _monthKey),
        ),
        child: const Icon(PhosphorIconsRegular.plus),
      ),
    );
  }

  void _confirmDelete(BuildContext context, BudgetRow budget, String categoryName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete budget?'),
        content: Text('This deletes the budget for "$categoryName" in ${monthKeyLabel(_monthKey)}. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(appDatabaseProvider).deleteBudget(budget.id);
              Navigator.pop(dialogContext);
            },
            child: Text('Delete', style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}