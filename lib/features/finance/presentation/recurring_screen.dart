import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/theme/app_colors.dart'; // NEW — danger color for the missing-category warning
import '../../../core/theme/app_spacing.dart';
import '../data/accounts_dao.dart';
import '../data/categories_dao.dart';
import '../data/recurring_rules_dao.dart';
import '../domain/recurrence_frequency.dart';
import 'recurring_rule_form_sheet.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(categoriesSeedProvider); // NEW — same pattern as every other screen that lists categories
    final rulesAsync = ref.watch(recurringRulesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dangerColor = isDark ? AppColors.dark.danger : AppColors.light.danger;

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring')),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Couldn't load recurring rules: $e")),
        data: (rules) {
          if (rules.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'No recurring rules yet. Tap + to add one.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return accountsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text("Couldn't load accounts: $e"),
            data: (accountList) => categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text("Couldn't load categories: $e"),
              data: (categoryList) {
                final accountsById = {for (final a in accountList) a.id: a};
                final categoriesById = {for (final c in categoryList) c.id: c};

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: rules.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final rule = rules[i];
                    final account = accountsById[rule.accountId];
                    final category = categoriesById[rule.categoryId];
                    final freq = RecurrenceFrequency.values.byName(rule.frequency);
                    // Bug 6 — defense-in-depth: structurally
                    // unreachable under normal use now that
                    // deleteCategory blocks on referencing rules, but
                    // surfaced visibly rather than silently stalling
                    // if it ever happens anyway (task response).
                    final categoryMissing = category == null;

                    return Card(
                      child: ListTile(
                        title: Text(category?.name ?? 'Category', style: theme.textTheme.bodyLarge),
                        subtitle: categoryMissing
                            ? Text(
                                'Category missing — this rule has stopped',
                                style: theme.textTheme.bodyMedium?.copyWith(color: dangerColor),
                              )
                            : Text(
                                '${account?.name ?? 'Account'} · ${freq.label} · Next: ${_formatDate(rule.nextDueDate)}'
                                '${rule.note.isNotEmpty ? ' · ${rule.note}' : ''}',
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                        trailing: Switch(
                          value: rule.isActive,
                          onChanged: (v) => ref.read(appDatabaseProvider).setRuleActive(id: rule.id, isActive: v),
                        ),
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => RecurringRuleFormSheet(existing: rule),
                        ),
                        onLongPress: () => _confirmDelete(context, ref, rule, category?.name ?? 'this rule'),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const RecurringRuleFormSheet(),
        ),
        child: const Icon(PhosphorIconsRegular.plus),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  void _confirmDelete(BuildContext context, WidgetRef ref, RecurringTransactionRuleRow rule, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete recurring rule?'),
        content: Text(
          'This deletes the rule for "$name". Transactions it already generated are kept, unaffected. '
          "This can't be undone.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(appDatabaseProvider).deleteRule(rule.id);
              Navigator.pop(dialogContext);
            },
            child: Text('Delete', style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}