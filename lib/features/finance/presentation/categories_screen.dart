import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/local_user_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/categories_table.dart';
import 'category_display.dart';
import 'category_list_entries.dart';
import 'providers/transactions_providers.dart';
import 'widgets/category_form_sheet.dart';

/// Manage categories: an Expense | Income chip row and the categories of the
/// chosen kind (active A-Z, then an "Archived" section). Tap a row to edit it;
/// the + button adds one for the chosen kind. System categories never appear.
/// Nothing is ever deleted: a category is archived instead.
///
/// The chip row is always visible; only the list area shows loading or an
/// error. The chosen kind is local to the screen.
///
/// Registered in COMPONENTS.md.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  /// Bottom padding so the FAB never covers the last row.
  static const double listBottomPadding = 96;

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  CategoryKind _kind = CategoryKind.expense;

  static const _kinds = <(String, CategoryKind)>[
    ('Expense', CategoryKind.expense),
    ('Income', CategoryKind.income),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kind = _kind;
    final async = ref.watch(manageCategoriesProvider(kind));

    final Widget list;
    if (async.hasError) {
      list = _ErrorView(
        onRetry: () {
          ref.invalidate(localUserIdProvider);
          ref.invalidate(manageCategoriesProvider(kind));
        },
      );
    } else if (async.valueOrNull == null) {
      list = const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else {
      final entries = flattenCategories(async.requireValue);
      list = entries.isEmpty
          ? _EmptyView(kind: kind)
          : _CategoryList(entries: entries);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton(
        // No hero: the Finance home underneath has its own FAB.
        heroTag: null,
        tooltip: 'Add category',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        onPressed: () => showCategoryFormSheet(context, kind: kind),
        child: const Icon(PhosphorIconsRegular.plus),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final (label, value) in _kinds)
                  ChoiceChip(
                    key: ValueKey('categories-kind-${value.name}'),
                    label: Text(label),
                    selected: _kind == value,
                    onSelected: (_) => setState(() => _kind = value),
                  ),
              ],
            ),
          ),
          Expanded(child: list),
        ],
      ),
    );
  }
}

/// The lazy list: rows (one Card each) and the "Archived" header.
class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.entries});

  final List<CategoryListEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        CategoriesScreen.listBottomPadding,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        switch (entries[index]) {
          case CategoryArchivedHeader():
            // AppSpacing.xs lines the header up with the cards (default 4px
            // margin).
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.xs,
              ),
              child: Text(
                'Archived',
                key: const ValueKey('categories-archived-header'),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          case CategoryRowEntry(:final category):
            return Card(
              // Clips the tap ripple to the rounded corners.
              clipBehavior: Clip.antiAlias,
              child: _CategoryRow(category: category),
            );
        }
      },
    );
  }
}

class _CategoryRow extends StatelessWidget {
  _CategoryRow({required this.category})
    : super(key: ValueKey('category-row-${category.id}'));

  final CategoryRow category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final color = Color(category.color);
    final archived = category.isArchived;
    final subtitle = [
      if (archived) 'Archived',
      if (category.seedKey != null) 'Built-in',
    ].join(' \u00B7 ');

    return InkWell(
      onTap: () => showCategoryFormSheet(
        context,
        kind: category.kind,
        category: category,
      ),
      child: Opacity(
        // Archived rows look muted.
        opacity: archived ? 0.6 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  categoryIcon(category.icon),
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name, style: theme.textTheme.bodyLarge),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: muted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.kind});

  final CategoryKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final word = kind == CategoryKind.income ? 'income' : 'expense';

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        CategoriesScreen.listBottomPadding,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'No $word categories. Tap + to add one, or restore an archived '
            'category.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn't load categories", style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
