import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_spacing.dart';
import 'accounts_screen.dart';
import 'widgets/balance_summary.dart';

/// The Finance tab: the balance summary and a "Manage" section.
/// No transaction FAB yet (that comes with transactions).
class FinanceHomeScreen extends StatelessWidget {
  const FinanceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Finance')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const BalanceSummary(),
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
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountsScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
