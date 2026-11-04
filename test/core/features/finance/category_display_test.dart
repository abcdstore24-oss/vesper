import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:vesper/features/finance/data/category_seeder.dart';
import 'package:vesper/features/finance/presentation/category_display.dart';

void main() {
  test('every icon key used by a default category has a real mapping', () {
    expect(defaultCategories, isNotEmpty);
    for (final c in defaultCategories) {
      expect(
        categoryIcon(c.icon),
        isNot(categoryFallbackIcon),
        reason: '${c.seedKey} uses the unmapped icon key "${c.icon}"',
      );
    }
  });

  test('known keys map to the right Phosphor icons', () {
    expect(categoryIcon('fork_knife'), PhosphorIconsRegular.forkKnife);
    expect(categoryIcon('shopping_cart'), PhosphorIconsRegular.shoppingCart);
    expect(categoryIcon('arrow_u_up_left'), PhosphorIconsRegular.arrowUUpLeft);
    expect(categoryIcon('trend_down'), PhosphorIconsRegular.trendDown);
    expect(categoryIcon('paw_print'), PhosphorIconsRegular.pawPrint);
  });

  test('an unknown or missing key falls back to a neutral icon', () {
    expect(categoryIcon('no_such_icon'), categoryFallbackIcon);
    expect(categoryIcon(''), categoryFallbackIcon);
    expect(categoryIcon(null), categoryFallbackIcon);
    expect(categoryFallbackIcon, PhosphorIconsRegular.tag);
  });
}
