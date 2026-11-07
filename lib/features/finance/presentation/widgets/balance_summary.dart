import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/db/local_user_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/amount_text.dart';
import '../../data/accounts_table.dart';
import '../providers/accounts_providers.dart';

/// Total balance (and, when there is an active credit card, Card dues).
/// Shared by the Finance home and the Accounts screen.
///
/// - Loading: a small progress indicator (never a fake 0).
/// - Error: "Couldn't load your accounts" with a Retry button.
/// - No active credit-card account: ONE full-width "Total balance" card.
/// - Otherwise a Row of two equal-width, equal-height cards.
///
/// Registered in COMPONENTS.md.
class BalanceSummary extends ConsumerWidget {
  const BalanceSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsWithBalanceProvider);
    final total = ref.watch(totalBalanceProvider);
    final dues = ref.watch(creditCardDuesProvider);

    if (accounts.hasError) {
      return _ErrorCard(
        onRetry: () {
          ref.invalidate(localUserIdProvider);
          ref.invalidate(accountsWithBalanceProvider);
        },
      );
    }

    final list = accounts.valueOrNull;
    if (list == null || !total.hasValue || !dues.hasValue) {
      return const _LoadingCard();
    }

    var otherCount = 0;
    var cardCount = 0;
    for (final a in list) {
      if (a.account.isArchived) continue;
      if (a.account.type == AccountType.creditCard) {
        cardCount++;
      } else {
        otherCount++;
      }
    }

    final totalCard = _SummaryCard(
      key: const ValueKey('total_balance_card'),
      icon: PhosphorIconsRegular.wallet,
      label: 'Total balance',
      paise: total.requireValue,
      tone: AmountTone.neutral,
      caption: switch (otherCount) {
        // "No accounts yet" only when there are no active cards either.
        0 => cardCount == 0 ? 'No accounts yet' : '0 accounts',
        1 => '1 account',
        _ => '$otherCount accounts',
      },
    );
    if (cardCount == 0) return totalCard;

    final duesPaise = dues.requireValue;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: totalCard),
          Expanded(
            child: _SummaryCard(
              key: const ValueKey('card_dues_card'),
              icon: PhosphorIconsRegular.creditCard,
              label: 'Card dues',
              paise: duesPaise,
              tone: duesPaise > 0 ? AmountTone.negative : AmountTone.neutral,
              caption: cardCount == 1 ? '1 card' : '$cardCount cards',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    super.key,
    required this.icon,
    required this.label,
    required this.paise,
    required this.tone,
    required this.caption,
  });

  final IconData icon;
  final String label;
  final int paise;
  final AmountTone tone;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: muted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AmountText(paise, style: theme.textTheme.headlineLarge, tone: tone),
            const SizedBox(height: AppSpacing.xs),
            Text(
              caption,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ],
        ),
      ),
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
              "Couldn't load your accounts",
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
