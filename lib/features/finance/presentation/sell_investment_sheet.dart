import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/accounts_dao.dart';
import '../data/categories_dao.dart';
import '../data/investment_sales_dao.dart';
import '../domain/category_kind.dart';
import '../domain/investment_type.dart';

/// No spinner-freeze-on-save here (unlike budget_form_sheet.dart) —
/// this form's account/category dropdowns aren't affected by its own
/// save action the way Budgets' category list was; see task response.
/// Confirm button is still disabled while _saving as a plain
/// double-submit guard.
class SellInvestmentSheet extends ConsumerStatefulWidget {
  const SellInvestmentSheet({super.key, required this.investment});

  final InvestmentRow investment;

  @override
  ConsumerState<SellInvestmentSheet> createState() => _SellInvestmentSheetState();
}

class _SellInvestmentSheetState extends ConsumerState<SellInvestmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _proceedsController = TextEditingController();
  String? _accountId;
  String? _categoryId;
  DateTime _soldAt = DateTime.now();
  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _quantityController.dispose();
    _proceedsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            child: Text('Add an account first, on the Accounts tab, before selling an investment.'),
          );
        }
        return categoriesAsync.when(
          loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: Text("Couldn't load categories: $e")),
          data: (categoryList) {
            // Income-kind only — locked decision 2.
            final incomeCategories = categoryList.where((c) => c.kind == CategoryKind.income.name).toList();
            if (incomeCategories.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text('No income categories yet — add one on the Categories tab first.'),
              );
            }

            final effectiveAccountId = _accountId ?? accountList.first.id;
            final effectiveCategoryId = _categoryId ?? incomeCategories.first.id;

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
                      Text('Sell — ${widget.investment.name}', style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Remaining: ${InvestmentType.formatQuantity(widget.investment.quantity)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(labelText: 'Quantity to sell'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter a quantity';
                          final parsed = double.tryParse(v);
                          if (parsed == null) return 'Enter a valid number';
                          if (parsed <= 0) return 'Quantity must be greater than 0';
                          // Required addition #2: epsilon tolerance,
                          // not a strict <=, so a genuine
                          // "sell everything" can't fail on float
                          // noise at the exact boundary the DAO's
                          // full-sell branch already accounts for.
                          if (parsed > widget.investment.quantity + investmentQuantityEpsilon) {
                            return "Can't sell more than the remaining quantity";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _proceedsController,
                        decoration: const InputDecoration(labelText: 'Total proceeds', hintText: '0.00'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter proceeds';
                          final parsed = double.tryParse(v);
                          if (parsed == null) return 'Enter a valid number';
                          if (parsed < 0) return "Proceeds can't be negative";
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: effectiveAccountId,
                        decoration: const InputDecoration(labelText: 'Account (proceeds go to)'),
                        items: [
                          for (final a in accountList) DropdownMenuItem(value: a.id, child: Text(a.name)),
                        ],
                        onChanged: (v) => setState(() => _accountId = v),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: effectiveCategoryId,
                        decoration: const InputDecoration(labelText: 'Category (income)'),
                        items: [
                          for (final c in incomeCategories) DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ],
                        onChanged: (v) => setState(() => _categoryId = v),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Date'),
                        subtitle: Text(_formatDate(_soldAt)),
                        trailing: const Icon(Icons.edit_calendar_outlined),
                        onTap: _pickDate,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(_errorMessage!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton(
                        onPressed: _saving ? null : () => _confirm(effectiveAccountId, effectiveCategoryId),
                        child: Text(_saving ? 'Selling…' : 'Confirm sale'),
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

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _soldAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    // Date-only picker (task response) — combined with the
    // current time-of-day at selection, just to produce a valid,
    // reasonably-ordered DateTime for sorting alongside same-day
    // transactions.
    final now = DateTime.now();
    setState(() {
      _soldAt = DateTime(date.year, date.month, date.day, now.hour, now.minute);
    });
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<void> _confirm(String accountId, String categoryId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final db = ref.read(appDatabaseProvider);
    final quantitySold = double.parse(_quantityController.text);
    final proceedsCents = (double.parse(_proceedsController.text) * 100).round();

    try {
      final userId = await LocalUserId.get();
      await db.sellInvestment(
        userId: userId,
        investment: widget.investment,
        quantitySold: quantitySold,
        proceedsCents: proceedsCents,
        accountId: accountId,
        categoryId: categoryId,
        soldAt: _soldAt,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _saving = false;
        _errorMessage = 'Could not complete sale: $e';
      });
    }
  }
}