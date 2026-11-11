import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_spacing.dart';
import 'accounts_screen.dart';
import 'categories_screen.dart';
import 'widgets/balance_summary.dart';
import 'widgets/recent_transactions.dart';
import 'widgets/transaction_form_sheet.dart';

/// The Finance tab: the balance summary, the most recent transactions and a
/// "Manage" section, with a button to add a transaction.
class FinanceHomeScreen extends StatelessWidget {
  const FinanceHomeScreen({super.key});

  /// Bottom padding so the FAB never covers the last row.
  static const double listBottomPadding = 96;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Finance')),
      floatingActionButton: FloatingActionButton(
        // No hero: every tab of the app shell is built at once, so tabs with
        // their own default-tag FABs would otherwise clash when a route is
        // pushed.
        heroTag: null,
        tooltip: 'Add transaction',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        onPressed: () => showTransactionFormSheet(context),
        child: const Icon(PhosphorIconsRegular.plus),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          listBottomPadding,
        ),
        children: [
          const BalanceSummary(),
          const SizedBox(height: AppSpacing.lg),
          const RecentTransactions(),
          const SizedBox(height: AppSpacing.lg),
          // AppSpacing.xs lines the header up with the cards, which carry
          // the theme's default 4px margin.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text('Manage', style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(
                PhosphorIconsRegular.bank,
                color: theme.colorScheme.onSurface,
              ),
              title: Text('Accounts', style: theme.textTheme.bodyLarge),
              subtitle: Text(
                'Balances by account',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Icon(
                PhosphorIconsRegular.caretRight,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AccountsScreen())),
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(
                PhosphorIconsRegular.tag,
                color: theme.colorScheme.onSurface,
              ),
              title: Text('Categories', style: theme.textTheme.bodyLarge),
              subtitle: Text(
                'Add, rename, archive',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Icon(
                PhosphorIconsRegular.caretRight,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
