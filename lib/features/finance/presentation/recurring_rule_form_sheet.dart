import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/accounts_dao.dart';
import '../data/categories_dao.dart';
import '../data/recurring_rules_dao.dart';
import '../domain/category_kind.dart';
import '../domain/recurrence_frequency.dart';

/// No spinner-freeze-on-save needed — saving a rule doesn't change
/// either accountsProvider's or categoriesProvider's membership (no
/// kind filter, no exclusion list like Budgets), so neither dropdown
/// can be invalidated by this form's own save. Confirmed for this
/// form specifically, not inherited (task response).
class RecurringRuleFormSheet extends ConsumerStatefulWidget {
  const RecurringRuleFormSheet({super.key, this.existing});

  final RecurringTransactionRuleRow? existing;

  @override
  ConsumerState<RecurringRuleFormSheet> createState() => _RecurringRuleFormSheetState();
}

class _RecurringRuleFormSheetState extends ConsumerState<RecurringRuleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedAccountId;
  String? _selectedCategoryId;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  late DateTime _startDate;
  bool _neverEnds = true;
  DateTime? _endDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final now = DateTime.now();
    _startDate = existing?.startDate ?? DateTime(now.year, now.month, now.day);
    if (existing != null) {
      _amountController.text = (existing.amountCents / 100).toStringAsFixed(2);
      _noteController.text = existing.note;
      _selectedAccountId = existing.accountId;
      _selectedCategoryId = existing.categoryId;
      _frequency = RecurrenceFrequency.values.byName(existing.frequency);
      _neverEnds = existing.endDate == null;
      _endDate = existing.endDate;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final theme = Theme.of(context);
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return accountsAsync.when(
      loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: Text("Couldn't load accounts: $e")),
      data: (accountList) {
        if (accountList.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Text('Add an account first, on the Accounts tab, before setting up a recurring rule.'),
          );
        }
        return categoriesAsync.when(
          loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: Text("Couldn't load categories: $e")),
          data: (categoryList) {
            if (categoryList.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text('Add a category first, on the Categories tab, before setting up a recurring rule.'),
              );
            }

            // No kind restriction — recurring items can be income
            // (salary) or expense (rent); type derives live from
            // whichever category is picked, same as the main
            // transaction form.
            final effectiveAccountId = _selectedAccountId ?? accountList.first.id;
            final effectiveCategoryId = _selectedCategoryId ?? categoryList.first.id;

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
                      Text(isEdit ? 'Edit recurring rule' : 'New recurring rule', style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.lg),
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
                        initialValue: effectiveCategoryId,
                        decoration: const InputDecoration(labelText: 'Category'),
                        isExpanded: true,
                        items: [
                          for (final c in categoryList)
                            DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                '${c.name} (${CategoryKind.values.byName(c.kind).label})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => _selectedCategoryId = v),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(labelText: 'Amount', hintText: '0.00'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter an amount';
                          final parsed = double.tryParse(v);
                          if (parsed == null) return 'Enter a valid number';
                          if (parsed <= 0) return 'Amount must be greater than 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _noteController,
                        decoration: const InputDecoration(labelText: 'Note (optional)'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<RecurrenceFrequency>(
                        initialValue: _frequency,
                        decoration: const InputDecoration(labelText: 'Frequency'),
                        items: [
                          for (final f in RecurrenceFrequency.values) DropdownMenuItem(value: f, child: Text(f.label)),
                        ],
                        onChanged: (v) => setState(() => _frequency = v ?? _frequency),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Start date'),
                        subtitle: Text(_formatDate(_startDate)),
                        trailing: const Icon(Icons.edit_calendar_outlined),
                        // Locked after creation — flagged design
                        // decision (task response): changing it post-
                        // creation would desync nextDueDate, which has
                        // likely already advanced independently.
                        enabled: !isEdit,
                        onTap: isEdit ? null : _pickStartDate,
                      ),
                      if (isEdit)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            'Start date is locked after creation.',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Never ends'),
                        value: _neverEnds,
                        onChanged: (v) => setState(() {
                          _neverEnds = v;
                          if (v) _endDate = null;
                        }),
                      ),
                      if (!_neverEnds)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('End date'),
                          subtitle: Text(_endDate != null ? _formatDate(_endDate!) : 'Pick a date'),
                          trailing: const Icon(Icons.edit_calendar_outlined),
                          onTap: _pickEndDate,
                        ),
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton(
                        onPressed: _saving ? null : () => _save(effectiveAccountId, effectiveCategoryId),
                        child: Text(_saving ? 'Saving…' : (isEdit ? 'Save' : 'Add rule')),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;
    // Pure calendar date, zero time component — unlike Sell/Buy
    // More's event timestamps, a rule's dates are only ever compared
    // date-only throughout generation, so midnight is the correct,
    // unambiguous representation here (task response).
    setState(() => _startDate = DateTime(date.year, date.month, date.day));
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 36500)),
    );
    if (date == null || !mounted) return;
    setState(() => _endDate = DateTime(date.year, date.month, date.day));
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<void> _save(String accountId, String categoryId) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_neverEnds && _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick an end date, or turn "Never ends" back on.')),
      );
      return;
    }

    setState(() => _saving = true);

    final db = ref.read(appDatabaseProvider);
    final amountCents = (double.parse(_amountController.text) * 100).round();
    final note = _noteController.text.trim();

    if (widget.existing == null) {
      final userId = await LocalUserId.get();
      await db.insertRule(
        userId: userId,
        accountId: accountId,
        categoryId: categoryId,
        amountCents: amountCents,
        note: note,
        frequency: _frequency,
        startDate: _startDate,
        endDate: _neverEnds ? null : _endDate,
      );
    } else {
      await db.updateRule(
        id: widget.existing!.id,
        accountId: accountId,
        categoryId: categoryId,
        amountCents: amountCents,
        note: note,
        frequency: _frequency,
        endDate: _neverEnds ? null : _endDate,
      );
    }

    if (mounted) Navigator.pop(context);
  }
}