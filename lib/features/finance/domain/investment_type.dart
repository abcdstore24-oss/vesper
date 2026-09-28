import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

enum InvestmentType {
  stock,
  crypto,
  realEstate,
  other;

  String get label => switch (this) {
    InvestmentType.stock => 'Stock',
    InvestmentType.crypto => 'Crypto',
    InvestmentType.realEstate => 'Real Estate',
    InvestmentType.other => 'Other',
  };

  IconData get icon => switch (this) {
    InvestmentType.stock => PhosphorIconsRegular.chartLineUp,
    InvestmentType.crypto => PhosphorIconsRegular.currencyBtc,
    InvestmentType.realEstate => PhosphorIconsRegular.house,
    InvestmentType.other => PhosphorIconsRegular.briefcase,
  };

  /// Formats a quantity for display — trims trailing zeros ("10.0" ->
  /// "10", "0.50" -> "0.5") without ever emitting scientific notation.
  ///
  /// Real bug fixed here: Dart's double.toString() switches to
  /// exponential notation for very small magnitudes (e.g. 0.00000001
  /// -> "1e-8"), which is plausible input for crypto quantities
  /// specifically. If toString() would contain 'e'/'E', this falls
  /// back to a fixed-decimal representation (8 decimal places, then
  /// trims trailing zeros the same way) instead of the raw result.
  ///
  /// Lives here rather than on the per-investment screens (was
  /// duplicated in investment_form_sheet.dart and
  /// investments_list_screen.dart) — this is per-type-independent
  /// formatting logic, not per-type data, but InvestmentType is
  /// still the shared, already-imported home for investment-domain
  /// helpers, so a static method here beats a third copy or a new
  /// file for one function.
  static String formatQuantity(double q) {
    var s = q.toString();
    if (s.contains('e') || s.contains('E')) {
      s = q.toStringAsFixed(8);
    }
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s;
  }
}