import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/theme/app_colors.dart';
import 'package:vesper/core/theme/app_spacing.dart';

import '../../support/ui_test_helpers.dart';

void main() {
  setUpAll(disableFontFetching);

  // Only cheap, font-free data is built while this file loads. AppTheme.light
  // and AppTheme.dark go through google_fonts, so they are built INSIDE each
  // test body, in the same environment the other widget tests use.
  final cases = <(String name, bool isDark, AppColorPalette palette)>[
    ('light', false, AppColors.light),
    ('dark', true, AppColors.dark),
  ];

  for (final (name, isDark, palette) in cases) {
    group('$name theme', () {
      testWidgets('dividers use the border token (not near-white)', (
        tester,
      ) async {
        final theme = buildTestTheme(
          isDark ? Brightness.dark : Brightness.light,
        );

        expect(theme.dividerTheme.color, palette.border);
        expect(theme.dividerTheme.thickness, 1);
        expect(theme.dividerTheme.space, 1);
        expect(theme.colorScheme.outlineVariant, palette.border);
      });

      testWidgets('bottom sheets: surface, drag handle, 20px top corners', (
        tester,
      ) async {
        final theme = buildTestTheme(
          isDark ? Brightness.dark : Brightness.light,
        );

        final sheet = theme.bottomSheetTheme;
        expect(sheet.backgroundColor, palette.surface);
        expect(sheet.modalBackgroundColor, palette.surface);
        expect(sheet.surfaceTintColor, Colors.transparent);
        expect(sheet.showDragHandle, isTrue);
        expect(
          sheet.shape,
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.card),
            ),
          ),
        );
      });

      testWidgets('chips: pill, border, no checkmark, accent when selected', (
        tester,
      ) async {
        final theme = buildTestTheme(
          isDark ? Brightness.dark : Brightness.light,
        );

        final chip = theme.chipTheme;
        expect(chip.backgroundColor, palette.surfaceVariant);
        expect(chip.selectedColor, palette.accent.withValues(alpha: 0.18));
        expect(chip.side, BorderSide(color: palette.border));
        expect(chip.shape, const StadiumBorder());
        expect(chip.showCheckmark, isFalse);
        expect(chip.labelStyle?.color, palette.textPrimary);
      });

      testWidgets('buildTestTheme returns the matching brightness', (
        tester,
      ) async {
        final theme = buildTestTheme(
          isDark ? Brightness.dark : Brightness.light,
        );
        expect(theme.brightness, isDark ? Brightness.dark : Brightness.light);
      });
    });
  }
}
