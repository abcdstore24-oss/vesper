import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/db/local_user_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/dashboard_card.dart';
import '../data/transactions_table.dart';
import 'providers/transactions_providers.dart';
import 'open_transaction.dart';
import 'transaction_grouping.dart';
import 'widgets/transaction_form_sheet.dart';
import 'widgets/transaction_tile.dart';

/// Every transaction, newest first, grouped under date headers, with filter
/// chips (All / Expense / Income / Transfer) and a + button for the add
/// sheet. Tapping a row edits it (a locked row is explained instead) through
/// openTransaction; delete is a later task.
///
/// The chip row is always visible; only the list area shows loading or an
/// error. The filter is local to this screen and runs in SQL. The list is
/// built lazily (ListView.builder). No pagination yet: every row of the
/// chosen filter is loaded in memory.
///
/// Registered in COMPONENTS.md.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  /// Bottom padding so the FAB never covers the last row.
  static const double listBottomPadding = 96;

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  /// null = All.
  TransactionType? _filter;

  static const _chips = <(String, TransactionType?)>[
    ('All', null),
    ('Expense', TransactionType.expense),
    ('Income', TransactionType.income),
    ('Transfer', TransactionType.transfer),
  ];

  static String _chipKey(TransactionType? type) =>
      'transactions-filter-${type?.name ?? 'all'}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = _filter;
    final async = ref.watch(allTransactionsProvider(filter));

    final Widget list;
    if (async.hasError) {
      list = _ErrorView(
        onRetry: () {
          ref.invalidate(localUserIdProvider);
          ref.invalidate(allTransactionsProvider(filter));
        },
      );
    } else if (async.valueOrNull == null) {
      list = const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else {
      final items = async.requireValue;
      list = items.isEmpty
          ? _EmptyView(filter: filter)
          : _GroupedList(entries: groupTransactionsByDate(items));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      floatingActionButton: FloatingActionButton(
        // No hero: the Finance home underneath has its own FAB.
        heroTag: null,
        tooltip: 'Add transaction',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        onPressed: () => showTransactionFormSheet(context),
        child: const Icon(PhosphorIconsRegular.plus),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final (label, type) in _chips)
                  ChoiceChip(
                    key: ValueKey(_chipKey(type)),
                    label: Text(label),
                    selected: _filter == type,
                    onSelected: (_) => setState(() => _filter = type),
                  ),
              ],
            ),
          ),
          Expanded(child: list),
        ],
      ),
    );
  }
}

String _emptyFilterMessage(TransactionType type) => switch (type) {
  TransactionType.expense => 'No expense transactions',
  TransactionType.income => 'No income transactions',
  TransactionType.transfer => 'No transfers',
};

/// The lazy list: date headers and one Card per row.
class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.entries});

  final List<TransactionListEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        TransactionsScreen.listBottomPadding,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        switch (entries[index]) {
          case TransactionDateHeader(:final label):
            // AppSpacing.xs lines the header up with the cards (default 4px
            // margin).
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.xs,
              ),
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          case TransactionRowEntry(:final item):
            return Card(
              // Clips the tap ripple to the rounded corners.
              clipBehavior: Clip.antiAlias,
              child: TransactionTile(
                item: item,
                showDate: false,
                onTap: () => openTransaction(context, item),
              ),
            );
        }
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.filter});

  final TransactionType? filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = filter;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        TransactionsScreen.listBottomPadding,
      ),
      children: [
        if (type == null)
          DashboardCard.emptyState(
            icon: PhosphorIconsRegular.receipt,
            title: 'No transactions yet',
            message: 'Tap + to add your first one.',
          )
        else
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              _emptyFilterMessage(type),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
