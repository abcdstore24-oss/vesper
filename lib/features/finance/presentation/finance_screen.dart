import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/db/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/dashboard_card.dart';
import '../data/accounts_dao.dart';
import '../data/categories_dao.dart';
import '../data/investments_dao.dart';
import '../data/transactions_dao.dart';
import '../domain/category_kind.dart';
import '../domain/category_style.dart';
import 'accounts_screen.dart';
import 'budgets_list_screen.dart';
import 'categories_screen.dart';
import 'charts_page.dart';
import 'investments_list_screen.dart';
import 'summary_page.dart';
import 'transaction_form_sheet.dart';
import 'transactions_screen.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finance')),
      body: ListView(
        padding: const EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: 88,
        ),
        children: [
          Row(
            children: const [
              Expanded(child: _NetWorthGlanceCard()),
              SizedBox(width: AppSpacing.md),
              Expanded(child: _ThisMonthGlanceCard()),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const _RecentTransactionsSection(),
          const SizedBox(height: AppSpacing.xl),
          Text('Manage', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          // CHANGED this task: was 4 separate full-width
          // DashboardCard entries (_NavCard) — now one Card of
          // ListTile rows, matching the Card+ListTile convention
          // every other list in this feature already uses (Accounts,
          // Categories, Budgets, Investments, Transactions), rather
          // than borrowing the main Dashboard's card-grid visual
          // language. _NavCard is removed — nothing else in this
          // file used it.
          const _ManageSection(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const TransactionFormSheet(),
        ),
        child: const Icon(PhosphorIconsRegular.plus),
      ),
    );
  }
}

class _ManageEntry {
  const _ManageEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

/// One Card, 4 ListTile rows, thin Divider between consecutive rows
/// (none after the last) — same order, same destinations as before.
class _ManageSection extends StatelessWidget {
  const _ManageSection();

  @override
  Widget build(BuildContext context) {
    final entries = [
      _ManageEntry(
        icon: PhosphorIconsRegular.chartBar,
        title: 'Budgets',
        subtitle: 'Track monthly limits',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BudgetsListScreen()),
        ),
      ),
      _ManageEntry(
        icon: PhosphorIconsRegular.trendUp,
        title: 'Investments',
        subtitle: 'Holdings & performance',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InvestmentsListScreen()),
        ),
      ),
      _ManageEntry(
        icon: PhosphorIconsRegular.bank,
        title: 'Accounts',
        subtitle: 'Balances by account',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccountsScreen()),
        ),
      ),
      _ManageEntry(
        icon: PhosphorIconsRegular.squaresFour,
        title: 'Categories',
        subtitle: 'Income & expense tags',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CategoriesScreen()),
        ),
      ),
    ];

    final theme = Theme.of(context);

    return Card(
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            ListTile(
              leading: Icon(entries[i].icon, color: theme.colorScheme.onSurfaceVariant),
              title: Text(entries[i].title, style: theme.textTheme.bodyLarge),
              subtitle: Text(
                entries[i].subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              trailing: Icon(PhosphorIconsRegular.caretRight, color: theme.colorScheme.onSurfaceVariant),
              onTap: entries[i].onTap,
            ),
          ],
        ],
      ),
    );
  }
}

class _NetWorthGlanceCard extends ConsumerWidget {
  const _NetWorthGlanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accountsAsync = ref.watch(accountsProvider);
    final balancesAsync = ref.watch(accountBalancesProvider);
    final investmentsAsync = ref.watch(investmentsProvider);

    Widget body;
    if (accountsAsync.hasError || balancesAsync.hasError || investmentsAsync.hasError) {
      body = Text(
        "Couldn't load",
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    } else if (!accountsAsync.hasValue || !balancesAsync.hasValue || !investmentsAsync.hasValue) {
      body = const SizedBox(
        height: 24,
        child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    } else {
      final accounts = accountsAsync.requireValue;
      final balances = balancesAsync.requireValue;
      final investments = investmentsAsync.requireValue;

      var totalCents = 0;
      for (final a in accounts) {
        totalCents += a.startingBalanceCents + (balances[a.id] ?? 0);
      }
      for (final inv in investments) {
        totalCents += inv.currentValueCents;
      }

      final decimal = (totalCents.abs() / 100).toStringAsFixed(2);
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${totalCents < 0 ? '-' : ''}$decimal',
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${accounts.length} account${accounts.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${investments.length} investment${investments.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChartsPage())),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: DashboardCard(icon: PhosphorIconsRegular.coins, title: 'Net Worth', child: body),
    );
  }
}

class _ThisMonthGlanceCard extends ConsumerWidget {
  const _ThisMonthGlanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final successColor = isDark ? AppColors.dark.success : AppColors.light.success;
    final dangerColor = isDark ? AppColors.dark.danger : AppColors.light.danger;

    final now = DateTime.now();
    final summaryAsync = ref.watch(monthSummaryProvider((now.year, now.month)));

    Widget body;
    if (summaryAsync.hasError) {
      body = Text(
        "Couldn't load",
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    } else if (!summaryAsync.hasValue) {
      body = const SizedBox(
        height: 24,
        child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    } else {
      final summary = summaryAsync.requireValue;
      final net = summary.netCents;
      final decimal = (net.abs() / 100).toStringAsFixed(2);

      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${net >= 0 ? '+' : '-'}$decimal',
              style: theme.textTheme.titleLarge?.copyWith(color: net >= 0 ? successColor : dangerColor),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Inc ${(summary.totalIncomeCents / 100).toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Exp ${(summary.totalExpenseCents / 100).toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SummaryPage())),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: DashboardCard(icon: PhosphorIconsRegular.calendarBlank, title: 'Month', child: body),
    );
  }
}

class _RecentTransactionsSection extends ConsumerWidget {
  const _RecentTransactionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final transactionsAsync = ref.watch(transactionsProvider(null));
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Transactions', style: theme.textTheme.titleMedium),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TransactionsScreen()),
              ),
              child: const Text('See all'),
            ),
          ],
        ),
        transactionsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text("Couldn't load transactions: $e"),
          ),
          data: (allTxns) {
            if (allTxns.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'No transactions yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              );
            }
            final recent = allTxns.take(5).toList();

            return accountsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text("Couldn't load accounts: $e"),
              data: (accountList) => categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text("Couldn't load categories: $e"),
                data: (categoryList) {
                  final accountsById = {for (final a in accountList) a.id: a};
                  final categoriesById = {for (final c in categoryList) c.id: c};

                  return Column(
                    children: [
                      for (final txn in recent)
                        _RecentTransactionTile(
                          txn: txn,
                          account: accountsById[txn.accountId],
                          category: categoriesById[txn.categoryId],
                        ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RecentTransactionTile extends StatelessWidget {
  const _RecentTransactionTile({required this.txn, required this.account, required this.category});

  final TransactionRow txn;
  final AccountRow? account;
  final CategoryRow? category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final successColor = isDark ? AppColors.dark.success : AppColors.light.success;
    final kind = CategoryKind.values.byName(txn.type);
    final isIncome = kind == CategoryKind.income;

    final hex = category == null ? null : (isDark ? CategoryPalette.darkHexFor(category!.color) : category!.color);
    final avatarColor = hex != null ? CategoryPalette.colorFromHex(hex) : theme.colorScheme.onSurfaceVariant;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: avatarColor.withValues(alpha: 0.16),
          foregroundColor: avatarColor,
          child: Icon(category != null ? CategoryIcons.forKey(category!.icon) : Icons.category_outlined),
        ),
        title: Text(category?.name ?? 'Category', style: theme.textTheme.bodyLarge),
        subtitle: Text(
          [account?.name ?? 'Account', _formatDate(txn.occurredAt)].join(' · '),
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${isIncome ? '+' : '-'}${(txn.amountCents / 100).toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(color: isIncome ? successColor : theme.colorScheme.error),
          ),
        ),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => TransactionFormSheet(existing: txn),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}