import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// One entry in Vesper's fixed category color swatch set — the
/// "deliberate exception" CLAUDE.md Section 3 carves out for category
/// colors, approved 2026-09-25 (see the DATABASE.md addition flagged
/// in the task response).
///
/// [lightHex] is the only value ever stored (categories.color);
/// [darkHex] is looked up from it at render time via
/// [CategoryPalette.darkHexFor] — a category row never stores two
/// colors.
class CategorySwatch {
  const CategorySwatch(this.lightHex, this.darkHex);
  final String lightHex;
  final String darkHex;
}

/// Fixed 8-swatch category color palette, owner-approved. Both default
/// and custom categories pick from this list only — no free hex entry.
class CategoryPalette {
  const CategoryPalette._();

  static const swatches = <CategorySwatch>[
    CategorySwatch('#966E40', '#D9AC78'), // Food
    CategorySwatch('#4E6D97', '#8CACD9'), // Transport
    CategorySwatch('#82745E', '#B7A78F'), // Bills
    CategorySwatch('#637E44', '#A1C775'), // Salary
    CategorySwatch('#96547B', '#D491B8'), // Shopping
    CategorySwatch('#428080', '#70C2C2'), // Health
    CategorySwatch('#A48D46', '#DBC480'), // Entertainment
    CategorySwatch('#8A8075', '#B3A89E'), // Other
  ];

  static String darkHexFor(String lightHex) {
    for (final s in swatches) {
      if (s.lightHex.toUpperCase() == lightHex.toUpperCase()) return s.darkHex;
    }
    return lightHex;
  }

  /// Single shared hex→Color parser — was duplicated identically in
  /// categories_list_screen.dart and category_form_sheet.dart (twice,
  /// for the icon-chip swatch dot and the color-chip swatch), now
  /// defined once here per the review note.
  static Color colorFromHex(String hex) =>
      Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
}

/// Icon options for the category picker grid, plus the key↔IconData
/// lookup used to render a stored category.icon value. Broader than
/// just the 8 defaults' icons — a custom category can use any of
/// these, per the task's "grid of Phosphor icons" request. Keys match
/// phosphoricons_flutter's identifier names.
class CategoryIcons {
  const CategoryIcons._();

  static const Map<String, IconData> options = {
    'forkKnife': PhosphorIconsRegular.forkKnife,
    'carSimple': PhosphorIconsRegular.carSimple,
    'receipt': PhosphorIconsRegular.receipt,
    'handCoins': PhosphorIconsRegular.handCoins,
    'shoppingBag': PhosphorIconsRegular.shoppingBag,
    'heartbeat': PhosphorIconsRegular.heartbeat,
    'filmSlate': PhosphorIconsRegular.filmSlate,
    'archiveBox': PhosphorIconsRegular.archiveBox,
    'house': PhosphorIconsRegular.house,
    'gift': PhosphorIconsRegular.gift,
    'briefcase': PhosphorIconsRegular.briefcase,
    'graduationCap': PhosphorIconsRegular.graduationCap,
    'airplane': PhosphorIconsRegular.airplane,
    'pawPrint': PhosphorIconsRegular.pawPrint,
    'shieldCheck': PhosphorIconsRegular.shieldCheck,
    'piggyBank': PhosphorIconsRegular.piggyBank,
    'wrench': PhosphorIconsRegular.wrench,
    'gasPump': PhosphorIconsRegular.gasPump,
    'bus': PhosphorIconsRegular.bus,
    'coffee': PhosphorIconsRegular.coffee,
    'book': PhosphorIconsRegular.book,
    'heart': PhosphorIconsRegular.heart,
    'tag': PhosphorIconsRegular.tag,
    'creditCard': PhosphorIconsRegular.creditCard,
    'bank': PhosphorIconsRegular.bank,
    'wallet': PhosphorIconsRegular.wallet,
  };

  static IconData forKey(String key) => options[key] ?? PhosphorIconsRegular.tag;
}