import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Locked ThemeData for Vesper, built entirely from the tokens in
/// app_colors.dart, app_typography.dart, and app_spacing.dart.
///
/// This file only *consumes* those tokens — it must never introduce a
/// new color, font, or radius value of its own. Everywhere Material
/// requires something the token files don't define (e.g. on-accent text
/// color, disabled-state color, the non-locked TextTheme roles), the
/// value here is deliberately derived from an existing token rather than
/// left to a Flutter/Material default — see the task response for the
/// full list of these decisions, flagged for owner review the same way
/// the typography scale was.
///
/// The ColorScheme is built with the full explicit constructor (not
/// `ColorScheme.fromSeed`) specifically so nothing — not even
/// `secondary`/`tertiary` — is silently generated from the accent color;
/// every field below is either a direct token or a documented
/// derivation.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColorPalette c, Brightness brightness) {
    final colorScheme = _colorScheme(c, brightness);
    final textTheme = _textTheme(c);
    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.background,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      dividerColor: c.border,

      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.headlineLarge.copyWith(
          color: c.textPrimary,
        ),
      ),

      // CLAUDE.md Section 3 describes elevation as a soft, low-spread,
      // high-blur *shadow* (0.08 opacity light / lower + warmer black
      // dark), not Material 3's default surfaceTint overlay. Setting
      // surfaceTintColor: transparent keeps surface colors exactly as
      // locked. The precise blur/spread from CLAUDE.md can't be
      // expressed through ThemeData's single `elevation` number — that
      // needs a custom BoxShadow at the widget level when a real Card
      // component is built (see COMPONENTS.md). This is an
      // approximation, flagged in the task response.
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: isLight ? 0.08 : 0.24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: c.border),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        titleTextStyle: AppTypography.titleMedium.copyWith(
          color: c.textPrimary,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: c.textPrimary,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: colorScheme.onPrimary,
          // Not in the token set — derived as accent at Material's
          // standard 38% disabled-opacity convention, not a new hex.
          disabledBackgroundColor: c.accent.withValues(alpha: 0.38),
          disabledForegroundColor: colorScheme.onPrimary.withValues(alpha: 0.7),
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.accent,
          side: BorderSide(color: c.border),
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          textStyle: AppTypography.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: AppTypography.bodyLarge.copyWith(color: c.textSecondary),
        labelStyle: AppTypography.bodyLarge.copyWith(color: c.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: c.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: c.danger, width: 1.5),
        ),
      ),
    );
  }

    static ColorScheme _colorScheme(AppColorPalette c, Brightness brightness) {
      // Not in the locked token set: Material needs an "on-accent" and
      // "on-danger" color for text/icons drawn on top of those surfaces.
      // Derived from the palette's own background token (reads clearly on
      // both accent shades and on danger, in both themes) rather than
      // inventing a new white/black hex.
      final onAccent = c.background;

      return ColorScheme(
        brightness: brightness,
        primary: c.accent,
        onPrimary: onAccent,
        // CLAUDE.md Section 3: "the one accent" — Vesper has no locked
        // secondary color, so it maps to accent rather than letting
        // Material derive a second hue from it.
        secondary: c.accent,
        onSecondary: onAccent,
        error: c.danger,
        onError: onAccent,
        surface: c.surface,
        onSurface: c.textPrimary,
        // ignore: deprecated_member_use
        background: c.background,
        // ignore: deprecated_member_use
        onBackground: c.textPrimary,
        // ignore: deprecated_member_use
        surfaceVariant: c.surfaceVariant,
        onSurfaceVariant: c.textSecondary,
        // surfaceVariant's non-deprecated Material 3 replacement — set
        // explicitly to the same locked token, not left to Flutter's own
        // computed default, so call sites can use the current API name
        // without pulling in an untracked color. See DECISIONS.md.
        surfaceContainerHighest: c.surfaceVariant,
        outline: c.border,
      );
    }
    
  static TextTheme _textTheme(AppColorPalette c) {
    // Material's TextTheme has 13 roles; CLAUDE.md/AppTypography only
    // locks 6. The rest fall back to GoogleFonts.karlaTextTheme()'s own
    // Material-standard sizes (Karla being the locked body/UI font),
    // rather than the system font — but those sizes are not a locked
    // decision, only the 6 named roles below are.
    final base = GoogleFonts.karlaTextTheme();

    return base
        .copyWith(
          displayLarge: AppTypography.displayLarge.copyWith(
            color: c.textPrimary,
          ),
          headlineLarge: AppTypography.headlineLarge.copyWith(
            color: c.textPrimary,
          ),
          titleMedium: AppTypography.titleMedium.copyWith(
            color: c.textPrimary,
          ),
          bodyLarge: AppTypography.bodyLarge.copyWith(color: c.textPrimary),
          bodyMedium: AppTypography.bodyMedium.copyWith(color: c.textPrimary),
          labelLarge: AppTypography.labelLarge.copyWith(color: c.textPrimary),
        )
        .apply(bodyColor: c.textPrimary, displayColor: c.textPrimary);
  }
}