import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/budgets_dao.dart'; // NEW — CategoryHasBudgetsException
import '../data/categories_dao.dart';
import '../data/transactions_dao.dart';
import '../domain/category_kind.dart';
import '../domain/category_style.dart';
import 'category_form_sheet.dart';

class CategoriesListScreen extends ConsumerWidget {
  const CategoriesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(categoriesSeedProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Couldn't load categories: $e")),
      data: (items) => ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) {
          final category = items[i];
          final hex = isDark ? CategoryPalette.darkHexFor(category.color) : category.color;
          final color = CategoryPalette.colorFromHex(hex);
          final kind = CategoryKind.values.byName(category.kind);

          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.16),
                foregroundColor: color,
                child: Icon(CategoryIcons.forKey(category.icon)),
              ),
              title: Text(category.name, style: theme.textTheme.bodyLarge),
              subtitle: Text(
                kind.label,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => CategoryFormSheet(existing: category),
              ),
              onLongPress: () => _confirmDelete(context, ref, category),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CategoryRow category) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('This deletes "${category.name}". This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(appDatabaseProvider).deleteCategory(category.id);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } on CategoryHasTransactionsException catch (e) {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Can't delete — ${e.count} transaction${e.count == 1 ? '' : 's'} use this category. "
                        'Delete those transactions first.',
                      ),
                    ),
                  );
                }
              } on CategoryHasBudgetsException catch (e) {
                // NEW this task.
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Can't delete — ${e.count} budget${e.count == 1 ? '' : 's'} use this category. "
                        'Delete ${e.count == 1 ? 'it' : 'them'} first.',
                      ),
                    ),
                  );
                }
              }
            },
            child: Text('Delete', style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}