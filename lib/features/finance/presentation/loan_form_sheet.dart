import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/accounts_dao.dart';
import '../data/categories_dao.dart';
import '../data/loans_dao.dart';
import '../domain/loan_activity_type.dart';
import '../domain/loan_direction.dart';

class LoanFormSheet extends ConsumerStatefulWidget {
  const LoanFormSheet({super.key, this.existing});

  final LoanRow? existing;

  @override
  ConsumerState<LoanFormSheet> createState() => _LoanFormSheetState();
}

class _LoanFormSheetState extends ConsumerState<LoanFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _personNameController = TextEditingController();
  final _principalController = TextEditingController();
  final _noteController = TextEditingController();
  LoanDirection _direction = LoanDirection.lent;
  late DateTime _date;
  late bool _includeInNetWorth;
  bool _saving = false;

  bool _fundFromAccount = true;
  String? _selectedAccountId;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final now = DateTime.now();
    _date = existing?.date ?? DateTime(now.year, now.month, now.day);
    _includeInNetWorth = existing?.includeInNetWorth ?? true;
    if (existing != null) {
      _personNameController.text = existing.personName;
      _principalController.text = (existing.principalCents / 100).toStringAsFixed(2);
      _noteController.text = existing.note;
      _direction = LoanDirection.values.byName(existing.direction);
    }
  }

  @override
  void dispose() {
    _personNameController.dispose();
    _principalController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Only reachable in ADD mode now — in edit mode the Direction
  /// dropdown's onChanged is null (direction is immutable after
  /// creation, this task). Handles two direction-dependent resets:
  /// 1. The instant direction becomes borrowed, the stored Net Worth
  ///    flag is forced back to true — the toggle disappears and a
  ///    stale `false` can't carry through.
  /// 2. The funding category selection is cleared, so the default
  ///    (direction.preferredCategoryNameFor) recomputes for the new
  ///    direction in build() instead of an earlier explicit pick
  ///    sticking. _selectedAccountId is deliberately NOT reset — an
  ///    account isn't direction-dependent.
  void _onDirectionChanged(LoanDirection? value) {
    if (value == null) return;
    setState(() {
      _direction = value;
      _selectedCategoryId = null;
      if (_direction == LoanDirection.borrowed) {
        _includeInNetWorth = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final theme = Theme.of(context);

    // REVERTED this task to a principal-specific name (was
    // activityLocked while it also gated direction). The two locks
    // now differ: direction is locked whenever isEdit (no activity
    // lookup involved), while this flag locks ONLY the principal
    // field, and only when loanActivityCountProvider reports a count
    // above 0 (defaulting to locked while loading/erroring). A shared
    // name would now be wrong for direction. Person name, note, date,
    // and the Count in Net Worth toggle stay editable regardless.
    var principalLocked = isEdit;
    if (isEdit) {
      final activityCountAsync = ref.watch(loanActivityCountProvider(widget.existing!.id));
      principalLocked = activityCountAsync.maybeWhen(
        data: (count) => count > 0,
        orElse: () => true,
      );
    }

    Widget? fundingSection;
    String? effectiveAccountId;
    String? effectiveCategoryId;
    var fundingBlocked = true;

    if (!isEdit && _fundFromAccount) {
      final accountsAsync = ref.watch(accountsProvider);
      final categoriesAsync = ref.watch(categoriesProvider);
      final preferredCategoryName = _direction.preferredCategoryNameFor(LoanActivityType.increase);

      fundingSection = accountsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text("Couldn't load accounts: $e"),
        ),
        data: (accountList) {
          if (accountList.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text('Add an account first, on the Accounts tab — or turn this off.'),
            );
          }
          return categoriesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text("Couldn't load categories: $e"),
            ),
            data: (categoryList) {
              if (categoryList.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text('Add a category first, on the Categories tab — or turn this off.'),
                );
              }

              fundingBlocked = false;
              effectiveAccountId = _selectedAccountId ?? accountList.first.id;
              final preferred = categoryList.where((c) => c.name == preferredCategoryName).toList();
              effectiveCategoryId =
                  _selectedCategoryId ?? (preferred.isNotEmpty ? preferred.first.id : categoryList.first.id);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: effectiveAccountId,
                    decoration: const InputDecoration(labelText: 'Account'),
                    isExpanded: true,
                    items: [
                      for (final a in accountList)
                        DropdownMenuItem(value: a.id, child: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setState(() => _selectedAccountId = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    // Keyed on the effective id so the dropdown's
                    // displayed value follows the recomputed default
                    // after a direction change —
                    // DropdownButtonFormField only reads initialValue
                    // once per State.
                    key: ValueKey('loan-funding-category-$effectiveCategoryId'),
                    initialValue: effectiveCategoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    isExpanded: true,
                    items: [
                      for (final c in categoryList)
                        DropdownMenuItem(value: c.id, child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    final canSave = isEdit || !_fundFromAccount || !fundingBlocked;

    final fundingTitle = _direction == LoanDirection.lent ? 'Fund this from an account' : 'Receive this into an account';
    final fundingSubtitle = _direction == LoanDirection.lent
        ? 'Creates a matching expense for the amount'
        : 'Creates a matching credit for the amount';

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isEdit ? 'Edit loan' : 'New loan', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _personNameController,
                decoration: const InputDecoration(labelText: 'Person'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<LoanDirection>(
                initialValue: _direction,
                decoration: const InputDecoration(labelText: 'Direction'),
                isExpanded: true,
                items: [
                  for (final d in LoanDirection.values)
                    DropdownMenuItem(value: d, child: Text(d.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
                // CHANGED this task: ALWAYS disabled in edit mode,
                // regardless of activity. Locking only when
                // loan_activities rows exist left a hole — a loan
                // funded at creation has no activity row (by design),
                // so its direction stayed editable, and flipping it
                // swung Net Worth by twice the principal and
                // contradicted the creation transaction. Add mode is
                // unchanged.
                onChanged: isEdit ? null : _onDirectionChanged,
              ),
              if (isEdit)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    "Direction can't be changed after a loan is created — "
                    'if it was entered wrongly and has no activity yet, delete it and add it again.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _principalController,
                enabled: !principalLocked,
                decoration: const InputDecoration(labelText: 'Principal amount', hintText: '0.00'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter an amount';
                  final parsed = double.tryParse(v);
                  if (parsed == null || !parsed.isFinite) return 'Enter a valid number';
                  if (parsed <= 0) return 'Amount must be greater than 0';
                  return null;
                },
              ),
              if (principalLocked)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    // CHANGED this task: was "repayment activity" —
                    // the activity count also includes "Add more", so
                    // "activity" is the accurate word.
                    'Principal is locked — this loan has activity against it.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              if (!isEdit) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Outstanding balance starts equal to the principal — use "Add more"/"Repayment" afterward to change it.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(fundingTitle),
                  subtitle: Text(fundingSubtitle),
                  value: _fundFromAccount,
                  onChanged: (v) => setState(() => _fundFromAccount = v),
                ),
                ?fundingSection,
              ],
              if (_direction == LoanDirection.lent) ...[
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Count in Net Worth'),
                  subtitle: const Text(
                    "Turn off if you no longer expect this to be repaid — can be changed anytime",
                  ),
                  value: _includeInNetWorth,
                  onChanged: (v) => setState(() => _includeInNetWorth = v),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(_formatDate(_date)),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _pickDate,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: (_saving || !canSave) ? null : () => _save(effectiveAccountId, effectiveCategoryId),
                child: Text(
                  _saving
                      ? 'Saving…'
                      : (!canSave
                          ? 'Add an account or category to fund, or turn funding off'
                          : (isEdit ? 'Save' : 'Add loan')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    setState(() => _date = DateTime(date.year, date.month, date.day));
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<void> _save(String? fundingAccountId, String? fundingCategoryId) async {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.existing != null;
    if (!isEdit && _fundFromAccount && (fundingAccountId == null || fundingCategoryId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick an account and category to fund this, or turn funding off.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final personName = _personNameController.text.trim();
      final principalCents = (double.parse(_principalController.text) * 100).round();
      final note = _noteController.text.trim();
      final includeInNetWorth = _direction == LoanDirection.lent ? _includeInNetWorth : true;

      if (widget.existing == null) {
        final userId = await LocalUserId.get();
        await db.insertLoan(
          userId: userId,
          personName: personName,
          direction: _direction,
          principalCents: principalCents,
          note: note,
          date: _date,
          includeInNetWorth: includeInNetWorth,
          fundingAccountId: _fundFromAccount ? fundingAccountId : null,
          fundingCategoryId: _fundFromAccount ? fundingCategoryId : null,
          fundingDate: _fundFromAccount ? _date : null,
        );
      } else {
        await db.updateLoan(
          id: widget.existing!.id,
          personName: personName,
          // direction removed: immutable, never written (DAO no longer
          // accepts it).
          principalCents: principalCents,
          note: note,
          date: _date,
          includeInNetWorth: includeInNetWorth,
        );
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}