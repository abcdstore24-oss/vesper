import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/features/finance/data/category_seeder.dart';
import 'package:vesper/features/finance/data/categories_table.dart';
import 'package:vesper/features/finance/presentation/category_choices.dart';
import 'package:vesper/features/finance/presentation/category_display.dart';

void main() {
  const systemKeys = {
    'arrow_up_right',
    'arrow_down_left',
    'hand_coins',
    'handshake',
    'trend_up',
    'trend_down',
  };

  group('icon choices', () {
    test('20 distinct keys, tag first (the default)', () {
      expect(categoryIconChoices, hasLength(20));
      expect(categoryIconChoices.toSet(), hasLength(20));
      expect(categoryIconChoices.first, 'tag');
    });

    test('no system key is offered', () {
      expect(categoryIconChoices.toSet().intersection(systemKeys), isEmpty);
    });

    test('every key is snake_case and has its own icon in the icon map', () {
      final shape = RegExp(r'^[a-z][a-z0-9_]*$');
      for (final key in categoryIconChoices) {
        expect(shape.hasMatch(key), isTrue, reason: key);
        // `tag` IS the fallback icon, so only the others can prove a mapping.
        if (key != 'tag') {
          expect(categoryIcon(key), isNot(categoryFallbackIcon), reason: key);
        }
      }
      expect(categoryIcon('tag'), categoryFallbackIcon);
    });

    test('covers every key the expense and income built-ins use', () {
      final used = {
        for (final c in defaultCategories)
          if (c.kind != CategoryKind.system) c.icon,
      };
      expect(categoryIconChoices.toSet().containsAll(used), isTrue);
    });
  });

  group('colour choices', () {
    test('12 distinct, opaque 0xFFRRGGBB values', () {
      expect(categoryColorChoices, hasLength(12));
      expect(categoryColorChoices.toSet(), hasLength(12));
      for (final c in categoryColorChoices) {
        expect(c >= 0xFF000000 && c <= 0xFFFFFFFF, isTrue, reason: '$c');
      }
    });

    test(
      'they are exactly the distinct colours of the expense/income built-ins',
      () {
        final used = <int>[];
        for (final c in defaultCategories) {
          if (c.kind != CategoryKind.system && !used.contains(c.color)) {
            used.add(c.color);
          }
        }
        expect(categoryColorChoices, used);
        expect(categoryColorChoices.first, 0xFFC97B84);
      },
    );
  });
}
