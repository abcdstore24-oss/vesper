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

/// Adds to an existing holding — mirrors sell_investment_sheet.dart's
/// shape (quantity + amount + optional funding + date), but the
/// funding section specifically reuses investment_form_sheet.dart's
/// JUST-FIXED pattern verbatim (task response): fundingBlocked
/// defaults to true and is only cleared once both
/// accountsProvider/categoriesProvider have resolved with real,
/// non-empty data; effectiveAccountId/effectiveCategoryId are
/// computed synchronously inside that same build() call, no
/// addPostFrameCallback, no separate child widget that would force
/// one back in. Save's onPressed is null whenever funding is on and
/// still blocked.
///
/// No second confirmation dialog — this sheet's own Save button is
/// the confirmation, same as UpdateValueDialog and
/// SellInvestmentSheet; a destructive-action-style AlertDialog
/// confirm is reserved for deletions in this project, and buying more
/// deletes nothing (task response).
class BuyMoreInvestmentSheet extends ConsumerStatefulWidget {
  const BuyMoreInvestmentSheet({super.key, required this.investment});

  final InvestmentRow investment;

  @override
  ConsumerState<BuyMoreInvestmentSheet> createState() => _BuyMoreInvestmentSheetState();
}

class _BuyMoreInvestmentSheetState extends ConsumerState<BuyMoreInvestmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _amountPaidController = TextEditingController();
  bool _fundFromAccount = true;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  DateTime _purchaseDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget? fundingSection;
    String? effectiveAccountId;
    String? effectiveCategoryId;
    // Default to blocked, not to safe — same fix as
    // investment_form_sheet.dart. Only cleared once both providers
    // have resolved AND confirmed a usable account and expense
    // category exist.
    var fundingBlocked = true;

    if (_fundFromAccount) {
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
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text('Add an expense category first, on the Categories tab — or turn this off.'),
                );
              }

              // Only reached once both providers have real,
              // non-empty data — the one place fundingBlocked is
              // cleared and the effective ids are ever non-null.
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
                    subtitle: Text(_formatDate(_purchaseDate)),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: _pickDate,
                  ),
                ],
              );
            },
          );
        },
      );
    }

    final canSave = !_fundFromAccount || !fundingBlocked;

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
              Text('Buy more — ${widget.investment.name}', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Current holding: ${InvestmentType.formatQuantity(widget.investment.quantity)}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity to add'),
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
                controller: _amountPaidController,
                decoration: const InputDecoration(labelText: 'Amount paid (total)', hintText: '0.00'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter an amount';
                  final parsed = double.tryParse(v);
                  if (parsed == null) return 'Enter a valid number';
                  if (parsed < 0) return "Amount can't be negative";
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Current value rises by the amount paid — use "Update value" afterward to correct it.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fund this from an account'),
                subtitle: const Text('Creates a matching expense transaction for the amount paid'),
                value: _fundFromAccount,
                onChanged: (v) => setState(() => _fundFromAccount = v),
              ),
              ?fundingSection,
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: (_saving || !canSave)
                    ? null
                    : () => _save(effectiveAccountId, effectiveCategoryId),
                child: Text(
                  _saving
                      ? 'Saving…'
                      : (!canSave ? 'Add an account or category to fund, or turn funding off' : 'Buy more'),
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
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final now = DateTime.now();
    setState(() {
      _purchaseDate = DateTime(date.year, date.month, date.day, now.hour, now.minute);
    });
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<void> _save(String? fundingAccountId, String? fundingCategoryId) async {
    if (!_formKey.currentState!.validate()) return;

    // Defensive fallback only — unreachable with the button disabled
    // whenever canSave is false, kept so a future change that
    // accidentally desyncs the two fails visibly, not silently.
    if (_fundFromAccount && (fundingAccountId == null || fundingCategoryId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick an account and category to fund this purchase, or turn funding off.')),
      );
      return;
    }

    setState(() => _saving = true);

    final db = ref.read(appDatabaseProvider);
    final userId = await LocalUserId.get();
    final quantityAdded = double.parse(_quantityController.text);
    final amountPaidCents = (double.parse(_amountPaidController.text) * 100).round();

    await db.buyMoreInvestment(
      userId: userId,
      investment: widget.investment,
      quantityAdded: quantityAdded,
      amountPaidCents: amountPaidCents,
      fundingAccountId: _fundFromAccount ? fundingAccountId : null,
      fundingCategoryId: _fundFromAccount ? fundingCategoryId : null,
      fundingDate: _fundFromAccount ? _purchaseDate : null,
    );

    if (mounted) Navigator.pop(context);
  }
}