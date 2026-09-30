import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../data/investments_dao.dart';
import '../../../core/services/local_user_id.dart';

/// Quick, single-field action — only ever touches currentValueCents
/// (lastUpdatedAt is set automatically by
/// InvestmentsDao.updateCurrentValue). Deliberately separate from
/// InvestmentFormSheet — task response.
class UpdateValueDialog extends ConsumerStatefulWidget {
  const UpdateValueDialog({super.key, required this.investment});

  final InvestmentRow investment;

  @override
  ConsumerState<UpdateValueDialog> createState() => _UpdateValueDialogState();
}

class _UpdateValueDialogState extends ConsumerState<UpdateValueDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(
      text: (widget.investment.currentValueCents / 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update value — ${widget.investment.name}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _valueController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Current value (total)', hintText: '0.00'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Enter a value';
            final parsed = double.tryParse(v);
            if (parsed == null) return 'Enter a valid number';
            if (parsed < 0) return "Value can't be negative";
            return null;
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Update'),
        ),
      ],
    );
  }

    Future<void> _save() async {
      if (!_formKey.currentState!.validate()) return;
      setState(() => _saving = true);

      final db = ref.read(appDatabaseProvider);
      final cents = (double.parse(_valueController.text) * 100).round();
      final userId = await LocalUserId.get(); // NEW — updateCurrentValue now requires userId to record a snapshot
      await db.updateCurrentValue(userId: userId, id: widget.investment.id, currentValueCents: cents);

      if (mounted) Navigator.pop(context);
    }
}