import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/db/local_user_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/dashboard_card.dart';
import '../providers/transactions_providers.dart';
import '../transactions_screen.dart';
import 'transaction_tile.dart';

/// The "Recent transactions" section of the Finance home: a header, then ONE
/// card with up to 5 descriptive rows and a "See all" action (only when there
/// is at least one row) that opens the full Transactions screen. Empty: a
/// DashboardCard. Loading: a spinner card (never a fake empty state). Error:
/// message + Retry.
///
/// Registered in COMPONENTS.md.
class RecentTransactions extends ConsumerWidget {
  const RecentTransactions({super.key});

  /// Most rows shown.
  static const int maxRows = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recent = ref.watch(recentTransactionsProvider);

    final Widget body;
    var hasRows = false;
    if (recent.hasError) {
      body = _ErrorCard(
        onRetry: () {
          ref.invalidate(localUserIdProvider);
          ref.invalidate(recentTransactionsProvider);
        },
      );
    } else if (recent.valueOrNull == null) {
      body = const _LoadingCard();
    } else {
      final items = recent.requireValue.take(maxRows).toList();
      if (items.isEmpty) {
        body = DashboardCard(
          icon: PhosphorIconsRegular.receipt,
          title: 'No transactions yet',
          child: Text(
            'Tap + to add your first one.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      } else {
        hasRows = true;
        body = Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(),
                TransactionTile(item: items[i]),
              ],
            ],
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // AppSpacing.xs lines the header up with the cards (default 4px
        // margin), like the "Manage" header.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Recent transactions',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              // Only when there is something to see: not in the empty,
              // loading or error states.
              if (hasRows)
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TransactionsScreen(),
                    ),
                  ),
                  child: const Text('See all'),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        body,
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Couldn't load transactions",
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
