import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/account_type.dart';
import '../data/accounts_dao.dart';

class AccountFormSheet extends ConsumerStatefulWidget {
  const AccountFormSheet({super.key, this.existing});

  final AccountRow? existing;

  @override
  ConsumerState<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _currencyController;
  late final TextEditingController _balanceController;
  late AccountType _type;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _currencyController = TextEditingController(text: existing?.currency ?? 'USD');
    // Cents -> decimal string for display only. toStringAsFixed(2)
    // keeps this exact for any int input (no float math involved).
    _balanceController = TextEditingController(
      text: existing != null
          ? (existing.startingBalanceCents / 100).toStringAsFixed(2)
          : '',
    );
    _type = existing != null
        ? AccountType.values.byName(existing.type)
        : AccountType.bank;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currencyController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

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
            Text(isEdit ? 'Edit account' : 'New account', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<AccountType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                for (final t in AccountType.values) DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _currencyController,
              decoration: const InputDecoration(labelText: 'Currency (e.g. USD)'),
              textCapitalization: TextCapitalization.characters,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a currency' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _balanceController,
              decoration: const InputDecoration(labelText: 'Starting balance', hintText: '0.00'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter a balance';
                if (double.tryParse(v) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : (isEdit ? 'Save' : 'Add account')),
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
    final currency = _currencyController.text.trim().toUpperCase();

    // Decimal string -> cents, at the one boundary where the user
    // actually types a decimal. round() here, not truncate, so
    // "12.505" doesn't silently lose a cent.
    final decimal = double.parse(_balanceController.text);
    final cents = (decimal * 100).round();

    if (widget.existing == null) {
      final userId = await LocalUserId.get();
      await db.insertAccount(
        userId: userId,
        name: name,
        type: _type,
        currency: currency,
        startingBalanceCents: cents,
      );
    } else {
      await db.updateAccount(
        id: widget.existing!.id,
        name: name,
        type: _type,
        currency: currency,
        startingBalanceCents: cents,
      );
    }

    if (mounted) Navigator.pop(context);
  }
}