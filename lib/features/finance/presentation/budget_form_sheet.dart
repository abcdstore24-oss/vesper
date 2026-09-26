import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/budgets_dao.dart';
import '../data/categories_dao.dart';
import '../domain/category_kind.dart';

class BudgetFormSheet extends ConsumerStatefulWidget {
  const BudgetFormSheet({super.key, required this.monthKey, this.existing});

  final String monthKey;
  final BudgetRow? existing;

  @override
  ConsumerState<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _limitController;
  String? _categoryId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _limitController = TextEditingController(
      text: existing != null ? (existing.limitAmountCents / 100).toStringAsFixed(2) : '',
    );
    _categoryId = existing?.categoryId;
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FIX: once a save is in flight, stop rebuilding against live
    // provider data entirely. The real bug — insertBudget commits,
    // budgetsProvider emits the updated list, this widget rebuilds
    // (still mounted, mid-pop), and the just-picked category is now
    // correctly excluded from availableCategories below — but
    // _categoryId still points at it, and DropdownButtonFormField
    // throws an assertion when its value isn't among its current
    // items. That's a real exception, visible for exactly one frame
    // before the sheet finishes closing — the "quick red flash."
    // Short-circuiting here means the dropdown is never rebuilt again
    // after Save is tapped, so the race can't fire.
    if (_saving) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final isEdit = widget.existing != null;
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final budgetsAsync = ref.watch(budgetsProvider(widget.monthKey));

    return categoriesAsync.when(
      loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: Text("Couldn't load categories: $e")),
      data: (categoryList) {
        final expenseCategories = categoryList.where((c) => c.kind == CategoryKind.expense.name).toList();

        return budgetsAsync.when(
          loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: Text("Couldn't load budgets: $e")),
          data: (existingBudgets) {
            final alreadyBudgetedIds = existingBudgets.map((b) => b.categoryId).toSet();
            final availableCategories = isEdit
                ? expenseCategories
                : expenseCategories.where((c) => !alreadyBudgetedIds.contains(c.id)).toList();

            if (!isEdit && availableCategories.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  expenseCategories.isEmpty
                      ? 'No expense categories yet — add one on the Categories tab first.'
                      : 'Every expense category already has a budget this month.',
                ),
              );
            }

            final effectiveCategoryId =
                _categoryId ?? (isEdit ? widget.existing!.categoryId : availableCategories.first.id);
            final lockedCategoryName =
                isEdit ? categoryList.firstWhere((c) => c.id == widget.existing!.categoryId).name : null;

            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                top: AppSpacing.xl,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(isEdit ? 'Edit budget' : 'New budget', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.lg),
                    if (isEdit)
                      Text('Category: $lockedCategoryName', style: theme.textTheme.bodyLarge)
                    else
                      DropdownButtonFormField<String>(
                        initialValue: effectiveCategoryId,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: [
                          for (final c in availableCategories) DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ],
                        onChanged: (v) => setState(() => _categoryId = v),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _limitController,
                      decoration: const InputDecoration(labelText: 'Monthly limit', hintText: '0.00'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter a limit';
                        final parsed = double.tryParse(v);
                        if (parsed == null) return 'Enter a valid number';
                        if (parsed <= 0) return 'Limit must be greater than 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: () => _save(effectiveCategoryId),
                      child: Text(isEdit ? 'Save' : 'Add budget'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _save(String categoryId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final db = ref.read(appDatabaseProvider);
    final limitCents = (double.parse(_limitController.text) * 100).round();

    if (widget.existing == null) {
      final userId = await LocalUserId.get();
      await db.insertBudget(
        userId: userId,
        categoryId: categoryId,
        monthKey: widget.monthKey,
        limitAmountCents: limitCents,
      );
    } else {
      await db.updateBudgetLimit(id: widget.existing!.id, limitAmountCents: limitCents);
    }

    if (mounted) Navigator.pop(context);
  }
}