import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:vesper/shared/widgets/picker_sheet.dart';

import '../../support/ui_test_helpers.dart';

final _searchField = find.byKey(const ValueKey('picker_search'));
final _rows = find.byWidgetPredicate((w) {
  final key = w.key;
  return key is ValueKey<String> && key.value.startsWith('picker_row_');
});

Finder _inPicker(String text) => find.descendant(
  of: find.byType(PickerSheet<String>),
  matching: find.text(text),
);

List<PickerItem<String>> _items(List<String> titles) => [
  for (final t in titles) PickerItem<String>(value: t, title: t),
];

const _ten = [
  'Food & Dining',
  'Groceries',
  'Transport',
  'Bills & Utilities',
  'Rent',
  'Shopping',
  'Health',
  'Education',
  'Entertainment',
  'Travel',
];

void main() {
  setUpAll(disableFontFetching);

  /// Shows a button that opens the picker; every result (including null for
  /// a dismissed sheet) is added to [results].
  Future<void> openPicker(
    WidgetTester tester, {
    required List<PickerItem<String>> items,
    required List<String?> results,
    String? selected,
    int searchThreshold = 8,
    Size size = const Size(800, 1000),
    double textScale = 1.0,
  }) async {
    await pumpUi(
      tester,
      Scaffold(
        body: Center(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final value = await showPickerSheet<String>(
                  context,
                  title: 'Pick one',
                  items: items,
                  selected: selected,
                  searchThreshold: searchThreshold,
                );
                results.add(value);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
      size: size,
      textScale: textScale,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('opens with a title, every row, and a search box', (
    tester,
  ) async {
    final results = <String?>[];
    await openPicker(tester, items: _items(_ten), results: results);

    expect(find.text('Pick one'), findsOneWidget);
    expect(_searchField, findsOneWidget);
    expect(_rows, findsNWidgets(10));
    for (final title in _ten) {
      expect(_inPicker(title), findsOneWidget, reason: title);
    }
    expect(results, isEmpty);
  });

  testWidgets('search filters case-insensitively with "contains"', (
    tester,
  ) async {
    await openPicker(tester, items: _items(_ten), results: <String?>[]);

    await tester.enterText(_searchField, 'bil');
    await tester.pump(const Duration(milliseconds: 300));
    expect(_inPicker('Bills & Utilities'), findsOneWidget);
    expect(_inPicker('Groceries'), findsNothing);
    expect(_rows, findsOneWidget);

    await tester.enterText(_searchField, 'BIL');
    await tester.pump(const Duration(milliseconds: 300));
    expect(_inPicker('Bills & Utilities'), findsOneWidget);

    // "contains", not "starts with".
    await tester.enterText(_searchField, 'ing');
    await tester.pump(const Duration(milliseconds: 300));
    expect(_inPicker('Food & Dining'), findsOneWidget);
    expect(_inPicker('Shopping'), findsOneWidget);
    expect(_inPicker('Travel'), findsNothing);

    // Clearing the search brings everything back.
    await tester.enterText(_searchField, '');
    await tester.pump(const Duration(milliseconds: 300));
    expect(_rows, findsNWidgets(10));
  });

  testWidgets('no match shows "No matches"', (tester) async {
    await openPicker(tester, items: _items(_ten), results: <String?>[]);

    await tester.enterText(_searchField, 'zzz');
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('No matches'), findsOneWidget);
    expect(_rows, findsNothing);
  });

  testWidgets('the selected row shows a check', (tester) async {
    await openPicker(
      tester,
      items: _items(_ten),
      results: <String?>[],
      selected: 'Rent',
    );

    expect(find.byIcon(PhosphorIconsRegular.check), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('picker_row_4')), // Rent
        matching: find.byIcon(PhosphorIconsRegular.check),
      ),
      findsOneWidget,
    );
  });

  testWidgets('no selection: no check anywhere', (tester) async {
    await openPicker(tester, items: _items(_ten), results: <String?>[]);
    expect(find.byIcon(PhosphorIconsRegular.check), findsNothing);
  });

  testWidgets('150 items: only a few rows are built (lazy)', (tester) async {
    final titles = [
      for (var i = 0; i < 150; i++) 'Item ${i.toString().padLeft(3, '0')}',
    ];
    await openPicker(
      tester,
      items: _items(titles),
      results: <String?>[],
      size: const Size(800, 600),
    );

    expect(_rows, findsWidgets);
    expect(tester.widgetList(_rows).length, lessThan(30));
    expect(_inPicker('Item 000'), findsOneWidget);
    expect(_inPicker('Item 149'), findsNothing);

    // Scrolling builds the far end on demand.
    await tester.dragUntilVisible(
      _inPicker('Item 149'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(_inPicker('Item 149'), findsOneWidget);
    expect(tester.widgetList(_rows).length, lessThan(30));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a row returns its value and closes the sheet', (
    tester,
  ) async {
    final results = <String?>[];
    await openPicker(tester, items: _items(_ten), results: results);

    await tester.tap(_inPicker('Groceries'));
    await tester.pumpAndSettle();

    expect(results, ['Groceries']);
    expect(find.byType(PickerSheet<String>), findsNothing);
  });

  testWidgets('dismissing the sheet returns null', (tester) async {
    final results = <String?>[];
    await openPicker(tester, items: _items(_ten), results: results);

    await tester.tapAt(const Offset(10, 10)); // the barrier
    await tester.pumpAndSettle();

    expect(results, [null]);
    expect(find.byType(PickerSheet<String>), findsNothing);
  });

  group('the search box', () {
    testWidgets('is hidden with as many items as the threshold', (
      tester,
    ) async {
      await openPicker(
        tester,
        items: _items(_ten.take(8).toList()),
        results: <String?>[],
      );
      expect(_searchField, findsNothing);
    });

    testWidgets('appears with one more item than the threshold', (
      tester,
    ) async {
      await openPicker(
        tester,
        items: _items(_ten.take(9).toList()),
        results: <String?>[],
      );
      expect(_searchField, findsOneWidget);
    });

    testWidgets('follows a custom searchThreshold', (tester) async {
      await openPicker(
        tester,
        items: _items(_ten.take(3).toList()),
        results: <String?>[],
        searchThreshold: 2,
      );
      expect(_searchField, findsOneWidget);
    });

    testWidgets('a high searchThreshold hides it', (tester) async {
      await openPicker(
        tester,
        items: _items(_ten),
        results: <String?>[],
        searchThreshold: 20,
      );
      expect(_searchField, findsNothing);
    });
  });

  testWidgets('rows show an icon and a one-line subtitle', (tester) async {
    await openPicker(
      tester,
      items: const [
        PickerItem<String>(
          value: 'a',
          title: 'Bank A',
          subtitle: 'Bank',
          icon: PhosphorIconsRegular.bank,
        ),
        PickerItem<String>(
          value: 'b',
          title: 'Cash B',
          subtitle: 'Cash',
          icon: PhosphorIconsRegular.money,
        ),
      ],
      results: <String?>[],
    );

    expect(find.byIcon(PhosphorIconsRegular.bank), findsOneWidget);
    expect(find.byIcon(PhosphorIconsRegular.money), findsOneWidget);
    expect(_inPicker('Bank'), findsOneWidget);
    expect(_inPicker('Cash'), findsOneWidget);
  });

  testWidgets('long titles do not overflow at 320dp, text scale 1.5', (
    tester,
  ) async {
    await openPicker(
      tester,
      items: [
        PickerItem<String>(
          value: 'long',
          title: 'A' * 100,
          subtitle: 'B' * 100,
          icon: PhosphorIconsRegular.bank,
        ),
        const PickerItem<String>(value: 'short', title: 'Short'),
      ],
      results: <String?>[],
      size: const Size(320, 640),
      textScale: 1.5,
    );

    expect(tester.takeException(), isNull);
    expect(_rows, findsNWidgets(2));
  });

  testWidgets('the list stays above the keyboard', (tester) async {
    await openPicker(
      tester,
      items: _items(_ten),
      results: <String?>[],
      size: const Size(800, 1000),
    );

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    // The visible area ends at y = 1000 - 300.
    expect(
      tester.getBottomLeft(find.byType(ListView)).dy,
      lessThanOrEqualTo(700.5),
    );
  });
}
