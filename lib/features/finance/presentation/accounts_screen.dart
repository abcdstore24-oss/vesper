import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/dashboard_card.dart';
import '../data/account_balance.dart';
import 'account_display.dart';
import 'providers/accounts_providers.dart';
import 'widgets/account_form_sheet.dart';
import 'widgets/balance_summary.dart';

/// All accounts with their balances. Archived accounts are hidden.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  /// Bottom padding so the FAB never covers the last row.
  static const double listBottomPadding = 96;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsWithBalanceProvider);
    final active = accounts.valueOrNull
        ?.where((a) => !a.account.isArchived)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add account',
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        onPressed: () => showAccountFormSheet(context),
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
          if (active != null && active.isEmpty)
            _EmptyState(onAdd: () => showAccountFormSheet(context))
          else if (active != null)
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < active.length; i++) ...[
                    if (i > 0) const Divider(),
                    _AccountRow(item: active[i]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardCard(
      icon: PhosphorIconsRegular.bank,
      title: 'Add your first account',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add an account to start tracking your balances.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(onPressed: onAdd, child: const Text('Add account')),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  _AccountRow({required this.item})
    : super(key: ValueKey('account-row-${item.account.id}'));

  final AccountWithBalance item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final muted = theme.colorScheme.onSurfaceVariant;
    final account = item.account;
    final display = accountBalanceDisplay(account.type, item.balancePaise);
    final captionColor = switch (display.tone) {
      AmountTone.negative => palette.danger,
      AmountTone.positive => palette.success,
      AmountTone.neutral => muted,
    };

    return InkWell(
      onTap: () => showAccountFormSheet(context, account: account),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    accountTypeIcon(account.type),
                    size: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.name, style: theme.textTheme.bodyLarge),
                      Text(
                        accountTypeLabel(account.type),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // The amount may take up to half the row; beyond that it
                // scales down (AmountText), it never wraps or truncates.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * 0.5,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AmountText(
                        display.paise,
                        tone: display.tone,
                        alignment: Alignment.centerRight,
                      ),
                      // Every row reserves this line (a non-breaking space
                      // when there is no caption) so all rows are the same
                      // height.
                      display.caption == null
                          ? ExcludeSemantics(
                              child: Text(
                                '\u00A0',
                                style: theme.textTheme.bodyMedium,
                              ),
                            )
                          : Text(
                              display.caption!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: captionColor,
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
