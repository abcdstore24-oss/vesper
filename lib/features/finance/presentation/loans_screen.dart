import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/loans_dao.dart';
import '../domain/loan_direction.dart';
import 'loan_add_more_sheet.dart';
import 'loan_form_sheet.dart';
import 'loan_repayment_sheet.dart';
import '../data/categories_dao.dart';

class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(categoriesSeedProvider); // NEW: the loan sheets' category pickers need the defaults
    final loansAsync = ref.watch(loansProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Loans & IOUs')),
      body: loansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Couldn't load loans: $e")),
        data: (loansList) {
          if (loansList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'No loans or IOUs yet. Tap + to add one.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: loansList.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) => _LoanTile(loan: loansList[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const LoanFormSheet(),
        ),
        child: const Icon(PhosphorIconsRegular.plus),
      ),
    );
  }
}

class _LoanTile extends ConsumerWidget {
  const _LoanTile({required this.loan});

  final LoanRow loan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final successColor = isDark ? AppColors.dark.success : AppColors.light.success;
    final dangerColor = isDark ? AppColors.dark.danger : AppColors.light.danger;
    final direction = LoanDirection.values.byName(loan.direction);
    // CHANGED this task: now color-coded success (lent, an asset) /
    // danger (borrowed, a liability) — Part 1 kept this neutral
    // specifically because loans didn't affect any total yet; now
    // that they do (this task), color correctly reflects reality
    // rather than misleading (task response).
    final directionColor = direction == LoanDirection.lent ? successColor : dangerColor;
    final outstandingDecimal = (loan.outstandingCents / 100).toStringAsFixed(2);
    final canRepay = loan.outstandingCents > 0;

    return Card(
      child: InkWell(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => LoanFormSheet(existing: loan),
        ),
        onLongPress: () => _confirmDelete(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(PhosphorIconsRegular.handshake, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loan.personName, style: theme.textTheme.bodyLarge),
                        Text(direction.label, style: theme.textTheme.bodyMedium?.copyWith(color: directionColor)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add more',
                    icon: const Icon(PhosphorIconsRegular.plusCircle),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => LoanAddMoreSheet(loan: loan),
                    ),
                  ),
                  IconButton(
                    tooltip: canRepay ? 'Repayment' : 'Nothing outstanding',
                    icon: const Icon(PhosphorIconsRegular.handCoins),
                    onPressed: canRepay
                        ? () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => LoanRepaymentSheet(loan: loan),
                            )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Outstanding',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            outstandingDecimal,
                            style: theme.textTheme.titleMedium?.copyWith(color: directionColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (loan.isSettled)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIconsRegular.checkCircle, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Settled',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete loan?'),
        content: Text(
          'This deletes the record for "${loan.personName}". If you funded it from an '
          'account, that transaction stays — delete it separately from Transactions if '
          "it was entered by mistake. This can't be undone.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(appDatabaseProvider).deleteLoan(loan.id);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } on LoanHasActivityException catch (e) {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Can't delete — ${e.count} recorded ${e.count == 1 ? 'activity' : 'activities'} against this loan.",
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