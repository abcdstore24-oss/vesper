import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/db/db_provider.dart';
import '../../../../core/db/local_user_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/money.dart';
import '../../data/accounts_dao.dart';
import '../../data/accounts_table.dart';
import '../account_delete_impact.dart';
import '../account_display.dart';
import '../providers/accounts_providers.dart';
import 'delete_account_dialog.dart';

/// Opens the add-account sheet, or the edit sheet when [account] is given.
Future<void> showAccountFormSheet(BuildContext context, {AccountRow? account}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AccountFormSheet(account: account),
  );
}

/// Add / edit an account. Saves through [AccountsDao]; the list updates
/// through the existing stream, so nothing here refreshes anything.
///
/// Edit mode also has the account's actions, below Save:
/// - an ACTIVE account: "Archive account" (only at a balance of exactly zero,
///   no confirmation: it is reversible) and "Delete account" (only when no
///   transaction refers to it; asks first, in DeleteAccountDialog);
/// - an ARCHIVED account: "Restore account". Only its NAME can be changed (the
///   type and the starting balance are disabled), so its balance can't change.
/// Where an action is not possible a muted caption says why. The actions are
/// disabled until the balance and the has-transactions answer have loaded.
///
/// Registered in COMPONENTS.md.
class AccountFormSheet extends ConsumerStatefulWidget {
  const AccountFormSheet({super.key, this.account});

  /// The account being edited, or null to add a new one.
  final AccountRow? account;

  @override
  ConsumerState<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<AccountFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late AccountType _type;

  bool _saving = false;
  // Set synchronously at the start of _save, before any rebuild, so a
  // second tap in the same frame can never start a second save.
  bool _saveStarted = false;
  bool _amountTouched = false;

  /// An archive / restore / delete is running. It and Save disable each
  /// other; [_actionStarted] is set synchronously, like [_saveStarted].
  bool _acting = false;
  bool _actionStarted = false;

  String? _nameError;
  String? _amountError;
  String? _formError;

  bool get _isEdit => widget.account != null;
  bool get _isCard => _type == AccountType.creditCard;
  bool get _archived => widget.account?.isArchived ?? false;

  static const String _zeroBalanceCaption =
      'Bring the balance to zero first (for example, transfer the money to '
      'another account) to archive it.';
  static const String _hasTransactionsCaption =
      "This account has transactions, so it can't be deleted. Archive it "
      'instead.';

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _name = TextEditingController(text: account?.name ?? '');
    _type = account?.type ?? AccountType.bank;
    _amount = TextEditingController(
      text: account == null
          ? ''
          : _render(
              account.startingBalance,
              account.type == AccountType.creditCard,
            ),
    );
  }

  /// The amount field's text for a STORED balance, in the meaning of the
  /// chosen type: Money.format without the symbol.
  ///  - non-card: the balance itself (a negative one keeps its minus sign);
  ///  - card: the amount OWED (-stored) when stored is negative, otherwise
  ///    empty (a card with a zero or positive balance has nothing "owed").
  static String _render(int stored, bool asCard) {
    if (asCard) return stored < 0 ? Money.format(-stored, symbol: false) : '';
    return Money.format(stored, symbol: false);
  }

  /// True when the user switched a non-card account to a credit card and has
  /// not typed an amount, while the stored balance is zero or positive. The
  /// field is empty then, and saving would silently drop that balance, so
  /// Save asks for the amount owed (0 if none) instead.
  bool get _needsOwedAmount {
    final account = widget.account;
    return account != null &&
        _isCard &&
        account.type != AccountType.creditCard &&
        !_amountTouched &&
        account.startingBalance >= 0;
  }

  /// Chooses an account type. In edit mode, when that switches between card
  /// and non-card and the amount field is untouched, the field is re-rendered
  /// from the STORED balance in the new meaning, so the balance never flips
  /// sign by accident. Switching back to the original type restores the
  /// original prefill. A touched field keeps the typed text.
  void _selectType(AccountType type) {
    final account = widget.account;
    final cardnessChanges = (type == AccountType.creditCard) != _isCard;
    setState(() {
      _type = type;
      _amountError = null;
      if (account != null && !_amountTouched && cardnessChanges) {
        _amount.text = _render(account.startingBalance, _isCard);
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  /// Parses the amount field with Money.parse only. `valid: false` means
  /// the text is not a usable amount. Empty means 0. For a card the typed
  /// (unsigned) amount is the amount owed and is stored negative.
  ({bool valid, int paise}) _parseAmount() {
    final text = _amount.text.trim();
    if (text.isEmpty) return (valid: true, paise: 0);
    final parsed = Money.parse(text, allowNegative: !_isCard);
    if (parsed == null) return (valid: false, paise: 0);
    return (valid: true, paise: _isCard ? -parsed : parsed);
  }

  Future<void> _save() async {
    if (_saveStarted || _actionStarted) return;
    _saveStarted = true;

    final name = _name.text.trim();
    final amount = _parseAmount();

    final nameError = name.isEmpty ? 'Enter a name' : null;
    final amountError = _needsOwedAmount
        ? 'Enter the amount owed (0 if none)'
        : (amount.valid
              ? null
              : 'Enter an amount like 1250 or 1250.50 (up to 2 decimals)');
    if (nameError != null || amountError != null) {
      setState(() {
        _nameError = nameError;
        _amountError = amountError;
        _formError = null;
      });
      _saveStarted = false;
      return;
    }

    setState(() {
      _saving = true;
      _nameError = null;
      _amountError = null;
      _formError = null;
    });

    try {
      final dao = AccountsDao(ref.read(appDatabaseProvider));
      final existing = widget.account;
      if (existing == null) {
        final userId = await ref.read(localUserIdProvider.future);
        await dao.insert(
          userId: userId,
          name: name,
          type: _type,
          startingBalancePaise: amount.paise,
        );
      } else {
        // Only touch the balance if the user typed in the amount field. An
        // untouched field is either the stored balance (re-rendered for the
        // new type, see _selectType) or empty, so the stored balance is left
        // exactly as it is. This also keeps a value the form can't show (a
        // card with a positive balance) from being silently overwritten.
        await dao.update(
          existing.id,
          name: name,
          type: _type,
          startingBalancePaise: _amountTouched ? amount.paise : null,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on AccountValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveStarted = false;
        switch (e.error) {
          case AccountValidationError.emptyName:
            _nameError = 'Enter a name';
          case AccountValidationError.nameTooLong:
            _nameError = 'Keep it to 40 characters or fewer';
          case AccountValidationError.duplicateName:
            _nameError = 'You already have an account with this name';
          default:
            // notFound / balanceNotZero / hasTransactions come from the
            // actions, not from Save.
            _formError = "Couldn't save. Please try again.";
        }
      });
    } catch (_) {
      // Deliberately no logging: names and amounts are user data.
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveStarted = false;
        _formError = "Couldn't save. Please try again.";
      });
    }
  }

  /// Runs archive / restore, then closes the sheet with a SnackBar. A failure
  /// leaves the sheet open with an inline message and everything re-enabled.
  Future<void> _runAction(
    Future<void> Function(AccountsDao dao) run,
    String successMessage,
  ) async {
    if (_actionStarted || _saveStarted) return;
    _actionStarted = true;
    setState(() {
      _acting = true;
      _nameError = null;
      _amountError = null;
      _formError = null;
    });

    // Captured before the sheet closes, so the SnackBar can still be shown.
    final messenger = ScaffoldMessenger.of(context);
    try {
      await run(AccountsDao(ref.read(appDatabaseProvider)));
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } on AccountValidationException catch (e) {
      if (!mounted) return;
      switch (e.error) {
        case AccountValidationError.notFound:
          Navigator.of(context).pop();
          messenger.showSnackBar(
            const SnackBar(content: Text('That account no longer exists')),
          );
        case AccountValidationError.balanceNotZero:
          _failAction(_zeroBalanceCaption);
        default:
          _failAction("Couldn't save. Please try again.");
      }
    } catch (_) {
      // Deliberately no logging: names are user data.
      if (!mounted) return;
      _failAction("Couldn't save. Please try again.");
    }
  }

  void _failAction(String message) {
    setState(() {
      _acting = false;
      _actionStarted = false;
      _formError = message;
    });
  }

  /// Delete: asks first (DeleteAccountDialog), which deletes itself.
  Future<void> _confirmDelete() async {
    final account = widget.account;
    if (account == null || _actionStarted || _saveStarted) return;
    _actionStarted = true;
    setState(() {
      _acting = true;
      _formError = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final outcome = await showDeleteAccountDialog(
      context,
      accountId: account.id,
      accountName: account.name,
      impactLines: deleteAccountImpactLines(
        type: account.type,
        startingBalancePaise: account.startingBalance,
      ),
    );
    if (!mounted) return;
    if (outcome == null) {
      setState(() {
        _acting = false;
        _actionStarted = false;
      });
      return;
    }
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          outcome == DeleteAccountOutcome.deleted
              ? 'Account deleted'
              : 'That account no longer exists',
        ),
      ),
    );
  }

  /// Edit mode: the actions area below Save.
  List<Widget> _actionWidgets(ThemeData theme) {
    final account = widget.account;
    if (account == null) return const [];

    final muted = theme.colorScheme.onSurfaceVariant;
    final danger =
        (theme.brightness == Brightness.dark ? AppColors.dark : AppColors.light)
            .danger;
    final accounts = ref.watch(accountsWithBalanceProvider).valueOrNull;
    int? balance;
    for (final a in accounts ?? const []) {
      if (a.account.id == account.id) balance = a.balancePaise;
    }
    final hasTransactions = ref
        .watch(accountHasTransactionsProvider(account.id))
        .valueOrNull;

    // Disabled until both answers are in, and while anything is running.
    final ready = balance != null && hasTransactions != null;
    final enabled = ready && !_saving && !_acting;
    final caption = theme.textTheme.bodyMedium?.copyWith(color: muted);

    Widget gap() => const SizedBox(height: AppSpacing.sm);

    if (_archived) {
      return [
        gap(),
        TextButton(
          key: const ValueKey('acct_restore_button'),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface,
          ),
          onPressed: enabled
              ? () => _runAction(
                  (dao) => dao.restore(account.id),
                  'Account restored',
                )
              : null,
          child: const Text('Restore account'),
        ),
      ];
    }

    final canArchive = balance == 0;
    return [
      gap(),
      TextButton(
        key: const ValueKey('acct_archive_button'),
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
        ),
        onPressed: enabled && canArchive
            ? () => _runAction(
                (dao) => dao.archive(account.id),
                'Account archived',
              )
            : null,
        child: const Text('Archive account'),
      ),
      if (ready && !canArchive)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            _zeroBalanceCaption,
            key: const ValueKey('acct_archive_caption'),
            textAlign: TextAlign.center,
            style: caption,
          ),
        ),
      // Delete is offered only for an account no transaction refers to; while
      // loading it is shown disabled.
      if (!ready || hasTransactions == false) ...[
        gap(),
        TextButton(
          key: const ValueKey('acct_delete_button'),
          style: TextButton.styleFrom(foregroundColor: danger),
          onPressed: enabled ? _confirmDelete : null,
          child: const Text('Delete account'),
        ),
      ] else ...[
        gap(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            _hasTransactionsCaption,
            key: const ValueKey('acct_delete_caption'),
            textAlign: TextAlign.center,
            style: caption,
          ),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Padding(
      // Keeps the button above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? 'Edit account' : 'Add account',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              key: const ValueKey('account_name_field'),
              controller: _name,
              autofocus: !_isEdit,
              enabled: !_saving && !_acting,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Name',
                errorText: _nameError,
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            if (_archived) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'This account is archived, so only its name can be changed.',
                key: const ValueKey('acct_archived_caption'),
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Type',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final type in AccountType.values)
                  ChoiceChip(
                    avatar: Icon(accountTypeIcon(type), size: 18),
                    label: Text(accountTypeLabel(type)),
                    selected: _type == type,
                    onSelected: (_saving || _acting || _archived)
                        ? null
                        : (_) => _selectType(type),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              key: const ValueKey('account_amount_field'),
              controller: _amount,
              enabled: !_saving && !_acting && !_archived,
              keyboardType: TextInputType.numberWithOptions(
                decimal: true,
                signed: !_isCard,
              ),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: _isCard ? 'Amount owed' : 'Opening balance',
                helperText: _isCard
                    ? 'Leave empty if you owe nothing'
                    : 'Amount in rupees',
                errorText: _amountError,
              ),
              onChanged: (_) {
                _amountTouched = true;
                if (_amountError != null) setState(() => _amountError = null);
              },
              onSubmitted: (_) => _save(),
            ),
            if (_formError != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _formError!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: (_saving || _acting) ? null : _save,
              child: Text(_isEdit ? 'Save changes' : 'Add account'),
            ),
            ..._actionWidgets(theme),
          ],
        ),
      ),
    );
  }
}
