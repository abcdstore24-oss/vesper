import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// One choice in a [showPickerSheet] list.
class PickerItem<T> {
  const PickerItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.icon,
  });

  final T value;
  final String title;
  final String? subtitle;
  final IconData? icon;
}

/// Opens a bottom sheet to choose ONE item from a list that can be long
/// (100+ rows). Returns the chosen value, or null if dismissed.
///
/// - A search box ("Search") appears only when there are MORE than
///   [searchThreshold] items; it filters titles case-insensitively with
///   "contains", in Dart, on every change.
/// - The list is built lazily (only the visible rows exist) and every row has
///   the same height, so it stays fast with hundreds of items.
/// - The [selected] row shows a check.
///
/// Registered in COMPONENTS.md.
Future<T?> showPickerSheet<T>(
  BuildContext context, {
  required String title,
  required List<PickerItem<T>> items,
  T? selected,
  int searchThreshold = 8,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => PickerSheet<T>(
      title: title,
      items: items,
      selected: selected,
      searchThreshold: searchThreshold,
    ),
  );
}

/// The content of [showPickerSheet]. Public so tests can find it.
class PickerSheet<T> extends StatefulWidget {
  const PickerSheet({
    super.key,
    required this.title,
    required this.items,
    this.selected,
    this.searchThreshold = 8,
  });

  final String title;
  final List<PickerItem<T>> items;
  final T? selected;
  final int searchThreshold;

  @override
  State<PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<PickerSheet<T>> {
  final TextEditingController _search = TextEditingController();

  // Lower-cased titles, built once, so a keystroke only scans strings.
  late final List<String> _lowerTitles = [
    for (final item in widget.items) item.title.toLowerCase(),
  ];

  /// Indexes (into widget.items) of the rows matching the search, or null
  /// when there is no search text (all rows).
  List<int>? _matches;

  bool get _showSearch => widget.items.length > widget.searchThreshold;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    final query = text.trim().toLowerCase();
    setState(() {
      _matches = query.isEmpty
          ? null
          : [
              for (var i = 0; i < _lowerTitles.length; i++)
                if (_lowerTitles[i].contains(query)) i,
            ];
    });
  }

  /// One fixed row height (so the list needs no per-row measuring), sized
  /// for the user's text scale.
  double _rowExtent(ThemeData theme, TextScaler scaler, bool hasSubtitle) {
    double line(TextStyle? style, double size, double height) =>
        scaler.scale((style?.fontSize ?? size) * (style?.height ?? height));
    final text =
        line(theme.textTheme.bodyLarge, 16, 1.5) +
        (hasSubtitle ? line(theme.textTheme.bodyMedium, 14, 1.43) : 0.0);
    return math.max(56.0, math.max(text, 40.0) + 2 * AppSpacing.md);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final muted = theme.colorScheme.onSurfaceVariant;
    final matches = _matches;
    final count = matches?.length ?? widget.items.length;
    final hasSubtitle = widget.items.any((i) => i.subtitle != null);
    final extent = _rowExtent(
      theme,
      MediaQuery.textScalerOf(context),
      hasSubtitle,
    );

    return Padding(
      // Keeps the list and the search box above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Text(widget.title, style: theme.textTheme.titleMedium),
            ),
            if (_showSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: TextField(
                  key: const ValueKey('picker_search'),
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: 'Search',
                    prefixIcon: Icon(
                      PhosphorIconsRegular.magnifyingGlass,
                      color: muted,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            if (count == 0)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'No matches',
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              )
            else
              Flexible(
                // Lazy: only the rows in view are built. The fixed itemExtent
                // lets the list size itself without building every row.
                child: ListView.builder(
                  shrinkWrap: true,
                  itemExtent: extent,
                  itemCount: count,
                  itemBuilder: (context, index) {
                    final itemIndex = matches == null ? index : matches[index];
                    final item = widget.items[itemIndex];
                    return _PickerRow<T>(
                      key: ValueKey('picker_row_$itemIndex'),
                      item: item,
                      selected: item.value == widget.selected,
                      surface: palette.surfaceVariant,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PickerRow<T> extends StatelessWidget {
  const _PickerRow({
    super.key,
    required this.item,
    required this.selected,
    required this.surface,
  });

  final PickerItem<T> item;
  final bool selected;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: () => Navigator.of(context).pop(item.value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            if (item.icon != null) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (item.subtitle != null)
                    Text(
                      item.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                ],
              ),
            ),
            if (selected) ...[
              const SizedBox(width: AppSpacing.md),
              Icon(
                PhosphorIconsRegular.check,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
