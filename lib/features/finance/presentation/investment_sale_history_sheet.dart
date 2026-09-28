import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/investment_sales_dao.dart';
import '../domain/investment_type.dart';

/// Bottom sheet, not a full screen — task response: this Finance
/// feature has no navigation stack anywhere else (every per-item view
/// is a sheet/dialog), so a route here would be the odd one out.
class InvestmentSaleHistorySheet extends ConsumerWidget {
  const InvestmentSaleHistorySheet({super.key, required this.investmentId, required this.investmentName});

  final String investmentId;
  final String investmentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final successColor = isDark ? AppColors.dark.success : AppColors.light.success;
    final dangerColor = isDark ? AppColors.dark.danger : AppColors.light.danger;
    final salesAsync = ref.watch(investmentSalesProvider(investmentId));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Sale history — $investmentName', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: salesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text("Couldn't load sale history: $e")),
                  data: (sales) {
                    if (sales.isEmpty) {
                      return Center(
                        child: Text(
                          'No sales recorded yet.',
                          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      itemCount: sales.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        final sale = sales[i];
                        final isGain = sale.realizedGainCents >= 0;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_formatDate(sale.soldAt), style: theme.textTheme.bodyMedium),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Sold ${InvestmentType.formatQuantity(sale.quantitySold)}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Proceeds ${(sale.proceedsCents / 100).toStringAsFixed(2)}',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          '${isGain ? '+' : '-'}${(sale.realizedGainCents.abs() / 100).toStringAsFixed(2)}',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: isGain ? successColor : dangerColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}