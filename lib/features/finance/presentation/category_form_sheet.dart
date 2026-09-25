import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/category_kind.dart';
import '../domain/category_style.dart';
import '../data/categories_dao.dart';

class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({super.key, this.existing});

  final CategoryRow? existing;

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late CategoryKind _kind;
  late String _iconKey;
  late String _colorHex;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _kind = existing != null ? CategoryKind.values.byName(existing.kind) : CategoryKind.expense;
    _iconKey = existing?.icon ?? CategoryIcons.options.keys.first;
    _colorHex = existing?.color ?? CategoryPalette.swatches.first.lightHex;
  }

  @override
  void dispose() {
    _nameController.dispose();
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isEdit ? 'Edit category' : 'New category', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<CategoryKind>(
                initialValue: _kind,
                decoration: const InputDecoration(labelText: 'Kind'),
                items: [
                  for (final k in CategoryKind.values) DropdownMenuItem(value: k, child: Text(k.label)),
                ],
                onChanged: (v) => setState(() => _kind = v ?? _kind),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Icon', style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final entry in CategoryIcons.options.entries)
                    _IconChoice(
                      icon: entry.value,
                      selected: entry.key == _iconKey,
                      onTap: () => setState(() => _iconKey = entry.key),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Color', style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final swatch in CategoryPalette.swatches)
                    _ColorChoice(
                      hex: theme.brightness == Brightness.dark ? swatch.darkHex : swatch.lightHex,
                      selected: swatch.lightHex == _colorHex,
                      onTap: () => setState(() => _colorHex = swatch.lightHex),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : (isEdit ? 'Save' : 'Add category')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final db = ref.read(appDatabaseProvider);
    final name = _nameController.text.trim();

    if (widget.existing == null) {
      final userId = await LocalUserId.get();
      await db.insertCategory(userId: userId, name: name, iconKey: _iconKey, colorHex: _colorHex, kind: _kind);
    } else {
      await db.updateCategory(id: widget.existing!.id, name: name, iconKey: _iconKey, colorHex: _colorHex, kind: _kind);
    }

    if (mounted) Navigator.pop(context);
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({required this.icon, required this.selected, required this.onTap});
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          // ignore: deprecated_member_use — matches app_theme.dart's
          // own established pattern: this is the locked surfaceVariant
          // token via ColorScheme, not a Material default. Swapping to
          // surfaceContainerHighest would pull in an unset/unintended
          // color instead (see task response).
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: selected ? Border.all(color: theme.colorScheme.primary, width: 1.5) : null,
        ),
        child: Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({required this.hex, required this.selected, required this.onTap});
  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = CategoryPalette.colorFromHex(hex);
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected ? Border.all(color: theme.colorScheme.onSurface, width: 2) : null,
        ),
      ),
    );
  }
}