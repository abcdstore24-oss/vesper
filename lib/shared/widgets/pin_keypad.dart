import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/theme/app_spacing.dart';

/// Numeric PIN entry pad: a row of filled/empty dots showing progress,
/// plus a 3x4 grid of digit buttons (0-9, backspace).
///
/// Used by both the lock screen (entering an existing PIN) and the PIN
/// setup screen (choosing/confirming a new one) — one shared widget
/// rather than duplicating this UI in each, per CLAUDE.md Section 8
/// rule 3. Added beyond this task's originally-listed files — see task
/// response. Registered in COMPONENTS.md.
///
/// Controlled component: the parent owns [value] and reacts to
/// [onDigit]/[onBackspace] rather than this widget holding its own
/// state, so callers can auto-submit, clear on error, etc.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.length,
    required this.value,
    required this.onDigit,
    required this.onBackspace,
  });

  /// Total PIN length — how many dots are shown.
  final int length;

  /// Digits entered so far.
  final String value;

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(length, (i) {
            final filled = i < value.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                border: Border.all(color: theme.colorScheme.outline),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [for (final key in row) _keyButton(theme, key)],
            ),
          ),
      ],
    );
  }

  Widget _keyButton(ThemeData theme, String key) {
    if (key.isEmpty) {
      return const SizedBox(width: 64, height: 64);
    }

    final isBackspace = key == '⌫';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              if (isBackspace) {
                onBackspace();
              } else if (value.length < length) {
                onDigit(key);
              }
            },
            child: Center(
              child: isBackspace
                  ? Icon(
                      PhosphorIconsRegular.backspace,
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                  : Text(key, style: theme.textTheme.headlineLarge),
            ),
          ),
        ),
      ),
    );
  }
}