import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/db/db_provider.dart';
import '../../../../core/db/local_user_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/picker_sheet.dart';
import '../../data/accounts_table.dart';
import '../../data/categories_table.dart';
import '../../data/transaction_queries.dart';
import '../../data/transactions_dao.dart';
import '../../data/transactions_table.dart';
import '../account_display.dart';
import '../category_display.dart';
import '../providers/accounts_providers.dart';
import '../providers/transactions_providers.dart';
import '../transaction_delete_impact.dart';
import '../transaction_display.dart';
import 'account_form_sheet.dart';
import 'delete_transaction_dialog.dart';

/// With MORE than this many active accounts, the account choices (From, and
/// To for transfers) become a picker field instead of chips.
const int accountChipsMax = 4;

/// Opens the add-transaction sheet, or, with [existing], the same sheet in
/// edit mode pre-filled from that row.
Future<void> showTransactionFormSheet(
  BuildContext context, {
  TransactionListItem? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => TransactionFormSheet(existing: existing),
  );
}

/// Records an expense, income or transfer. Saves through [TransactionsDao];
/// the Finance home updates through its streams, so nothing here refreshes
/// anything.
///
/// With [existing] it edits that row instead (title "Edit transaction",
/// button "Save changes", saved through TransactionsDao.update):
/// - the amount is pre-filled through Money (plain digits, no symbol);
/// - the date keeps the row's exact occurred_at unless the user picks one;
/// - the row's current category and accounts are shown even if archived
///   (marked "archived"); archived items are offered only in the slot they
///   already occupy, never as a choice for anything else.
///
/// Registered in COMPONENTS.md.
class TransactionFormSheet extends ConsumerStatefulWidget {
  const TransactionFormSheet({super.key, this.existing});

  /// The row being edited; null = add mode.
  final TransactionListItem? existing;

  @override
  ConsumerState<TransactionFormSheet> createState() =>
      _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _note = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String? _categoryId;
  String? _fromId;
  String? _toId;

  /// The chosen calendar day (local, time of day ignored). Never after today.
  late DateTime _date;

  /// Edit mode: true once the user has picked a date. Until then the row's
  /// original occurred_at is kept exactly.
  bool _dateTouched = false;

  bool _saving = false;

  /// Edit mode: the delete confirmation is open.
  bool _deleting = false;
  // Set synchronously at the start of _save, before any rebuild, so a second
  // tap in the same frame can never start a second save.
  bool _saveStarted = false;

  String? _amountError;
  String? _categoryError;
  String? _fromError;
  String? _toError;
  String? _dateError;
  String? _noteError;
  String? _formError;

  bool get _isEdit => widget.existing != null;

  bool get _isTransfer => _type == TransactionType.transfer;

  CategoryKind get _categoryKind => _type == TransactionType.income
      ? CategoryKind.income
      : CategoryKind.expense;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing == null) {
      final now = DateTime.now();
      _date = DateTime(now.year, now.month, now.day);
      return;
    }
    final t = existing.transaction;
    _type = t.type;
    _categoryId = t.categoryId;
    _fromId = t.accountId;
    _toId = t.toAccountId;
    // Money.format always gives exactly 2 decimals; dropping the grouping
    // commas leaves plain digits that Money.parse reads back exactly.
    _amount.text = Money.format(t.amount, symbol: false).replaceAll(',', '');
    _note.text = t.note ?? '';
    final at = t.occurredAt.isUtc ? t.occurredAt.toLocal() : t.occurredAt;
    _date = DateTime(at.year, at.month, at.day);
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _selectType(TransactionType type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      // Expense and income have different categories, so the choice is
      // cleared whenever the type changes.
      _categoryId = null;
      _categoryError = null;
      _toError = null;
      if (type != TransactionType.transfer) _toId = null;
    });
  }

  void _selectFrom(String id) {
    setState(() {
      _fromId = id;
      _fromError = null;
      // "To" can't be the same account as "From".
      if (_toId == id) _toId = null;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(today) ? today : _date,
      firstDate: DateTime(2000, 1, 1),
      lastDate: today,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day);
      _dateTouched = true;
      _dateError = null;
    });
  }

  Future<void> _save() async {
    if (_saveStarted) return;
    _saveStarted = true;

    final text = _amount.text.trim();
    final parsed = text.isEmpty
        ? null
        : Money.parse(text, allowNegative: false);
    final amountError = parsed == null
        ? 'Enter an amount like 1250 or 1250.50 (up to 2 decimals)'
        : (parsed == 0 ? 'Enter an amount greater than 0' : null);
    final categoryError = !_isTransfer && _categoryId == null
        ? 'Choose a category'
        : null;
    final fromError = _fromId == null ? 'Choose an account' : null;
    final toError = _isTransfer && _toId == null ? 'Choose an account' : null;

    if (amountError != null ||
        categoryError != null ||
        fromError != null ||
        toError != null) {
      setState(() {
        _amountError = amountError;
        _categoryError = categoryError;
        _fromError = fromError;
        _toError = toError;
        _formError = null;
      });
      _saveStarted = false;
      return;
    }

    setState(() {
      _saving = true;
      _amountError = null;
      _categoryError = null;
      _fromError = null;
      _toError = null;
      _dateError = null;
      _noteError = null;
      _formError = null;
    });

    try {
      final existing = widget.existing;
      if (existing == null) {
        final userId = await ref.read(localUserIdProvider.future);
        await TransactionsDao(ref.read(appDatabaseProvider)).insert(
          userId: userId,
          accountId: _fromId!,
          type: _type,
          amountPaise: parsed!,
          categoryId: _isTransfer ? null : _categoryId,
          toAccountId: _isTransfer ? _toId : null,
          note: _note.text,
          occurredAt: AppDates.occurredAtFor(_date, DateTime.now()),
        );
      } else {
        await TransactionsDao(ref.read(appDatabaseProvider)).update(
          existing.transaction.id,
          accountId: _fromId!,
          type: _type,
          amountPaise: parsed!,
          categoryId: _isTransfer ? null : _categoryId,
          toAccountId: _isTransfer ? _toId : null,
          note: _note.text,
          // Untouched date: keep the stored moment exactly (resetting it to
          // 12:00 or "now" would reorder the row).
          occurredAt: _dateTouched
              ? AppDates.occurredAtFor(_date, DateTime.now())
              : existing.transaction.occurredAt,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on TransactionValidationException catch (e) {
      if (!mounted) return;
      if (_isEdit && e.error == TransactionValidationError.notFound) {
        // The row was removed meanwhile: close, and say so.
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('That transaction no longer exists')),
        );
        return;
      }
      setState(() {
        _saving = false;
        _saveStarted = false;
        switch (e.error) {
          case TransactionValidationError.invalidAmount:
            _amountError = 'Enter an amount greater than 0';
          case TransactionValidationError.categoryRequired:
          case TransactionValidationError.categoryInvalid:
            _categoryError = 'Choose a category';
          case TransactionValidationError.accountNotFound:
            _fromError = 'Choose an account';
          case TransactionValidationError.toAccountNotFound:
            _toError = 'Choose an account';
          case TransactionValidationError.sameAccount:
            _toError = 'Choose two different accounts';
          case TransactionValidationError.accountArchived:
            if (_isEdit) {
              _markArchivedAccounts();
            } else {
              _fromError = 'That account is archived';
            }
          case TransactionValidationError.noteTooLong:
            _noteError = 'Keep the note to 100 characters or fewer';
          case TransactionValidationError.futureDate:
            _dateError = "The date can't be in the future";
          case TransactionValidationError.balanceOutOfRange:
            _formError = 'That would make an account balance too large';
          case TransactionValidationError.linkedToSource:
            _formError = _isEdit
                ? "This transaction belongs to Loans or Investments and "
                      "can't be edited here."
                : "Couldn't save. Please try again.";
          case TransactionValidationError.categoryNotAllowed:
          case TransactionValidationError.sourceIncomplete:
          case TransactionValidationError.notFound:
            _formError = "Couldn't save. Please try again.";
        }
      });
    } catch (_) {
      // Deliberately no logging: notes and amounts are user data.
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveStarted = false;
        _formError = "Couldn't save. Please try again.";
      });
    }
  }

  /// Edit mode: asks to delete the STORED row (not unsaved edits). The
  /// confirmation says how each account's balance changes; on success the
  /// sheet closes and a SnackBar says so.
  Future<void> _confirmDelete() async {
    final existing = widget.existing;
    final all = ref.read(accountsWithBalanceProvider).valueOrNull;
    // The button is disabled until the accounts have loaded; this is only a
    // guard.
    if (existing == null || all == null || _saving || _deleting) return;
    final t = existing.transaction;

    DeleteImpactAccount accountFor(String id, String fallbackName) {
      for (final a in all) {
        if (a.account.id == id) {
          return DeleteImpactAccount(a.account.name, a.account.type);
        }
      }
      return DeleteImpactAccount(fallbackName, AccountType.other);
    }

    final toId = t.toAccountId;
    final lines = deleteImpactLines(
      type: t.type,
      amountPaise: t.amount,
      from: accountFor(t.accountId, existing.accountName),
      to: toId == null
          ? null
          : accountFor(toId, existing.toAccountName ?? 'Unknown account'),
    );
    final summary =
        '${transactionDisplay(existing).title} \u00B7 '
        '${Money.format(t.amount)}';

    // Captured before the sheet closes, so the SnackBar can still be shown.
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _deleting = true);
    final outcome = await showDeleteTransactionDialog(
      context,
      transactionId: t.id,
      summary: summary,
      impactLines: lines,
    );
    if (!mounted) return;
    if (outcome == null) {
      setState(() => _deleting = false);
      return;
    }
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          outcome == DeleteOutcome.deleted
              ? 'Transaction deleted'
              : 'That transaction no longer exists',
        ),
      ),
    );
  }

  /// Edit mode: the DAO said an account is archived. Say which field, and
  /// ask for another account (never a silent failure). Call inside setState.
  void _markArchivedAccounts() {
    const message = 'That account is archived. Choose another account.';
    final all = ref.read(accountsWithBalanceProvider).valueOrNull;
    bool archived(String? id) =>
        all?.any((a) => a.account.id == id && a.account.isArchived) ?? false;
    final fromArchived = archived(_fromId);
    final toArchived = _isTransfer && archived(_toId);
    if (toArchived) _toError = message;
    if (fromArchived || !toArchived) _fromError = message;
  }

  /// An account name, marked when it is archived (edit mode only ever shows
  /// an archived account where the row already uses it).
  static String _accountLabel(AccountRow a) =>
      a.isArchived ? '${a.name} (archived)' : a.name;

  /// Edit mode: the row's current category when it is archived (so not in
  /// the active list) and the type is unchanged; null otherwise.
  ({String id, String name, String? icon})? _keptArchivedCategory(
    List<CategoryRow> active,
  ) {
    final existing = widget.existing;
    if (existing == null) return null;
    final t = existing.transaction;
    final id = t.categoryId;
    final name = existing.categoryName;
    if (id == null || name == null) return null;
    if (t.type == TransactionType.transfer || _type != t.type) return null;
    if (active.any((c) => c.id == id)) return null;
    return (id: id, name: name, icon: existing.categoryIcon);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accounts = ref.watch(activeAccountsProvider);

    final Widget content;
    if (accounts.hasError) {
      content = Text(
        "Couldn't load your accounts",
        style: theme.textTheme.bodyLarge,
      );
    } else if (accounts.valueOrNull == null) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (accounts.requireValue.isEmpty) {
      content = _buildNoAccounts(theme);
    } else {
      content = _buildForm(theme, accounts.requireValue);
    }

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
              _isEdit ? 'Edit transaction' : 'Add transaction',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            content,
          ],
        ),
      ),
    );
  }

  void _selectCategory(String id) {
    setState(() {
      _categoryId = id;
      _categoryError = null;
    });
  }

  Future<void> _pickCategory(
    List<CategoryRow> categories,
    ({String id, String name, String? icon})? kept,
  ) async {
    final picked = await showPickerSheet<String>(
      context,
      title: 'Category',
      items: [
        if (kept != null)
          PickerItem<String>(
            value: kept.id,
            title: '${kept.name} (archived)',
            icon: categoryIcon(kept.icon),
          ),
        for (final c in categories)
          PickerItem<String>(
            value: c.id,
            title: c.name,
            icon: categoryIcon(c.icon),
          ),
      ],
      selected: _categoryId,
    );
    if (picked == null || !mounted) return;
    _selectCategory(picked);
  }

  Future<void> _pickAccount({
    required String title,
    required List<AccountRow> choices,
    required String? selectedId,
    required bool isFrom,
  }) async {
    final picked = await showPickerSheet<String>(
      context,
      title: title,
      items: [
        for (final a in choices)
          PickerItem<String>(
            value: a.id,
            title: _accountLabel(a),
            subtitle: accountTypeLabel(a.type),
            icon: accountTypeIcon(a.type),
          ),
      ],
      selected: selectedId,
    );
    if (picked == null || !mounted) return;
    if (isFrom) {
      _selectFrom(picked);
    } else {
      setState(() {
        _toId = picked;
        _toError = null;
      });
    }
  }

  Widget _label(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
  );

  Widget _fieldError(ThemeData theme, String? text) => text == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        );

  Widget _buildNoAccounts(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Add an account before recording transactions.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          onPressed: () => showAccountFormSheet(context),
          child: const Text('Add account'),
        ),
      ],
    );
  }

  Widget _buildForm(ThemeData theme, List<AccountRow> accounts) {
    final muted = theme.colorScheme.onSurfaceVariant;
    final existing = widget.existing;
    // Editing a transfer keeps Transfer available even if archived accounts
    // leave fewer than two active ones.
    final canTransfer =
        accounts.length >= 2 ||
        existing?.transaction.type == TransactionType.transfer;

    // Edit mode: an archived account the row already uses stays selectable in
    // the slot it occupies (From / To), and nowhere else.
    final allAccounts = _isEdit
        ? ref.watch(accountsWithBalanceProvider).valueOrNull
        : null;
    AccountRow? archivedRow(String? id) {
      if (id == null || allAccounts == null) return null;
      for (final a in allAccounts) {
        if (a.account.id == id && a.account.isArchived) return a.account;
      }
      return null;
    }

    final keptFrom = archivedRow(existing?.transaction.accountId);
    final keptTo = archivedRow(existing?.transaction.toAccountId);
    final fromChoices = [...accounts, ?keptFrom];
    final toPool = [...accounts, ?keptTo];

    // Keep the choices consistent with the accounts that exist now.
    if (_type == TransactionType.transfer && !canTransfer) {
      _type = TransactionType.expense;
    }
    if (!fromChoices.any((a) => a.id == _fromId)) _fromId = accounts.first.id;
    if (_toId != null &&
        (_toId == _fromId || !toPool.any((a) => a.id == _toId))) {
      _toId = null;
    }

    final categories = _isTransfer
        ? null
        : ref.watch(categoriesByKindProvider(_categoryKind));
    final activeCategories = categories?.valueOrNull;
    final keptCategory = activeCategories == null
        ? null
        : _keptArchivedCategory(activeCategories);
    final noCategories =
        categories != null &&
        categories.hasValue &&
        categories.requireValue.isEmpty &&
        keptCategory == null;

    final fromLabel = switch (_type) {
      TransactionType.expense => 'Paid from',
      TransactionType.income => 'Received in',
      TransactionType.transfer => 'From',
    };
    final saveLabel = _isEdit
        ? 'Save changes'
        : switch (_type) {
            TransactionType.expense => 'Add expense',
            TransactionType.income => 'Add income',
            TransactionType.transfer => 'Add transfer',
          };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 2. Type
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _typeChip(
              TransactionType.expense,
              'Expense',
              PhosphorIconsRegular.arrowUpRight,
              enabled: true,
            ),
            _typeChip(
              TransactionType.income,
              'Income',
              PhosphorIconsRegular.arrowDownLeft,
              enabled: true,
            ),
            _typeChip(
              TransactionType.transfer,
              'Transfer',
              PhosphorIconsRegular.arrowsLeftRight,
              enabled: canTransfer,
            ),
          ],
        ),
        if (!canTransfer) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add a second account to transfer',
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),

        // 3. Amount
        TextField(
          key: const ValueKey('tx_amount_field'),
          controller: _amount,
          enabled: !_saving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Amount',
            helperText: 'Amount in rupees',
            errorText: _amountError,
          ),
          onChanged: (_) {
            if (_amountError != null) setState(() => _amountError = null);
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // 4. Category (expense / income only): one picker field, plus
        // one-tap chips for the most recently used.
        if (!_isTransfer) ...[
          _buildCategorySection(theme, categories!, keptCategory),
          const SizedBox(height: AppSpacing.lg),
        ],

        // 5. Account(s): chips for a few, a picker field for many.
        ..._accountFields(
          theme,
          accounts,
          fromLabel,
          fromChoices: fromChoices,
          toPool: toPool,
        ),
        const SizedBox(height: AppSpacing.lg),

        // 6. Date
        InkWell(
          key: const ValueKey('tx_date_field'),
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: _saving ? null : _pickDate,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Date',
              errorText: _dateError,
              suffixIcon: Icon(
                PhosphorIconsRegular.calendarBlank,
                color: muted,
              ),
            ),
            child: Text(
              AppDates.format(_date),
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 7. Note
        TextField(
          key: const ValueKey('tx_note_field'),
          controller: _note,
          enabled: !_saving,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Note (optional)',
            hintText: 'e.g. Electricity bill',
            errorText: _noteError,
          ),
          onChanged: (_) {
            if (_noteError != null) setState(() => _noteError = null);
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

        // 8. Save
        ElevatedButton(
          onPressed: (_saving || _deleting || noCategories) ? null : _save,
          child: Text(saveLabel),
        ),

        // 9. Delete (edit mode only). A TextButton, so Save stays the only
        // ElevatedButton. Disabled while saving or deleting, and until the
        // accounts the confirmation describes have loaded.
        if (_isEdit) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            key: const ValueKey('tx_delete_button'),
            style: TextButton.styleFrom(
              foregroundColor:
                  (theme.brightness == Brightness.dark
                          ? AppColors.dark
                          : AppColors.light)
                      .danger,
            ),
            onPressed: (_saving || _deleting || allAccounts == null)
                ? null
                : _confirmDelete,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(PhosphorIconsRegular.trash, size: 20),
                const SizedBox(width: AppSpacing.sm),
                const Flexible(
                  child: Text(
                    'Delete transaction',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _typeChip(
    TransactionType type,
    String name,
    IconData icon, {
    required bool enabled,
  }) {
    return ChoiceChip(
      key: ValueKey('type_chip_${type.name}'),
      avatar: Icon(icon, size: 18),
      label: Text(name),
      selected: _type == type,
      onSelected: (_saving || !enabled) ? null : (_) => _selectType(type),
    );
  }

  Widget _buildCategorySection(
    ThemeData theme,
    AsyncValue<List<CategoryRow>> async,
    ({String id, String name, String? icon})? kept,
  ) {
    if (async.hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label(theme, 'Category'),
          Text("Couldn't load categories", style: theme.textTheme.bodyMedium),
        ],
      );
    }
    final categories = async.valueOrNull;
    if (categories == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label(theme, 'Category'),
          const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      );
    }
    if (categories.isEmpty && kept == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label(theme, 'Category'),
          Text(
            'No categories available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      );
    }

    CategoryRow? chosen;
    for (final c in categories) {
      if (c.id == _categoryId) chosen = c;
    }
    // Edit mode: the row's own archived category, shown as selected.
    final keptShown = (chosen == null && kept != null && kept.id == _categoryId)
        ? kept
        : null;
    final recent =
        ref.watch(recentCategoriesProvider(_categoryKind)).valueOrNull ??
        const <CategoryRow>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PickerField(
          key: const ValueKey('category_field'),
          label: 'Category',
          hint: 'Choose a category',
          value: keptShown != null
              ? '${keptShown.name} (archived)'
              : chosen?.name,
          icon: keptShown != null
              ? categoryIcon(keptShown.icon)
              : (chosen == null ? null : categoryIcon(chosen.icon)),
          errorText: _categoryError,
          enabled: !_saving,
          onTap: () => _pickCategory(categories, kept),
        ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _label(theme, 'Recent'),
          _recentCategoryChips(recent),
        ],
      ],
    );
  }

  Widget _recentCategoryChips(List<CategoryRow> recent) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelMax = math.max(48.0, constraints.maxWidth - 80);
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final c in recent)
              ChoiceChip(
                key: ValueKey('recent_category_chip_${c.id}'),
                avatar: Icon(categoryIcon(c.icon), size: 18),
                label: _chipLabel(c.name, labelMax),
                selected: _categoryId == c.id,
                onSelected: _saving ? null : (_) => _selectCategory(c.id),
              ),
          ],
        );
      },
    );
  }

  /// The From field (and To, for transfers). With up to [accountChipsMax]
  /// active accounts these are the chips; with more they are picker fields.
  /// "To" never offers the From account.
  ///
  /// [fromChoices] / [toPool] are the active accounts, plus (edit mode) the
  /// row's own archived From / To account in its slot. Chips vs pickers still
  /// depends on the ACTIVE count only.
  List<Widget> _accountFields(
    ThemeData theme,
    List<AccountRow> accounts,
    String fromLabel, {
    required List<AccountRow> fromChoices,
    required List<AccountRow> toPool,
  }) {
    final usePickers = accounts.length > accountChipsMax;
    final toChoices = toPool.where((a) => a.id != _fromId).toList();

    AccountRow? byId(List<AccountRow> list, String? id) {
      for (final a in list) {
        if (a.id == id) return a;
      }
      return null;
    }

    final from = byId(fromChoices, _fromId);
    final to = byId(toPool, _toId);

    return [
      if (usePickers)
        _PickerField(
          key: const ValueKey('from_field'),
          label: fromLabel,
          hint: 'Choose an account',
          value: from == null ? null : _accountLabel(from),
          icon: from == null ? null : accountTypeIcon(from.type),
          errorText: _fromError,
          enabled: !_saving,
          onTap: () => _pickAccount(
            title: fromLabel,
            choices: fromChoices,
            selectedId: _fromId,
            isFrom: true,
          ),
        )
      else ...[
        _label(theme, fromLabel),
        _accountChips(fromChoices, selectedId: _fromId, isFrom: true),
        _fieldError(theme, _fromError),
      ],
      if (_isTransfer) ...[
        const SizedBox(height: AppSpacing.lg),
        if (usePickers)
          _PickerField(
            key: const ValueKey('to_field'),
            label: 'To',
            hint: 'Choose an account',
            value: to == null ? null : _accountLabel(to),
            icon: to == null ? null : accountTypeIcon(to.type),
            errorText: _toError,
            enabled: !_saving,
            onTap: () => _pickAccount(
              title: 'To',
              choices: toChoices,
              selectedId: _toId,
              isFrom: false,
            ),
          )
        else ...[
          _label(theme, 'To'),
          _accountChips(toChoices, selectedId: _toId, isFrom: false),
          _fieldError(theme, _toError),
        ],
      ],
    ];
  }

  Widget _accountChips(
    List<AccountRow> accounts, {
    required String? selectedId,
    required bool isFrom,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelMax = math.max(48.0, constraints.maxWidth - 80);
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final a in accounts)
              ChoiceChip(
                key: ValueKey('${isFrom ? 'from' : 'to'}_chip_${a.id}'),
                avatar: Icon(accountTypeIcon(a.type), size: 18),
                label: _chipLabel(_accountLabel(a), labelMax),
                selected: selectedId == a.id,
                onSelected: _saving
                    ? null
                    : (_) {
                        if (isFrom) {
                          _selectFrom(a.id);
                        } else {
                          setState(() {
                            _toId = a.id;
                            _toError = null;
                          });
                        }
                      },
              ),
          ],
        );
      },
    );
  }

  /// A chip label that can never overflow: one line, ellipsis, bounded width.
  Widget _chipLabel(String text, double maxWidth) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

/// A read-only field that opens a picker: a themed InputDecorator inside an
/// InkWell, showing the chosen value (with its icon) or a hint. Small and
/// stateless, so rebuilding the form never rebuilds a list of choices.
class _PickerField extends StatelessWidget {
  const _PickerField({
    super.key,
    required this.label,
    required this.hint,
    required this.enabled,
    required this.onTap,
    this.value,
    this.icon,
    this.errorText,
  });

  final String label;
  final String hint;
  final String? value;
  final IconData? icon;
  final String? errorText;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.control),
      onTap: enabled ? onTap : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          suffixIcon: Icon(PhosphorIconsRegular.caretDown, color: muted),
        ),
        child: value == null
            ? Text(
                hint,
                style: theme.textTheme.bodyLarge?.copyWith(color: muted),
              )
            : Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: theme.colorScheme.onSurface),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      value!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
