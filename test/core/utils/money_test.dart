import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/utils/money.dart';

void main() {
  const String r = '\u20B9';

  group('constants', () {
    test('rupee symbol is U+20B9', () {
      expect(Money.rupeeSymbol, '\u20B9');
    });

    test('maxPaise is 10^14 (10^12 rupees)', () {
      expect(Money.maxPaise, 100000000000000);
    });
  });

  group('format', () {
    test('spec examples', () {
      expect(Money.format(0), '${r}0.00');
      expect(Money.format(5), '${r}0.05');
      expect(Money.format(125050), '${r}1,250.50');
      expect(Money.format(123456700), '${r}12,34,567.00');
      expect(Money.format(10000000000), '${r}10,00,00,000.00');
      expect(Money.format(-125050), '-${r}1,250.50');
    });

    test('alwaysShowSign', () {
      expect(Money.format(125050, alwaysShowSign: true), '+${r}1,250.50');
      expect(Money.format(0, alwaysShowSign: true), '${r}0.00');
      expect(Money.format(-125050, alwaysShowSign: true), '-${r}1,250.50');
    });

    test('symbol: false', () {
      expect(Money.format(125050, symbol: false), '1,250.50');
      expect(Money.format(-125050, symbol: false), '-1,250.50');
      expect(
        Money.format(125050, symbol: false, alwaysShowSign: true),
        '+1,250.50',
      );
      expect(Money.format(0, symbol: false), '0.00');
    });

    test('always exactly 2 decimals, never trimmed', () {
      expect(Money.format(1), '${r}0.01');
      expect(Money.format(10), '${r}0.10');
      expect(Money.format(100), '${r}1.00');
      expect(Money.format(-1), '-${r}0.01');
      expect(Money.format(-10), '-${r}0.10');
    });

    test('Indian grouping boundaries (rupees x 100 = paise)', () {
      expect(Money.format(99999 * 100), '${r}99,999.00');
      expect(Money.format(100000 * 100), '${r}1,00,000.00');
      expect(Money.format(9999999 * 100), '${r}99,99,999.00');
      expect(Money.format(10000000 * 100), '${r}1,00,00,000.00');
      expect(Money.format(999 * 100), '${r}999.00');
      expect(Money.format(1000 * 100), '${r}1,000.00');
    });

    test('maxPaise formats; one beyond throws', () {
      expect(Money.format(Money.maxPaise), '${r}10,00,00,00,00,000.00');
      expect(Money.format(-Money.maxPaise), '-${r}10,00,00,00,00,000.00');
      expect(() => Money.format(Money.maxPaise + 1), throwsArgumentError);
      expect(() => Money.format(-Money.maxPaise - 1), throwsArgumentError);
    });
  });

  group('parse accepts', () {
    test('spec examples', () {
      expect(Money.parse('1250'), 125000);
      expect(Money.parse('1,250.5'), 125050);
      expect(Money.parse('$r 12,34,567.89'), 123456789);
      expect(Money.parse('.5'), 50);
      expect(Money.parse('5.'), 500);
      expect(Money.parse('0'), 0);
    });

    test('symbol, spaces and decimals', () {
      expect(Money.parse('${r}5'), 500);
      expect(Money.parse('  5  '), 500);
      expect(Money.parse('  $r 5  '), 500);
      expect(Money.parse('0.05'), 5);
      expect(Money.parse('0.5'), 50);
      expect(Money.parse('0.00'), 0);
      expect(Money.parse('12.34'), 1234);
    });

    test('leading zeros are accepted', () {
      expect(Money.parse('007'), 700);
      expect(Money.parse('0000000000000000001'), 100);
    });

    test('negatives only when allowed', () {
      expect(Money.parse('-5', allowNegative: true), -500);
      expect(Money.parse('-${r}1,250.50', allowNegative: true), -125050);
      expect(Money.parse('-0', allowNegative: true), 0);
      expect(Money.parse('-.5', allowNegative: true), -50);
    });

    test('exactly maxPaise is accepted', () {
      expect(Money.parse('10,00,00,00,00,000.00'), Money.maxPaise);
      expect(Money.parse('1000000000000'), Money.maxPaise);
      expect(
        Money.parse('-1000000000000', allowNegative: true),
        -Money.maxPaise,
      );
    });
  });

  group('parse rejects (null)', () {
    test('empty and whitespace', () {
      expect(Money.parse(''), isNull);
      expect(Money.parse('   '), isNull);
      expect(Money.parse('\t\n'), isNull);
    });

    test('letters and junk', () {
      expect(Money.parse('abc'), isNull);
      expect(Money.parse('12a'), isNull);
      expect(Money.parse('a12'), isNull);
      expect(Money.parse('1e5'), isNull);
      expect(Money.parse('+5'), isNull);
      expect(Money.parse('5$r'), isNull);
      expect(Money.parse('$r${r}5'), isNull);
      expect(Money.parse('\u0663'), isNull); // Arabic-Indic digit three
    });

    test('lone symbols', () {
      expect(Money.parse('.'), isNull);
      expect(Money.parse(','), isNull);
      expect(Money.parse(r), isNull);
      expect(Money.parse('-', allowNegative: true), isNull);
      expect(Money.parse(',.5'), isNull);
    });

    test('3+ decimals are rejected, not rounded', () {
      expect(Money.parse('1.234'), isNull);
      expect(Money.parse('1.999'), isNull);
      expect(Money.parse('0.001'), isNull);
      expect(Money.parse('1.2000'), isNull);
    });

    test('multiple dots', () {
      expect(Money.parse('1.2.3'), isNull);
      expect(Money.parse('..5'), isNull);
    });

    test('minus handling', () {
      expect(Money.parse('--5'), isNull);
      expect(Money.parse('--5', allowNegative: true), isNull);
      expect(Money.parse('-5'), isNull); // allowNegative defaults to false
      expect(Money.parse('-5', allowNegative: false), isNull);
      expect(Money.parse('$r-5', allowNegative: true), isNull);
      expect(Money.parse('- 5', allowNegative: true), isNull);
      expect(Money.parse('5-', allowNegative: true), isNull);
    });

    test('comma after the dot', () {
      expect(Money.parse('1.5,0'), isNull);
      expect(Money.parse('1.,5'), isNull);
    });

    test('spaces inside the digits', () {
      expect(Money.parse('1 250'), isNull);
      expect(Money.parse('1, 250'), isNull);
      expect(Money.parse('1250 .50'), isNull);
      expect(Money.parse('1250. 50'), isNull);
    });

    test('anything over maxPaise', () {
      expect(Money.parse('10,00,00,00,00,000.01'), isNull);
      expect(Money.parse('1000000000001'), isNull);
      expect(Money.parse('9999999999999'), isNull);
      expect(Money.parse('10000000000000'), isNull);
      expect(Money.parse('99999999999999999999999999999'), isNull);
      expect(Money.parse('0' * 40 + '99999999999999999999'), isNull);
      expect(
        Money.parse('-1000000000000.01', allowNegative: true),
        isNull,
      );
    });
  });

  group('round trip', () {
    int roundTrip(int x) {
      final int? back = Money.parse(
        Money.format(x, symbol: false),
        allowNegative: true,
      );
      expect(back, isNotNull, reason: 'format($x) did not parse back');
      return back!;
    }

    test('named values and their negatives', () {
      const List<int> values = <int>[
        0,
        1,
        99,
        100,
        101,
        99999,
        100000,
        12345678,
        Money.maxPaise,
      ];
      for (final int v in values) {
        expect(roundTrip(v), v);
        expect(roundTrip(-v), -v);
      }
    });

    test('with the rupee symbol too', () {
      for (final int v in <int>[0, 5, 125050, -125050, Money.maxPaise]) {
        expect(Money.parse(Money.format(v), allowNegative: true), v);
      }
    });

    test('powers of ten and their neighbours', () {
      int p = 1;
      for (int k = 0; k <= 14; k++) {
        for (final int v in <int>[p - 1, p, p + 1]) {
          if (v > Money.maxPaise) continue;
          expect(roundTrip(v), v);
          expect(roundTrip(-v), -v);
        }
        p *= 10;
      }
    });

    test('1,000+ value sample never drifts', () {
      int checked = 0;

      // Dense run across every paise/rupee/thousand boundary near zero.
      for (int v = -1500; v <= 1500; v++) {
        expect(roundTrip(v), v);
        checked++;
      }

      // Sparse spread across the whole range (integer math only).
      for (int i = 1; i <= 1500; i++) {
        final int v = (i * 66666666661) % (Money.maxPaise + 1);
        expect(roundTrip(v), v);
        expect(roundTrip(-v), -v);
        checked += 2;
      }

      expect(checked, greaterThanOrEqualTo(1000));
    });
  });

  group('no floating-point drift', () {
    test('0.10 + 0.20 == 0.30', () {
      final int a = Money.parse('0.10')!;
      final int b = Money.parse('0.20')!;
      final int c = Money.parse('0.30')!;
      expect(a + b, c);
      expect(Money.format(a + b), '${r}0.30');
    });

    test('1.10 + 2.20 == 3.30', () {
      expect(Money.parse('1.10')! + Money.parse('2.20')!, Money.parse('3.30'));
    });
  });

  group('source guard (locked rules)', () {
    test('money.dart uses no floating-point or rounding APIs', () {
      final String source = File('lib/core/utils/money.dart').readAsStringSync();
      final String code = source
          .split('\n')
          .where((String line) => !line.trim().startsWith('//'))
          .join('\n');

      expect(RegExp(r'\bdouble\b').hasMatch(code), isFalse);
      expect(RegExp(r'\bnum\b').hasMatch(code), isFalse);
      expect(code.contains('Decimal'), isFalse);
      expect(code.contains('toStringAsFixed'), isFalse);
      expect(code.contains('.round('), isFalse);
      expect(code.contains('.toDouble'), isFalse);
      expect(code.contains('intl'), isFalse);
      // The only parse call allowed is int.parse.
      expect(RegExp(r'(?<!int)\.parse\(').hasMatch(code), isFalse);
    });
  });
}