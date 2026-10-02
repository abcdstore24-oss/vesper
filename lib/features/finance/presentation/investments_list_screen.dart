import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/investment_snapshots_dao.dart';
import '../data/investment_sales_dao.dart';
import '../data/investments_dao.dart';
import '../domain/investment_type.dart';
import 'investment_form_sheet.dart';
import 'investment_sale_history_sheet.dart';
import 'sell_investment_sheet.dart';
import 'update_value_dialog.dart';
import 'buy_more_investment_sheet.dart';

class InvestmentsListScreen extends ConsumerWidget {
  const InvestmentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investmentsAsync = ref.watch(investmentsProvider);
    ref.watch(investmentSnapshotsSeedProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final successColor = isDark ? AppColors.dark.success : AppColors.light.success;
    final dangerColor = isDark ? AppColors.dark.danger : AppColors.light.danger;

    return Scaffold(
      appBar: AppBar(title: const Text('Investments')),
      body: investmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Couldn't load investments: $e")),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'No investments yet. Tap + to add one.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          var totalCostBasis = 0;
          var totalCurrentValue = 0;
          for (final inv in items) {
            totalCostBasis += inv.costBasisCents;
            totalCurrentValue += inv.currentValueCents;
          }
          final totalGain = totalCurrentValue - totalCostBasis;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Portfolio', style: theme.textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _AmountLabel(
                              label: 'Cost basis',
                              cents: totalCostBasis,
                              color: theme.colorScheme.onSurface,
                              valueStyle: theme.textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _AmountLabel(
                              label: 'Current value',
                              cents: totalCurrentValue,
                              color: theme.colorScheme.onSurface,
                              valueStyle: theme.textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _AmountLabel(
                              label: 'Gain/Loss',
                              cents: totalGain,
                              color: totalGain >= 0 ? successColor : dangerColor,
                              signed: true,
                              valueStyle: theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final inv in items)
                _InvestmentTile(investment: inv, successColor: successColor, dangerColor: dangerColor),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const InvestmentFormSheet(),
        ),
        child: const Icon(PhosphorIconsRegular.plus),
      ),
    );
  }
}

class _InvestmentTile extends ConsumerWidget {
  const _InvestmentTile({required this.investment, required this.successColor, required this.dangerColor});

  final InvestmentRow investment;
  final Color successColor;
  final Color dangerColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final type = InvestmentType.values.byName(investment.type);
    final gain = investment.currentValueCents - investment.costBasisCents;
    final isGain = gain >= 0;
    // Sell disabled once ~nothing remains — task response.
    final canSell = investment.quantity > investmentQuantityEpsilon;

    return Card(
      child: InkWell(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => InvestmentFormSheet(existing: investment),
        ),
        onLongPress: () => _confirmDelete(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(type.icon, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(investment.name, style: theme.textTheme.bodyLarge),
                        Text(
                          '${type.label} · ${InvestmentType.formatQuantity(investment.quantity)}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Update value',
                    icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => UpdateValueDialog(investment: investment),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Buy more',
                    icon: const Icon(PhosphorIconsRegular.plusCircle),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => BuyMoreInvestmentSheet(investment: investment),
                    ),
                  ),
                  IconButton(
                    tooltip: canSell ? 'Sell' : 'Nothing left to sell',
                    icon: const Icon(PhosphorIconsRegular.handCoins),
                    onPressed: canSell
                        ? () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => SellInvestmentSheet(investment: investment),
                            )
                        : null,
                  ),
                  IconButton(
                    tooltip: 'Sale history',
                    icon: const Icon(PhosphorIconsRegular.clockCounterClockwise),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => InvestmentSaleHistorySheet(
                        investmentId: investment.id,
                        investmentName: investment.name,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _AmountLabel(
                      label: 'Cost basis',
                      cents: investment.costBasisCents,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _AmountLabel(
                      label: 'Current value',
                      cents: investment.currentValueCents,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _AmountLabel(
                      label: 'Gain/Loss',
                      cents: gain,
                      color: isGain ? successColor : dangerColor,
                      signed: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Updated ${_formatDate(investment.lastUpdatedAt)}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete investment?'),
        content: Text(
          'This permanently erases "${investment.name}" and its entire history — '
          'use Delete only for an entry added by mistake. If you actually owned '
          'and sold this, use Sell instead.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              // Now also catches InvestmentHasSalesException — required
              // addition this task.
              try {
                await ref.read(appDatabaseProvider).deleteInvestment(investment.id);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } on InvestmentHasSalesException catch (e) {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Can't delete — ${e.count} recorded sale${e.count == 1 ? '' : 's'} for this investment.",
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

class _AmountLabel extends StatelessWidget {
  const _AmountLabel({
    required this.label,
    required this.cents,
    required this.color,
    this.signed = false,
    this.valueStyle,
  });

  final String label;
  final int cents;
  final Color color;
  final bool signed;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefix = signed ? (cents >= 0 ? '+' : '-') : '';
    final decimal = (cents.abs() / 100).toStringAsFixed(2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '$prefix$decimal',
            style: (valueStyle ?? theme.textTheme.bodyMedium)?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}