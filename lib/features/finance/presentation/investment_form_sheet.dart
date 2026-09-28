import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/investments_dao.dart';
import '../domain/investment_type.dart';

/// Name/type/quantity/cost basis only — never currentValueCents. Not
/// spinner-frozen on save (unlike budget_form_sheet.dart after the
/// Task 2.4 fix): this form's only picker is the static
/// InvestmentType enum, never touched by any DAO write, so saving
/// can't invalidate its own dropdown's selection — see task response.
class InvestmentFormSheet extends ConsumerStatefulWidget {
  const InvestmentFormSheet({super.key, this.existing});

  final InvestmentRow? existing;

  @override
  ConsumerState<InvestmentFormSheet> createState() => _InvestmentFormSheetState();
}

class _InvestmentFormSheetState extends ConsumerState<InvestmentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _costBasisController;
  late InvestmentType _type;
  bool _saving = false;

    @override
    void initState() {
      super.initState();
      final existing = widget.existing;
      _nameController = TextEditingController(text: existing?.name ?? '');
      _quantityController = TextEditingController(
        text: existing != null ? InvestmentType.formatQuantity(existing.quantity) : '',
      );
      _costBasisController = TextEditingController(
        text: existing != null ? (existing.costBasisCents / 100).toStringAsFixed(2) : '',
      );
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
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : (isEdit ? 'Save' : 'Add investment')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
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