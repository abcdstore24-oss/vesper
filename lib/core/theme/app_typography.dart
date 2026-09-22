import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Text style design tokens for Vesper.
///
/// Font families and their usage are locked by AI/CLAUDE.md, Section 3
/// ("Typography"):
///   - Fraunces (header/display): screen titles, section headers, large
///     numbers (e.g. balances, streaks).
///   - Karla (body/UI): body text, labels, buttons, form fields.
///
/// NOT LOCKED: CLAUDE.md specifies the font families and what each is
/// used for, but does not specify a numeric type scale (font sizes,
/// weights, or letter-spacing). The values below are a PROPOSED scale
/// only — see the pending DECISIONS.md entry for this task. Do not treat
/// these numbers as final/locked the way the font families and hex
/// colors are; they are open to the owner's revision without needing to
/// "supersede" a prior locked decision.
///
/// These are raw [TextStyle]s with no color set — color tokens
/// (AppColors) are applied where these styles are consumed (e.g. in
/// ThemeData, built in a later task), not here.
class AppTypography {
  const AppTypography._();

  /// Large numeric displays — balances, streaks. Fraunces.
  static TextStyle get displayLarge => GoogleFonts.fraunces(
        fontSize: 57,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        height: 1.12,
      );

  /// Screen titles. Fraunces.
  static TextStyle get headlineLarge => GoogleFonts.fraunces(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.25,
      );

  /// Section headers. Fraunces.
  static TextStyle get titleMedium => GoogleFonts.fraunces(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.3,
      );

  /// Body text. Karla.
  static TextStyle get bodyLarge => GoogleFonts.karla(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.5,
      );

  /// Secondary/meta body text. Karla.
  static TextStyle get bodyMedium => GoogleFonts.karla(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
      );

  /// Buttons, form labels. Karla.
  static TextStyle get labelLarge => GoogleFonts.karla(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      );
}
