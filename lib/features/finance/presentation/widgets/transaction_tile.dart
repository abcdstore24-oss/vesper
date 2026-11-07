import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/amount_text.dart';
import '../../data/transaction_queries.dart';
import '../transaction_display.dart';

/// One transaction as a descriptive row: icon circle, title, subtitle, and a
/// right column with the amount and, under it, the date (unless [showDate] is
/// false). Not tappable (editing comes later). Named TransactionTile because
/// TransactionRow is Drift's data class.
///
/// The title and subtitle wrap to at most two lines (ellipsis after that).
/// The right column takes at most half the row; the amount and the date are
/// never truncated: beyond that width they scale down.
///
/// Registered in COMPONENTS.md.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.item,
    this.now,
    this.showDate = true,
  });

  final TransactionListItem item;

  /// For tests: decides "Today" / "Yesterday" in the subtitle.
  final DateTime? now;

  /// Show the date label under the amount. The full Transactions list passes
  /// false because its date header already carries the date.
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final display = transactionDisplay(item, now: now);

    return Padding(
      key: ValueKey('transaction-tile-${item.transaction.id}'),
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
                  // Neutral: category colours are reserved for charts.
                  color: palette.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  display.icon,
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
                    Text(
                      display.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge,
                    ),
                    Text(
                      display.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // At most half the row; beyond that the amount scales down.
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
                    if (showDate)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          display.dateLabel,
                          maxLines: 1,
                          softWrap: false,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
