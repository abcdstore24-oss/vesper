import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/db/db_provider.dart';
import '../../../../core/db/local_user_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/money.dart';
import '../../data/accounts_dao.dart';
import '../../data/accounts_table.dart';
import '../account_display.dart';

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

  String? _nameError;
  String? _amountError;
  String? _formError;

  bool get _isEdit => widget.account != null;
  bool get _isCard => _type == AccountType.creditCard;

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
    if (_saveStarted) return;
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
        _nameError = switch (e.error) {
          AccountValidationError.emptyName => 'Enter a name',
          AccountValidationError.nameTooLong =>
            'Keep it to 40 characters or fewer',
          AccountValidationError.duplicateName =>
            'You already have an account with this name',
        };
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
              enabled: !_saving,
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
                    onSelected: _saving ? null : (_) => _selectType(type),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              key: const ValueKey('account_amount_field'),
              controller: _amount,
              enabled: !_saving,
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
              onPressed: _saving ? null : _save,
              child: Text(_isEdit ? 'Save changes' : 'Add account'),
            ),
          ],
        ),
      ),
    );
  }
}
