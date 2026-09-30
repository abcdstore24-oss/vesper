import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/accounts_dao.dart';
import '../data/categories_dao.dart';
import '../data/investments_dao.dart';
import '../domain/category_kind.dart';
import '../domain/investment_type.dart';

/// Name/type/quantity/cost basis, unchanged. Add mode only: an
/// optional "Fund this from an account" toggle (default ON) that,
/// when on, also picks an account + expense category + date and
/// creates a matching expense Transaction on save — mirror of
/// sellInvestment crediting an account, this is the debit side for a
/// purchase. Edit mode is untouched: no toggle, no funding fields.
///
/// FIX HISTORY on this file's funding section, both for the same
/// underlying reason — "assume safe until proven otherwise" is the
/// wrong default when the consequence is a button that's tappable
/// while its own required state is still null:
/// 1. Originally, default account/category were set via
///    addPostFrameCallback from a separate _FundingFields widget —
///    there was a window on first build where they were null but the
///    button was enabled. Fixed by folding _FundingFields back in
///    here and computing effectiveAccountId/effectiveCategoryId
///    synchronously inside build(), same pattern
///    sell_investment_sheet.dart already used.
/// 2. That fix introduced a narrower version of the same bug:
///    fundingBlocked defaulted to false and was only set true inside
///    the accountsAsync/categoriesAsync `data:` branches — so while
///    either provider was still loading, canSave read true even
///    though effectiveAccountId/effectiveCategoryId were still null.
///    Fixed below by defaulting fundingBlocked to TRUE and only
///    clearing it once both providers have resolved with real,
///    non-empty data.
///
/// Spinner-freeze-on-save: re-examined for this task, not assumed —
/// saving doesn't change either accountsProvider's or
/// categoriesProvider's membership (unlike Budgets, nothing here
/// excludes a category once picked), so the Task 2.4 race can't
/// occur. Still not needed.
class InvestmentFormSheet extends ConsumerStatefulWidget {
  const InvestmentFormSheet({super.key, this.existing});

  final InvestmentRow? existing;

  @override
  ConsumerState<InvestmentFormSheet> createState() => _InvestmentFormSheetState();
}

class _InvestmentFormSheetState extends ConsumerState<InvestmentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costBasisController = TextEditingController();
  late InvestmentType _type;
  bool _saving = false;

  bool _fundFromAccount = true;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  DateTime _fundingDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController.text = existing?.name ?? '';
    _quantityController.text = existing != null ? InvestmentType.formatQuantity(existing.quantity) : '';
    _costBasisController.text = existing != null ? (existing.costBasisCents / 100).toStringAsFixed(2) : '';
    _type = existing != null ? InvestmentType.values.byName(existing.type) : InvestmentType.stock;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _costBasisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final theme = Theme.of(context);

    Widget? fundingSection;
    String? effectiveAccountId;
    String? effectiveCategoryId;
    // FIX: default to blocked, not to safe. Only cleared once both
    // providers have resolved AND confirmed a usable account and
    // expense category exist. Loading and error states leave this
    // true, same as "no accounts" or "no expense categories" do.
    var fundingBlocked = true;

    if (!isEdit && _fundFromAccount) {
      final accountsAsync = ref.watch(accountsProvider);
      final categoriesAsync = ref.watch(categoriesProvider);

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
            // fundingBlocked already true by default — nothing to set.
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text('Add an account first, on the Accounts tab, to fund a purchase — or turn this off.'),
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
              final expenseCategories = categoryList.where((c) => c.kind == CategoryKind.expense.name).toList();
              if (expenseCategories.isEmpty) {
                // fundingBlocked already true by default — nothing to set.
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text('Add an expense category first, on the Categories tab — or turn this off.'),
                );
              }

              // Only reached once both providers have real data AND
              // both lists are non-empty — this is the one place
              // fundingBlocked is cleared, and effectiveAccountId/
              // effectiveCategoryId are only ever non-null here too.
              fundingBlocked = false;
              effectiveAccountId = _selectedAccountId ?? accountList.first.id;
              effectiveCategoryId = _selectedCategoryId ??
                  (InvestmentType.preferredFundingCategory(expenseCategories)?.id ?? expenseCategories.first.id);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: effectiveAccountId,
                    decoration: const InputDecoration(labelText: 'Account'),
                    items: [
                      for (final a in accountList) DropdownMenuItem(value: a.id, child: Text(a.name)),
                    ],
                    onChanged: (v) => setState(() => _selectedAccountId = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: effectiveCategoryId,
                    decoration: const InputDecoration(labelText: 'Category (expense)'),
                    items: [
                      for (final c in expenseCategories) DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date'),
                    subtitle: Text(_formatDate(_fundingDate)),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: _pickFundingDate,
                  ),
                ],
              );
            },
          );
        },
      );
    }

    final canSave = isEdit || !_fundFromAccount || !fundingBlocked;

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
              Text(isEdit ? 'Edit investment' : 'New investment', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<InvestmentType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  for (final t in InvestmentType.values) DropdownMenuItem(value: t, child: Text(t.label)),
                ],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity', hintText: 'e.g. 10 or 0.5'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter a quantity';
                  final parsed = double.tryParse(v);
                  if (parsed == null) return 'Enter a valid number';
                  if (parsed <= 0) return 'Quantity must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _costBasisController,
                decoration: const InputDecoration(labelText: 'Cost basis (total)', hintText: '0.00'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter a cost basis';
                  final parsed = double.tryParse(v);
                  if (parsed == null) return 'Enter a valid number';
                  if (parsed < 0) return "Cost basis can't be negative";
                  return null;
                },
              ),
              if (!isEdit) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Current value starts equal to cost basis — use "Update value" afterward to change it.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fund this from an account'),
                  subtitle: const Text('Creates a matching expense transaction for the cost basis'),
                  value: _fundFromAccount,
                  onChanged: (v) => setState(() => _fundFromAccount = v),
                ),
                ?fundingSection,
              ],
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: (_saving || !canSave)
                    ? null
                    : () => _save(effectiveAccountId, effectiveCategoryId),
                child: Text(
                  _saving
                      ? 'Saving…'
                      : (!canSave
                          ? 'Add an account or category to fund, or turn funding off'
                          : (isEdit ? 'Save' : 'Add investment')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFundingDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fundingDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final now = DateTime.now();
    setState(() {
      _fundingDate = DateTime(date.year, date.month, date.day, now.hour, now.minute);
    });
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<void> _save(String? fundingAccountId, String? fundingCategoryId) async {
    if (!_formKey.currentState!.validate()) return;

    // Defensive fallback only — with the button disabled whenever
    // canSave is false, this should be unreachable in practice. Kept
    // so that if it's ever reached, it fails visibly instead of
    // silently.
    if (widget.existing == null && _fundFromAccount && (fundingAccountId == null || fundingCategoryId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick an account and category to fund this purchase, or turn funding off.')),
      );
      return;
    }

    setState(() => _saving = true);

    final db = ref.read(appDatabaseProvider);
    final name = _nameController.text.trim();
    final quantity = double.parse(_quantityController.text);
    final costBasisCents = (double.parse(_costBasisController.text) * 100).round();

    if (widget.existing == null) {
      final userId = await LocalUserId.get();
      await db.insertInvestment(
        userId: userId,
        name: name,
        type: _type,
        quantity: quantity,
        costBasisCents: costBasisCents,
        fundingAccountId: _fundFromAccount ? fundingAccountId : null,
        fundingCategoryId: _fundFromAccount ? fundingCategoryId : null,
        fundingDate: _fundFromAccount ? _fundingDate : null,
      );
    } else {
      await db.updateInvestmentDetails(
        id: widget.existing!.id,
        name: name,
        type: _type,
        quantity: quantity,
        costBasisCents: costBasisCents,
      );
    }

    if (mounted) Navigator.pop(context);
  }
}