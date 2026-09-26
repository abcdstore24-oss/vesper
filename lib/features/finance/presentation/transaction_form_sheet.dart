import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/accounts_dao.dart';
import '../data/categories_dao.dart';
import '../data/transactions_dao.dart';
import '../domain/category_kind.dart';

class TransactionFormSheet extends ConsumerStatefulWidget {
  const TransactionFormSheet({super.key, this.existing});

  final TransactionRow? existing;

  @override
  ConsumerState<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  String? _accountId;
  String? _categoryId;
  late DateTime _occurredAt;
  bool _isRecurring = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _amountController = TextEditingController(
      text: existing != null ? (existing.amountCents / 100).toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
    _accountId = existing?.accountId;
    _categoryId = existing?.categoryId;
    _occurredAt = existing?.occurredAt ?? DateTime.now();
    _isRecurring = existing?.isRecurring ?? false;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;

    return accountsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text("Couldn't load accounts: $e"),
      ),
      data: (accountList) {
        if (accountList.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Text('Add an account first, on the Accounts tab, before adding transactions.'),
          );
        }
        return categoriesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text("Couldn't load categories: $e"),
          ),
          data: (categoryList) {
            if (categoryList.isEmpty) {
              // Shouldn't normally happen — categoriesSeedProvider is
              // watched by both the Categories tab and this sheet's
              // caller (transactions_list_screen.dart) — but guard
              // anyway rather than showing a broken empty dropdown.
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text('No categories yet — open the Categories tab once, then try again.'),
              );
            }

            final effectiveAccountId = _accountId ?? accountList.first.id;
            final effectiveCategoryId = _categoryId ?? categoryList.first.id;
            final selectedCategory = categoryList.firstWhere(
              (c) => c.id == effectiveCategoryId,
              orElse: () => categoryList.first,
            );
            final derivedKind = CategoryKind.values.byName(selectedCategory.kind);

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
                      Text(isEdit ? 'Edit transaction' : 'New transaction', style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.lg),
                      DropdownButtonFormField<String>(
                        initialValue: effectiveAccountId,
                        decoration: const InputDecoration(labelText: 'Account'),
                        items: [
                          for (final a in accountList) DropdownMenuItem(value: a.id, child: Text(a.name)),
                        ],
                        onChanged: (v) => setState(() => _accountId = v),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: effectiveCategoryId,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: [
                          for (final c in categoryList)
                            DropdownMenuItem(
                              value: c.id,
                              child: Text('${c.name} (${CategoryKind.values.byName(c.kind).label})'),
                            ),
                        ],
                        onChanged: (v) => setState(() => _categoryId = v),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // Type is derived, not selectable — locked
                      // decision 2. Shown read-only so it's never
                      // ambiguous which way this transaction counts.
                      Text(
                        'Type: ${derivedKind.label} (set by category)',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Date'),
                        subtitle: Text(_formatDateTime(_occurredAt)),
                        trailing: const Icon(Icons.edit_calendar_outlined),
                        onTap: _pickDateTime,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _noteController,
                        decoration: const InputDecoration(labelText: 'Note (optional)'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Recurring'),
                        subtitle: const Text('Just a label for now — no auto-repeat yet'),
                        value: _isRecurring,
                        onChanged: (v) => setState(() => _isRecurring = v),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton(
                        onPressed: _saving ? null : () => _save(effectiveAccountId, effectiveCategoryId, derivedKind),
                        child: Text(_saving ? 'Saving…' : (isEdit ? 'Save' : 'Add transaction')),
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

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (time == null || !mounted) return;

    setState(() {
      _occurredAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String _formatDateTime(DateTime dt) {
    final d = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final t = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d  $t';
  }

  Future<void> _save(String accountId, String categoryId, CategoryKind derivedKind) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final db = ref.read(appDatabaseProvider);
    final amountCents = (double.parse(_amountController.text) * 100).round();
    final note = _noteController.text.trim();

    if (widget.existing == null) {
      final userId = await LocalUserId.get();
      await db.insertTransaction(
        userId: userId,
        accountId: accountId,
        categoryId: categoryId,
        amountCents: amountCents,
        type: derivedKind,
        note: note,
        occurredAt: _occurredAt,
        isRecurring: _isRecurring,
      );
    } else {
      await db.updateTransaction(
        id: widget.existing!.id,
        accountId: accountId,
        categoryId: categoryId,
        amountCents: amountCents,
        type: derivedKind,
        note: note,
        occurredAt: _occurredAt,
        isRecurring: _isRecurring,
      );
    }

    if (mounted) Navigator.pop(context);
  }
}