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

/// Mirrors sell_investment_sheet.dart — ceiling validation against
/// current outstanding (locked decision 3: rejected, never clamped),
/// same funding-picker pattern as loan_add_more_sheet.dart.
class LoanRepaymentSheet extends ConsumerStatefulWidget {
  const LoanRepaymentSheet({super.key, required this.loan});

  final LoanRow loan;

  @override
  ConsumerState<LoanRepaymentSheet> createState() => _LoanRepaymentSheetState();
}

class _LoanRepaymentSheetState extends ConsumerState<LoanRepaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _fundFromAccount = true;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final direction = LoanDirection.values.byName(widget.loan.direction);
    final preferredCategoryName = direction.preferredCategoryNameFor(LoanActivityType.repayment);
    final outstandingDecimal = (widget.loan.outstandingCents / 100).toStringAsFixed(2);

    Widget? fundingSection;
    String? effectiveAccountId;
    String? effectiveCategoryId;
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
                    initialValue: effectiveCategoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    isExpanded: true,
                    items: [
                      for (final c in categoryList)
                        DropdownMenuItem(value: c.id, child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date'),
                    subtitle: Text(_formatDate(_date)),
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
              Text('Repayment — ${widget.loan.personName}', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${direction.label} · Outstanding: $outstandingDecimal',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount', hintText: '0.00'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter an amount';
                  final parsed = double.tryParse(v);
                  if (parsed == null || !parsed.isFinite) return 'Enter a valid number';
                  if (parsed <= 0) return 'Amount must be greater than 0';
                  // FIXED this task: was a 0.005 (half-cent) tolerance,
                  // which let a value through that could round UP a
                  // full cent past outstandingCents in _save() — a
                  // real, traced bug (see task response), not a
                  // hypothetical. Shrunk to 1e-6, matching this
                  // project's established float-noise-only epsilon
                  // convention (investmentQuantityEpsilon). This is
                  // tight enough only to absorb genuine floating-point
                  // representation error, not loose enough to let a
                  // rounding-driven off-by-one-cent slip through.
                  final outstandingDollars = widget.loan.outstandingCents / 100;
                  if (parsed > outstandingDollars + 1e-6) return "Can't exceed the outstanding balance";
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Credit/debit an account'),
                value: _fundFromAccount,
                onChanged: (v) => setState(() => _fundFromAccount = v),
              ),
              ?fundingSection,
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: (_saving || !canSave) ? null : () => _save(effectiveAccountId, effectiveCategoryId),
                child: Text(
                  _saving ? 'Saving…' : (!canSave ? 'Add an account or category to fund, or turn funding off' : 'Repayment'),
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
    if (_fundFromAccount && (fundingAccountId == null || fundingCategoryId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick an account and category to fund this, or turn funding off.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final userId = await LocalUserId.get();
      final amountCents = (double.parse(_amountController.text) * 100).round();
      await db.repayLoan(
        userId: userId,
        loan: widget.loan,
        amountCents: amountCents,
        fundingAccountId: _fundFromAccount ? fundingAccountId : null,
        fundingCategoryId: _fundFromAccount ? fundingCategoryId : null,
        fundingDate: _fundFromAccount ? _date : null,
      );
      if (mounted) Navigator.pop(context);
    } on ArgumentError {
      // NEW this task — defensive backstop, same belt-and-suspenders
      // philosophy as Sell's disabled-button-plus-fallback-check. The
      // validator above should make this unreachable now that its
      // epsilon is tight, but if any future edge case (e.g. a
      // different rounding path, a locale-specific parse quirk) still
      // produces an amountCents that exceeds outstanding, this shows
      // a clean message instead of letting it propagate uncaught.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Can't exceed the outstanding balance.")),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}