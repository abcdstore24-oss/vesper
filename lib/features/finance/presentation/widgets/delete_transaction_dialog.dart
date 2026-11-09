import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/db_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/transactions_dao.dart';

/// How the delete confirmation ended (null = cancelled).
enum DeleteOutcome { deleted, notFound }

/// Opens the delete confirmation for transaction [transactionId]. [summary]
/// is a one-line description of the row and [impactLines] say how each
/// affected account's balance changes. The dialog performs the delete itself,
/// so an error can be shown inside it while it stays open. Returns
/// [DeleteOutcome.deleted] / [DeleteOutcome.notFound], or null if cancelled.
Future<DeleteOutcome?> showDeleteTransactionDialog(
  BuildContext context, {
  required String transactionId,
  required String summary,
  required List<String> impactLines,
}) {
  return showDialog<DeleteOutcome>(
    context: context,
    // Not dismissible by a tap outside: Cancel is the way out, and a delete
    // in flight can't be abandoned half-way.
    barrierDismissible: false,
    builder: (_) => DeleteTransactionDialog(
      transactionId: transactionId,
      summary: summary,
      impactLines: impactLines,
    ),
  );
}

/// "Delete this transaction?" with the per-account balance change. Scrollable
/// (so it fits at 320dp and large text); the buttons never stay disabled
/// after a failure. Deletes through TransactionsDao.delete only.
///
/// Registered in COMPONENTS.md.
class DeleteTransactionDialog extends ConsumerStatefulWidget {
  const DeleteTransactionDialog({
    super.key,
    required this.transactionId,
    required this.summary,
    required this.impactLines,
  });

  final String transactionId;
  final String summary;
  final List<String> impactLines;

  @override
  ConsumerState<DeleteTransactionDialog> createState() =>
      _DeleteTransactionDialogState();
}

class _DeleteTransactionDialogState
    extends ConsumerState<DeleteTransactionDialog> {
  bool _busy = false;
  // Set synchronously at the start of _delete, before any rebuild, so a
  // second tap in the same frame can never start a second delete.
  bool _deleteStarted = false;
  String? _error;

  Future<void> _delete() async {
    if (_deleteStarted) return;
    _deleteStarted = true;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await TransactionsDao(
        ref.read(appDatabaseProvider),
      ).delete(widget.transactionId);
      if (!mounted) return;
      Navigator.of(context).pop(DeleteOutcome.deleted);
    } on TransactionValidationException catch (e) {
      if (!mounted) return;
      if (e.error == TransactionValidationError.notFound) {
        Navigator.of(context).pop(DeleteOutcome.notFound);
        return;
      }
      _fail(switch (e.error) {
        TransactionValidationError.balanceOutOfRange =>
          "Can't delete this: it would make an account balance too large.",
        TransactionValidationError.linkedToSource =>
          "This transaction belongs to Loans or Investments and can't be "
              'deleted here.',
        _ => "Couldn't delete. Please try again.",
      });
    } catch (_) {
      // Deliberately no logging: notes and amounts are user data.
      if (!mounted) return;
      _fail("Couldn't delete. Please try again.");
    }
  }

  /// Shows [message] and re-enables the buttons.
  void _fail(String message) {
    setState(() {
      _busy = false;
      _deleteStarted = false;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final danger =
        (theme.brightness == Brightness.dark ? AppColors.dark : AppColors.light)
            .danger;

    return AlertDialog(
      // The title and content scroll together, so nothing overflows at 320dp
      // or with large text.
      scrollable: true,
      title: const Text('Delete this transaction?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.summary),
          const SizedBox(height: AppSpacing.md),
          for (final line in widget.impactLines) ...[
            Text(line),
            const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.sm),
          const Text("This can't be undone."),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              key: const ValueKey('delete_error'),
              style: theme.textTheme.bodyMedium?.copyWith(color: danger),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          key: const ValueKey('delete_cancel_button'),
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const ValueKey('delete_confirm_button'),
          onPressed: _busy ? null : _delete,
          style: TextButton.styleFrom(foregroundColor: danger),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
