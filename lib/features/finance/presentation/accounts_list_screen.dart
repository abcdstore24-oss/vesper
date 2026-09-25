import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/accounts_dao.dart';
import '../domain/account_type.dart';
import 'account_form_sheet.dart';

class AccountsListScreen extends ConsumerWidget {
  const AccountsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
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
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            final account = items[i];
            final type = AccountType.values.byName(account.type);
            // Cents -> decimal for display only. All arithmetic and
            // storage stay in integer cents; this division happens at
            // the render boundary, never gets stored or summed further.
            final displayBalance = account.startingBalanceCents / 100;

            return Card(
              child: ListTile(
                leading: Icon(type.icon, color: theme.colorScheme.onSurfaceVariant),
                title: Text(account.name, style: theme.textTheme.bodyLarge),
                subtitle: Text(
                  '${type.label} · ${account.currency}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Text(
                  '${account.currency} ${displayBalance.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: account.startingBalanceCents < 0
                        ? theme.colorScheme.error
                        : null,
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
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(appDatabaseProvider).deleteAccount(account.id);
              Navigator.pop(dialogContext);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}