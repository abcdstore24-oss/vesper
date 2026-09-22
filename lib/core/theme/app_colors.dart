import 'package:flutter/material.dart';

/// Locked color design tokens for Vesper.
///
/// Source of truth: AI/CLAUDE.md, Section 3 ("Design system" → "Color").
/// Every value here is copied verbatim from the locked light/dark tables.
/// Do not add, remove, or change any token or value without updating
/// CLAUDE.md first (see CLAUDE.md Section 8, Rule 4).
class AppColors {
  const AppColors._();

  /// Light mode palette.
  static const AppColorPalette light = AppColorPalette(
    background: Color(0xFFFAF8F5),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF1ECE6),
    textPrimary: Color(0xFF1E1B22),
    textSecondary: Color(0xFF6E6875),
    border: Color(0xFFE4DED6),
    accent: Color(0xFF5B4B8A),
    success: Color(0xFF3F7D58),
    danger: Color(0xFFB3483F),
  );

  /// Dark mode palette.
  static const AppColorPalette dark = AppColorPalette(
    background: Color(0xFF131118),
    surface: Color(0xFF1D1A23),
    surfaceVariant: Color(0xFF26222E),
    textPrimary: Color(0xFFF3F0F7),
    textSecondary: Color(0xFFA8A2B3),
    border: Color(0xFF332E3D),
    accent: Color(0xFF9683E8),
    success: Color(0xFF6FBE8C),
    danger: Color(0xFFE08277),
  );
}

/// One theme's worth of color tokens.
///
/// `accent` is the one accent color — reserved for CTAs, active states,
/// and links only (CLAUDE.md Section 3). It is not a general-purpose
/// color and must not be reused for decorative purposes elsewhere.
class AppColorPalette {
  const AppColorPalette({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.accent,
    required this.success,
    required this.danger,
  });

  /// App background.
  final Color background;

  /// Cards, sheets, dialogs.
  final Color surface;

  /// Subtle section backgrounds.
  final Color surfaceVariant;

  /// Primary text.
  final Color textPrimary;

  /// Secondary/meta text.
  final Color textSecondary;

  /// Dividers, outlines.
  final Color border;

  /// The one accent — CTAs, active states, links only.
  final Color accent;

  /// Positive amounts, completed states.
  final Color success;

  /// Destructive actions, negative amounts.
  final Color danger;
}
