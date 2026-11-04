import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Shown for an icon key the app doesn't know (or a missing one).
const IconData categoryFallbackIcon = PhosphorIconsRegular.tag;

/// Category icon KEYS (what the database stores, snake_case) to Phosphor
/// regular icons. Covers every key used by the default categories (expense,
/// income and system), plus keys the app may store later.
const Map<String, IconData> _categoryIcons = <String, IconData>{
  // Expense defaults
  'fork_knife': PhosphorIconsRegular.forkKnife,
  'shopping_cart': PhosphorIconsRegular.shoppingCart,
  'car': PhosphorIconsRegular.car,
  'receipt': PhosphorIconsRegular.receipt,
  'house': PhosphorIconsRegular.house,
  'shopping_bag': PhosphorIconsRegular.shoppingBag,
  'heartbeat': PhosphorIconsRegular.heartbeat,
  'graduation_cap': PhosphorIconsRegular.graduationCap,
  'film_slate': PhosphorIconsRegular.filmSlate,
  'airplane': PhosphorIconsRegular.airplane,
  'repeat': PhosphorIconsRegular.repeat,
  'sparkle': PhosphorIconsRegular.sparkle,
  'gift': PhosphorIconsRegular.gift,
  'dots_three': PhosphorIconsRegular.dotsThree,
  // Income defaults
  'briefcase': PhosphorIconsRegular.briefcase,
  'storefront': PhosphorIconsRegular.storefront,
  'piggy_bank': PhosphorIconsRegular.piggyBank,
  'arrow_u_up_left': PhosphorIconsRegular.arrowUUpLeft,
  // System defaults (loans and investments)
  'arrow_up_right': PhosphorIconsRegular.arrowUpRight,
  'arrow_down_left': PhosphorIconsRegular.arrowDownLeft,
  'hand_coins': PhosphorIconsRegular.handCoins,
  'handshake': PhosphorIconsRegular.handshake,
  'trend_up': PhosphorIconsRegular.trendUp,
  'trend_down': PhosphorIconsRegular.trendDown,
  // Keys the app may store later (user-made categories)
  'paw_print': PhosphorIconsRegular.pawPrint,
  'tag': PhosphorIconsRegular.tag,
};

/// The Phosphor icon for a category icon KEY; [categoryFallbackIcon] for an
/// unknown or missing key.
IconData categoryIcon(String? key) {
  if (key == null) return categoryFallbackIcon;
  return _categoryIcons[key] ?? categoryFallbackIcon;
}
