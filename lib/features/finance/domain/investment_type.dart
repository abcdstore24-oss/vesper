import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/db/app_database.dart'; // NEW — CategoryRow, for preferredFundingCategory

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
  /// See git history / DECISIONS.md for the scientific-notation fix
  /// this method absorbed (was duplicated in two presentation files
  /// before being consolidated here).
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

  /// NEW this task — moved here from a short-lived separate
  /// category_defaults.dart file, per the same "one small shared
  /// helper doesn't need its own file" precedent formatQuantity above
  /// already set.
  ///
  /// The category investment_form_sheet.dart's and
  /// buy_more_investment_sheet.dart's funding-category pickers should
  /// default to, given an already-filtered list of expense-kind
  /// categories. Prefers the category named exactly "Investment
  /// Purchase" (case-sensitive — a fixed name this project controls
  /// via category_seeder.dart, so an exact match is deliberate; a
  /// looser match would risk silently preferring an unrelated
  /// user-created category with a similar name); falls back to
  /// [expenseCategories].first (alphabetically first, since both call
  /// sites source this list from categoriesProvider) if that category
  /// was ever deleted or renamed. Returns null only if
  /// [expenseCategories] is itself empty — neither call site should
  /// actually reach that case, since both already show a "no expense
  /// categories yet" message and return before computing a default at
  /// all when the list is empty.
  static CategoryRow? preferredFundingCategory(List<CategoryRow> expenseCategories) {
    if (expenseCategories.isEmpty) return null;
    const targetName = 'Investment Purchase';
    for (final c in expenseCategories) {
      if (c.name == targetName) return c;
    }
    return expenseCategories.first;
  }
}