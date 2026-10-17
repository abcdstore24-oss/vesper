import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:vesper/core/theme/app_colors.dart';
import 'package:vesper/core/utils/money.dart';
import 'package:vesper/shared/widgets/amount_text.dart';

import '../../support/ui_test_helpers.dart';

void main() {
  setUpAll(disableFontFetching);

  Future<void> pumpAmount(
    WidgetTester tester,
    Widget amount, {
    double width = 300,
    Brightness brightness = Brightness.light,
  }) {
    return pumpUi(
      tester,
      Scaffold(
        body: Center(child: SizedBox(width: width, child: amount)),
      ),
      brightness: brightness,
    );
  }

  testWidgets('shows Money.format output', (tester) async {
    await pumpAmount(tester, const AmountText(125050));
    expect(find.text('\u20B91,250.50'), findsOneWidget);
    expect(Money.format(125050), '\u20B91,250.50');
  });

  testWidgets('negative amounts keep their minus sign', (tester) async {
    await pumpAmount(tester, const AmountText(-125050));
    expect(find.text('-\u20B91,250.50'), findsOneWidget);
  });

  testWidgets('maxPaise still formats', (tester) async {
    await pumpAmount(tester, const AmountText(Money.maxPaise));
    expect(find.text('\u20B910,00,00,00,00,000.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('too large shows "Amount too large", never crashes', (
    tester,
  ) async {
    await pumpAmount(tester, const AmountText(Money.maxPaise + 1));
    expect(find.text('Amount too large'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpAmount(tester, const AmountText(-Money.maxPaise - 1));
    expect(find.text('Amount too large'), findsOneWidget);
    expect(AmountText.textFor(Money.maxPaise * 2), 'Amount too large');
  });

  testWidgets('one line, scaleDown, never ellipsis', (tester) async {
    await pumpAmount(tester, const AmountText(Money.maxPaise));

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.maxLines, 1);
    expect(text.softWrap, isFalse);
    expect(text.overflow, isNot(TextOverflow.ellipsis));

    final fitted = tester.widget<FittedBox>(find.byType(FittedBox));
    expect(fitted.fit, BoxFit.scaleDown);
  });

  testWidgets('a narrow space shrinks the amount instead of overflowing', (
    tester,
  ) async {
    await pumpAmount(
      tester,
      const AmountText(Money.maxPaise),
      width: 60,
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(FittedBox)).width, lessThanOrEqualTo(60));
    final paragraph = tester.renderObject<RenderParagraph>(find.byType(Text));
    expect(paragraph.didExceedMaxLines, isFalse);
  });

  for (final brightness in Brightness.values) {
    testWidgets('tone colours come from AppColors ($brightness)', (
      tester,
    ) async {
      final palette = brightness == Brightness.dark
          ? AppColors.dark
          : AppColors.light;

      Future<Color?> colourFor(AmountTone tone) async {
        await pumpAmount(
          tester,
          AmountText(100, tone: tone),
          brightness: brightness,
        );
        return tester.widget<Text>(find.byType(Text)).style?.color;
      }

      expect(await colourFor(AmountTone.neutral), palette.textPrimary);
      expect(await colourFor(AmountTone.positive), palette.success);
      expect(await colourFor(AmountTone.negative), palette.danger);
    });
  }

  testWidgets('defaults to the theme titleMedium style', (tester) async {
    await pumpAmount(tester, const AmountText(100));
    final text = tester.widget<Text>(find.byType(Text));
    final context = tester.element(find.byType(AmountText));
    final expected = Theme.of(context).textTheme.titleMedium!;
    expect(text.style?.fontSize, expected.fontSize);
    expect(text.style?.fontFamily, expected.fontFamily);
  });
}
