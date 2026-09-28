import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/db_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/accounts_dao.dart';
import '../data/categories_dao.dart';
import '../data/investment_sales_dao.dart'; // NEW — TransactionHasSaleException
import '../data/transactions_dao.dart';
import '../domain/category_kind.dart';
import '../domain/category_style.dart';
import 'transaction_form_sheet.dart';

class TransactionsListScreen extends ConsumerStatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  ConsumerState<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends ConsumerState<TransactionsListScreen> {
  String? _filterAccountId;

  @override
  Widget build(BuildContext context) {
    ref.watch(categoriesSeedProvider);

    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final transactionsAsync = ref.watch(transactionsProvider(_filterAccountId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final successColor = isDark ? AppColors.dark.success : AppColors.light.success;

    return accountsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Couldn't load accounts: $e")),
      data: (accountList) => categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Couldn't load categories: $e")),
        data: (categoryList) {
          final accountsById = {for (final a in accountList) a.id: a};
          final categoriesById = {for (final c in categoryList) c.id: c};

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: DropdownButtonFormField<String?>(
                  initialValue: _filterAccountId,
                  decoration: const InputDecoration(labelText: 'Filter'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All accounts')),
                    for (final a in accountList) DropdownMenuItem<String?>(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: (v) => setState(() => _filterAccountId = v),
                ),
              ),
              Expanded(
                child: transactionsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text("Couldn't load transactions: $e")),
                  data: (items) {
                    if (items.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Text(
                            'No transactions yet. Tap + to add one.',
                            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        final txn = items[i];
                        final account = accountsById[txn.accountId];
                        final category = categoriesById[txn.categoryId];
                        final kind = CategoryKind.values.byName(txn.type);
                        final isIncome = kind == CategoryKind.income;

                        final hex = category == null
                            ? null
                            : (isDark ? CategoryPalette.darkHexFor(category.color) : category.color);
                        final avatarColor =
                            hex != null ? CategoryPalette.colorFromHex(hex) : theme.colorScheme.onSurfaceVariant;

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: avatarColor.withValues(alpha: 0.16),
                              foregroundColor: avatarColor,
                              child: Icon(category != null ? CategoryIcons.forKey(category.icon) : Icons.category_outlined),
                            ),
                            title: Text(category?.name ?? 'Category', style: theme.textTheme.bodyLarge),
                            subtitle: Text(
                              [
                                account?.name ?? 'Account',
                                _formatDate(txn.occurredAt),
                                if (txn.note.isNotEmpty) txn.note,
                              ].join(' · '),
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              '${isIncome ? '+' : '-'}${(txn.amountCents / 100).toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: isIncome ? successColor : theme.colorScheme.error,
                              ),
                            ),
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => TransactionFormSheet(existing: txn),
                            ),
                            onLongPress: () => _confirmDelete(context, txn.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              // CHANGED this task: deleteTransaction can now throw
              // TransactionHasSaleException — was previously a bare
              // fire-and-forget call with no possible failure to
              // handle. Same try/catch/SnackBar pattern as every
              // other deletion-blocking rule in this project.
              try {
                await ref.read(appDatabaseProvider).deleteTransaction(id);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } on TransactionHasSaleException catch (e) {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Can't delete — this transaction is linked to ${e.count} investment sale"
                        "${e.count == 1 ? '' : 's'}. Delete from the investment's sale history first.",
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