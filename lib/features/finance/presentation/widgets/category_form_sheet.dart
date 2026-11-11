import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/db/db_provider.dart';
import '../../../../core/db/local_user_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/categories_dao.dart';
import '../../data/categories_table.dart';
import '../category_choices.dart';
import '../category_display.dart';

/// Opens the add-category sheet for [kind], or the edit sheet when
/// [category] is given (then [kind] is the category's own kind).
Future<void> showCategoryFormSheet(
  BuildContext context, {
  required CategoryKind kind,
  CategoryRow? category,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => CategoryFormSheet(kind: kind, category: category),
  );
}

/// Add / edit a category. Saves through [CategoriesDao]; the lists update
/// through their streams, so nothing here refreshes anything.
///
/// - The kind is fixed: it comes from the screen when adding, and is shown as
///   read-only text when editing. A built-in category (it has a seed_key) says
///   so; its seed_key never changes.
/// - The icon and colour choices are the palettes in category_choices.dart.
/// - Edit mode has an "Archive category" / "Restore category" button (no
///   confirmation: it is reversible). Nothing is ever deleted.
///
/// Registered in COMPONENTS.md.
class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({super.key, required this.kind, this.category});

  final CategoryKind kind;

  /// The category being edited, or null to add a new one.
  final CategoryRow? category;

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  late final TextEditingController _name;
  late String _icon;
  late int _color;

  bool _busy = false;
  // Set synchronously at the start of _save / _toggleArchived, before any
  // rebuild, so a second tap in the same frame can never start a second
  // action. Reset after every failure.
  bool _actionStarted = false;

  String? _nameError;
  String? _formError;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _name = TextEditingController(text: category?.name ?? '');
    _icon = category?.icon ?? categoryIconChoices.first;
    _color = category?.color ?? categoryColorChoices.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Re-enables everything after a failure and shows the message.
  void _fail({String? nameError, String? formError}) {
    setState(() {
      _busy = false;
      _actionStarted = false;
      _nameError = nameError;
      _formError = formError;
    });
  }

  Future<void> _save() async {
    if (_actionStarted) return;
    _actionStarted = true;

    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameError = 'Enter a name';
        _formError = null;
      });
      _actionStarted = false;
      return;
    }

    setState(() {
      _busy = true;
      _nameError = null;
      _formError = null;
    });

    try {
      final dao = CategoriesDao(ref.read(appDatabaseProvider));
      final existing = widget.category;
      if (existing == null) {
        final userId = await ref.read(localUserIdProvider.future);
        await dao.create(
          userId: userId,
          name: name,
          kind: widget.kind,
          icon: _icon,
          color: _color,
        );
      } else {
        await dao.edit(existing.id, name: name, icon: _icon, color: _color);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on CategoryValidationException catch (e) {
      if (!mounted) return;
      switch (e.error) {
        case CategoryValidationError.emptyName:
          _fail(nameError: 'Enter a name');
        case CategoryValidationError.nameTooLong:
          _fail(nameError: 'Keep the name to 40 characters or fewer');
        case CategoryValidationError.duplicateName:
          _fail(nameError: 'You already have a category with that name');
        case CategoryValidationError.duplicateNameArchived:
          _fail(nameError: 'A category with that name is in Archived');
        default:
          _fail(formError: "Couldn't save. Please try again.");
      }
    } catch (_) {
      // Deliberately no logging: names are user data.
      if (!mounted) return;
      _fail(formError: "Couldn't save. Please try again.");
    }
  }

  Future<void> _toggleArchived() async {
    final existing = widget.category;
    if (existing == null || _actionStarted) return;
    _actionStarted = true;
    setState(() {
      _busy = true;
      _nameError = null;
      _formError = null;
    });

    // Captured before the sheet closes, so the SnackBar can still be shown.
    final messenger = ScaffoldMessenger.of(context);
    final archive = !existing.isArchived;
    try {
      await CategoriesDao(
        ref.read(appDatabaseProvider),
      ).setArchived(existing.id, archive);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(archive ? 'Category archived' : 'Category restored'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _fail(formError: "Couldn't save. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final muted = theme.colorScheme.onSurfaceVariant;
    final accent = theme.colorScheme.primary;
    final existing = widget.category;
    final kindWord = widget.kind == CategoryKind.income ? 'Income' : 'Expense';

    Widget iconChoice(String key) {
      final selected = _icon == key;
      return Semantics(
        button: true,
        selected: selected,
        label: key.replaceAll('_', ' '),
        child: InkResponse(
          key: ValueKey('cat_icon_$key'),
          onTap: _busy ? null : () => setState(() => _icon = key),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? accent.withValues(alpha: 0.18)
                  : palette.surfaceVariant,
              border: Border.all(
                color: selected ? accent : palette.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Icon(
              categoryIcon(key),
              size: 22,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      );
    }

    Widget colorChoice(int value) {
      final selected = _color == value;
      return Semantics(
        button: true,
        selected: selected,
        label: 'Colour',
        child: InkResponse(
          key: ValueKey('cat_color_${value.toRadixString(16).toUpperCase()}'),
          onTap: _busy ? null : () => setState(() => _color = value),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? accent : Colors.transparent,
                width: 2,
              ),
            ),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(value),
              ),
              child: selected
                  ? const Icon(
                      PhosphorIconsRegular.check,
                      size: 18,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
        ),
      );
    }

    return Padding(
      // Keeps the button above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? 'Edit category' : 'Add category',
              style: theme.textTheme.titleMedium,
            ),
            if (existing != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$kindWord category',
                key: const ValueKey('cat_kind_text'),
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
              if (existing.seedKey != null)
                Text(
                  'Built-in category',
                  key: const ValueKey('cat_builtin_text'),
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
            ],
            const SizedBox(height: AppSpacing.lg),
            // Live preview: the chosen icon in the chosen colour.
            Center(
              child: Container(
                key: const ValueKey('cat_preview'),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Color(_color).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  categoryIcon(_icon),
                  size: 28,
                  color: Color(_color),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              key: const ValueKey('cat_name_field'),
              controller: _name,
              autofocus: !_isEdit,
              enabled: !_busy,
              maxLength: 40,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Name',
                counterText: '',
                errorText: _nameError,
                errorMaxLines: 2,
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Icon',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final key in categoryIconChoices) iconChoice(key),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Colour',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final value in categoryColorChoices) colorChoice(value),
              ],
            ),
            if (_formError != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _formError!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: _busy ? null : _save,
              child: Text(_isEdit ? 'Save changes' : 'Add category'),
            ),
            // Edit mode only. Neutral (not the danger colour): archiving is
            // reversible, so there is no confirmation either.
            if (existing != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                key: const ValueKey('cat_archive_button'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                ),
                onPressed: _busy ? null : _toggleArchived,
                child: Text(
                  existing.isArchived ? 'Restore category' : 'Archive category',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
