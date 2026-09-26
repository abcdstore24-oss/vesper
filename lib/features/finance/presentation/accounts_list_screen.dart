import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/accounts_dao.dart';
import '../data/transactions_dao.dart';
import '../domain/account_type.dart';
import 'account_form_sheet.dart';

class AccountsListScreen extends ConsumerWidget {
  const AccountsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final balancesAsync = ref.watch(accountBalancesProvider);
    final theme = Theme.of(context);

    return accountsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Couldn't load accounts: $e")),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'No accounts yet. Tap + to add one.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Balances stream can briefly lag behind accounts on first
        // load; treat "not yet loaded" as zero net transactions
        // rather than blocking the whole screen on it.
        final balances = balancesAsync.asData?.value ?? const <String, int>{};

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            final account = items[i];
            final type = AccountType.values.byName(account.type);
            // Live balance: starting balance + signed sum of that
            // account's transactions (Task 2.2). Cents throughout;
            // division to a decimal happens only here, at render.
            final liveBalanceCents = account.startingBalanceCents + (balances[account.id] ?? 0);
            final displayBalance = liveBalanceCents / 100;

            return Card(
              child: ListTile(
                leading: Icon(type.icon, color: theme.colorScheme.onSurfaceVariant),
                title: Text(account.name, style: theme.textTheme.bodyLarge),
                subtitle: Text(
                  '${type.label} · ${account.currency}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                trailing: Text(
                  '${account.currency} ${displayBalance.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: liveBalanceCents < 0 ? theme.colorScheme.error : null,
                  ),
                ),
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AccountFormSheet(existing: account),
                ),
                onLongPress: () => _confirmDelete(context, ref, account),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AccountRow account) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text('This deletes "${account.name}". This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(appDatabaseProvider).deleteAccount(account.id);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } on AccountHasTransactionsException catch (e) {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Can't delete — ${e.count} transaction${e.count == 1 ? '' : 's'} use this account. "
                        'Delete those transactions first.',
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