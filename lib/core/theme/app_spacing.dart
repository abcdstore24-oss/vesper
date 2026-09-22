/// Locked 4px spacing grid for Vesper.
///
/// Source of truth: AI/CLAUDE.md, Section 3 ("Design system" →
/// "Shape & elevation"): "Spacing grid: multiples of 4px, with
/// 8/12/16/24/32 as the standard step sizes used throughout layouts."
class AppSpacing {
  const AppSpacing._();

  /// 4px — the base unit of the grid.
  static const double xs = 4;

  /// 8px
  static const double sm = 8;

  /// 12px
  static const double md = 12;

  /// 16px
  static const double lg = 16;

  /// 24px
  static const double xl = 24;

  /// 32px
  static const double xxl = 32;
}

/// Locked corner radii for Vesper.
///
/// Source of truth: AI/CLAUDE.md, Section 3 ("Design system" →
/// "Shape & elevation"): "Corner radius: 20px for cards/sheets, 14px for
/// buttons/inputs, 999px (full) for chips/pills." This shape language is
/// the same across light and dark themes — only color tokens change
/// between themes, never shape.
class AppRadius {
  const AppRadius._();

  /// 20px — cards, sheets, dialogs.
  static const double card = 20;

  /// 14px — buttons, inputs.
  static const double control = 14;

  /// 999px (full) — chips, pills.
  static const double pill = 999;
}
