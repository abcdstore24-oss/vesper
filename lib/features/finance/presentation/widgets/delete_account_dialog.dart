import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/db_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/accounts_dao.dart';

/// How the account delete confirmation ended (null = cancelled).
enum DeleteAccountOutcome { deleted, notFound }

/// Opens the delete confirmation for account [accountId]. [accountName] is
/// shown first (it may be 40 characters, so it wraps) and [impactLines] say
/// what disappears. The dialog performs the delete itself, so an error can be
/// shown inside it while it stays open.
Future<DeleteAccountOutcome?> showDeleteAccountDialog(
  BuildContext context, {
  required String accountId,
  required String accountName,
  required List<String> impactLines,
}) {
  return showDialog<DeleteAccountOutcome>(
    context: context,
    // Cancel is the way out; a delete in flight can't be abandoned half-way.
    barrierDismissible: false,
    builder: (_) => DeleteAccountDialog(
      accountId: accountId,
      accountName: accountName,
      impactLines: impactLines,
    ),
  );
}

/// "Delete this account?" with what disappears. Scrollable (fits at 320dp and
/// with large text); the buttons never stay disabled after a failure. Deletes
/// through AccountsDao.delete only, which refuses an account that has
/// transactions (shown inside the dialog).
///
/// Registered in COMPONENTS.md.
class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({
    super.key,
    required this.accountId,
    required this.accountName,
    required this.impactLines,
  });

  final String accountId;
  final String accountName;
  final List<String> impactLines;

  @override
  ConsumerState<DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
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
      await AccountsDao(ref.read(appDatabaseProvider)).delete(widget.accountId);
      if (!mounted) return;
      Navigator.of(context).pop(DeleteAccountOutcome.deleted);
    } on AccountValidationException catch (e) {
      if (!mounted) return;
      switch (e.error) {
        case AccountValidationError.notFound:
          Navigator.of(context).pop(DeleteAccountOutcome.notFound);
        case AccountValidationError.hasTransactions:
          _fail(
            "This account now has transactions, so it can't be deleted. "
            'Archive it instead.',
          );
        default:
          _fail("Couldn't delete. Please try again.");
      }
    } catch (_) {
      // Deliberately no logging: names are user data.
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
      // Title and content scroll together: nothing overflows at 320dp or with
      // large text.
      scrollable: true,
      title: const Text('Delete this account?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.accountName, style: theme.textTheme.titleMedium),
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
              key: const ValueKey('delete_account_error'),
              style: theme.textTheme.bodyMedium?.copyWith(color: danger),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          key: const ValueKey('delete_account_cancel_button'),
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const ValueKey('delete_account_confirm_button'),
          onPressed: _busy ? null : _delete,
          style: TextButton.styleFrom(foregroundColor: danger),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
