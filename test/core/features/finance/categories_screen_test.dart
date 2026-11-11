import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/features/finance/data/categories_table.dart';
import 'package:vesper/features/finance/presentation/categories_screen.dart';
import 'package:vesper/features/finance/presentation/category_choices.dart';
import 'package:vesper/features/finance/presentation/finance_home_screen.dart';
import 'package:vesper/features/finance/presentation/providers/transactions_providers.dart';
import 'package:vesper/features/finance/presentation/widgets/category_form_sheet.dart';

import '../../../support/ui_test_helpers.dart';

CategoryRow _cat(
  String id,
  String name, {
  CategoryKind kind = CategoryKind.expense,
  bool archived = false,
  String? seedKey,
  String icon = 'tag',
  int color = 0xFFC97B84,
}) => CategoryRow(
  id: id,
  userId: 'user-1',
  name: name,
  icon: icon,
  color: color,
  kind: kind,
  seedKey: seedKey,
  isArchived: archived,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);

Finder _row(String id) => find.byKey(ValueKey('category-row-$id'));
Finder _kindChip(String name) => find.byKey(ValueKey('categories-kind-$name'));

/// Overrides manageCategoriesProvider with fixed rows, filtered by kind (the
/// real provider reads them from the database).
Override _manageOverride(List<CategoryRow> rows) {
  return manageCategoriesProvider.overrideWith(
    (ref, kind) => Stream.value([
      for (final c in rows)
        if (c.kind == kind) c,
    ]),
  );
}

/// Waits for an override stream to emit, then rebuilds.
Future<void> _afterChip(WidgetTester tester, Finder chip) async {
  await tapChip(tester, chip);
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(disableFontFetching);

  Future<void> pumpScreen(
    WidgetTester tester,
    List<CategoryRow> rows, {
    Size size = const Size(800, 1000),
    double textScale = 1.0,
    Brightness brightness = Brightness.light,
  }) => pumpUi(
    tester,
    const CategoriesScreen(),
    size: size,
    textScale: textScale,
    brightness: brightness,
    overrides: [_manageOverride(rows)],
  );

  group('the screen (no database)', () {
    testWidgets('title, chips, rows, subtitles and the Archived section', (
      tester,
    ) async {
      await pumpScreen(tester, [
        _cat('1', 'Pets', icon: 'paw_print', color: 0xFF8FB38A),
        _cat('2', 'Food & Dining', seedKey: 'exp_food'),
        _cat('3', 'Rent', archived: true, seedKey: 'exp_rent'),
        _cat('4', 'Hobbies', archived: true),
        _cat('5', 'Salary', kind: CategoryKind.income, seedKey: 'inc_salary'),
      ]);

      expect(find.text('Categories'), findsOneWidget);
      expect(tester.widget<ChoiceChip>(_kindChip('expense')).selected, isTrue);
      expect(tester.widget<ChoiceChip>(_kindChip('income')).selected, isFalse);
      expect(find.byTooltip('Add category'), findsOneWidget);

      // Active A-Z first, then the Archived header, then archived A-Z.
      final names = ['Food & Dining', 'Pets', 'Hobbies', 'Rent'];
      final tops = [for (final n in names) tester.getTopLeft(find.text(n)).dy];
      expect(tops, orderedEquals([...tops]..sort()));
      expect(
        tester.getTopLeft(find.text('Pets')).dy,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(const ValueKey('categories-archived-header')),
              )
              .dy,
        ),
      );
      expect(find.text('Archived'), findsWidgets);

      // Subtitles.
      Finder sub(String id, String text) =>
          find.descendant(of: _row(id), matching: find.text(text));
      expect(sub('2', 'Built-in'), findsOneWidget); // built-in, active
      expect(sub('1', 'Built-in'), findsNothing); // user-made: none
      expect(sub('3', 'Archived \u00B7 Built-in'), findsOneWidget);
      expect(sub('4', 'Archived'), findsOneWidget);

      // The expense tab does not show income rows.
      expect(find.text('Salary'), findsNothing);

      // The icon is the category's own, in its own colour.
      final icon = tester.widget<Icon>(
        find.descendant(
          of: _row('1'),
          matching: find.byIcon(PhosphorIconsRegular.pawPrint),
        ),
      );
      expect(icon.color, const Color(0xFF8FB38A));
      expect(tester.takeException(), isNull);
    });

    testWidgets('archived rows look muted', (tester) async {
      await pumpScreen(tester, [
        _cat('1', 'Active'),
        _cat('2', 'Gone', archived: true),
      ]);

      double opacityOf(String id) => tester
          .widget<Opacity>(
            find.descendant(of: _row(id), matching: find.byType(Opacity)),
          )
          .opacity;
      expect(opacityOf('1'), 1);
      expect(opacityOf('2'), lessThan(1));
    });

    testWidgets('the chips switch between expense and income', (tester) async {
      await pumpScreen(tester, [
        _cat('1', 'Pets'),
        _cat('2', 'Freelance', kind: CategoryKind.income),
      ]);
      expect(find.text('Pets'), findsOneWidget);
      expect(find.text('Freelance'), findsNothing);

      await _afterChip(tester, _kindChip('income'));
      expect(tester.widget<ChoiceChip>(_kindChip('income')).selected, isTrue);
      expect(find.text('Freelance'), findsOneWidget);
      expect(find.text('Pets'), findsNothing);

      await _afterChip(tester, _kindChip('expense'));
      expect(find.text('Pets'), findsOneWidget);
    });

    testWidgets('empty: a message about + and restoring', (tester) async {
      await pumpScreen(tester, const []);

      expect(find.textContaining('No expense categories'), findsOneWidget);
      expect(find.textContaining('+'), findsOneWidget);
      expect(find.textContaining('restore'), findsOneWidget);

      await _afterChip(tester, _kindChip('income'));
      expect(find.textContaining('No income categories'), findsOneWidget);
      // The chips stay.
      expect(_kindChip('expense'), findsOneWidget);
    });

    testWidgets('loading: a spinner, the chips stay', (tester) async {
      await pumpUi(
        tester,
        const CategoriesScreen(),
        overrides: [
          manageCategoriesProvider.overrideWith((ref, kind) {
            final controller = StreamController<List<CategoryRow>>();
            ref.onDispose(controller.close);
            return controller.stream;
          }),
        ],
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('No expense categories'), findsNothing);
      expect(_kindChip('expense'), findsOneWidget);
    });

    testWidgets('error: a message and Retry; the chips stay', (tester) async {
      var calls = 0;
      await pumpUi(
        tester,
        const CategoriesScreen(),
        overrides: [
          manageCategoriesProvider.overrideWith((ref, kind) {
            calls++;
            return calls == 1
                ? Stream<List<CategoryRow>>.error(Exception('boom'))
                : Stream.value([_cat('1', 'Back again')]);
          }),
        ],
      );

      expect(find.text("Couldn't load categories"), findsOneWidget);
      expect(_kindChip('income'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();
      expect(find.text("Couldn't load categories"), findsNothing);
      expect(find.text('Back again'), findsOneWidget);
    });

    testWidgets('500 rows: lazy, and the last row clears the FAB', (
      tester,
    ) async {
      await pumpScreen(tester, [
        for (var i = 1; i <= 500; i++)
          _cat('c$i', 'Category ${i.toString().padLeft(3, '0')}'),
      ], size: const Size(800, 600));

      final built = find.byType(InkWell).evaluate().length;
      expect(built, greaterThan(0));
      expect(built, lessThan(60));

      final last = _row('c500');
      for (var i = 0; i < 400 && last.evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -2000));
        await tester.pump();
      }
      expect(last, findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -2000));
        await tester.pumpAndSettle();
      }

      final lastBottom = tester
          .getBottomLeft(
            find.ancestor(of: last, matching: find.byType(Card)).first,
          )
          .dy;
      final fabTop = tester.getTopLeft(find.byType(FloatingActionButton)).dy;
      expect(lastBottom, lessThanOrEqualTo(fabTop));
    });

    testWidgets('tapping a row opens the edit sheet; + opens the add sheet', (
      tester,
    ) async {
      await pumpScreen(tester, [_cat('1', 'Pets')]);

      await tester.tap(_row('1'));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryFormSheet), findsOneWidget);
      expect(find.text('Edit category'), findsOneWidget);

      await tester.tapAt(const Offset(5, 5)); // dismiss
      await tester.pumpAndSettle();
      expect(find.byType(CategoryFormSheet), findsNothing);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Add category'), findsWidgets);
      expect(find.byType(CategoryFormSheet), findsOneWidget);
    });

    for (final brightness in Brightness.values) {
      testWidgets('worst case: 320dp, text scale 2.0, 40-character names '
          '($brightness)', (tester) async {
        await pumpScreen(
          tester,
          [
            _cat('1', 'A' * 40, seedKey: 'exp_a'),
            _cat('2', 'B' * 40, archived: true, seedKey: 'exp_b'),
            _cat('3', 'C' * 40),
          ],
          size: const Size(320, 640),
          textScale: 2.0,
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);
        expect(_kindChip('expense'), findsOneWidget);
        expect(_row('1'), findsOneWidget);
      });
    }
  });

  group('the sheet (no database)', () {
    final previewIcon = find.descendant(
      of: find.byKey(const ValueKey('cat_preview')),
      matching: find.byType(Icon),
    );

    Future<void> pumpSheet(
      WidgetTester tester, {
      CategoryKind kind = CategoryKind.expense,
      CategoryRow? category,
      Size size = const Size(800, 1600),
      double textScale = 1.0,
      Brightness brightness = Brightness.light,
    }) => pumpUi(
      tester,
      Scaffold(
        body: CategoryFormSheet(
          key: UniqueKey(),
          kind: kind,
          category: category,
        ),
      ),
      size: size,
      textScale: textScale,
      brightness: brightness,
    );

    testWidgets('add mode: title, button, defaults and the two palettes', (
      tester,
    ) async {
      await pumpSheet(tester);

      expect(find.text('Add category'), findsNWidgets(2)); // title + button
      expect(find.byKey(const ValueKey('cat_archive_button')), findsNothing);
      expect(find.byKey(const ValueKey('cat_kind_text')), findsNothing);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('cat_name_field')))
            .maxLength,
        40,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('cat_name_field')))
            .controller!
            .text,
        '',
      );

      // Defaults: the tag icon in the first colour.
      final preview = tester.widget<Icon>(previewIcon);
      expect(preview.icon, PhosphorIconsRegular.tag);
      expect(preview.color, Color(categoryColorChoices.first));

      // 20 icons and 12 colours are offered; no system icon.
      for (final key in categoryIconChoices) {
        expect(find.byKey(ValueKey('cat_icon_$key')), findsOneWidget);
      }
      for (final c in categoryColorChoices) {
        expect(
          find.byKey(
            ValueKey('cat_color_${c.toRadixString(16).toUpperCase()}'),
          ),
          findsOneWidget,
        );
      }
      expect(find.byKey(const ValueKey('cat_icon_trend_up')), findsNothing);
      expect(find.byKey(const ValueKey('cat_icon_handshake')), findsNothing);
    });

    testWidgets('choosing an icon and a colour updates the preview', (
      tester,
    ) async {
      await pumpSheet(tester);

      await tapChip(tester, find.byKey(const ValueKey('cat_icon_house')));
      await tapChip(
        tester,
        find.byKey(
          ValueKey('cat_color_${0xFF6FA3A8.toRadixString(16).toUpperCase()}'),
        ),
      );

      final preview = tester.widget<Icon>(previewIcon);
      expect(preview.icon, PhosphorIconsRegular.house);
      expect(preview.color, const Color(0xFF6FA3A8));
    });

    testWidgets(
      'edit mode: prefill, read-only kind, built-in caption, Archive',
      (tester) async {
        await pumpSheet(
          tester,
          category: _cat(
            '1',
            'Food & Dining',
            seedKey: 'exp_food',
            icon: 'fork_knife',
            color: 0xFFC97B84,
          ),
        );

        expect(find.text('Edit category'), findsOneWidget);
        expect(find.text('Save changes'), findsOneWidget);
        expect(find.text('Expense category'), findsOneWidget);
        expect(find.text('Built-in category'), findsOneWidget);
        expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('cat_name_field')))
              .controller!
              .text,
          'Food & Dining',
        );
        expect(
          tester.widget<Icon>(previewIcon).icon,
          PhosphorIconsRegular.forkKnife,
        );
        // Archive is a neutral TextButton, not the danger colour.
        final archive = find.byKey(const ValueKey('cat_archive_button'));
        expect(tester.widget(archive), isA<TextButton>());
        expect(
          find.descendant(of: archive, matching: find.text('Archive category')),
          findsOneWidget,
        );
        expect(find.text('Restore category'), findsNothing);
      },
    );

    testWidgets(
      'edit mode: a user-made income category, then an archived one',
      (tester) async {
        await pumpSheet(
          tester,
          kind: CategoryKind.income,
          category: _cat('2', 'Freelance', kind: CategoryKind.income),
        );
        expect(find.text('Income category'), findsOneWidget);
        expect(find.text('Built-in category'), findsNothing);
      },
    );

    testWidgets('an archived category offers Restore', (tester) async {
      await pumpSheet(tester, category: _cat('3', 'Old', archived: true));
      expect(find.text('Restore category'), findsOneWidget);
      expect(find.text('Archive category'), findsNothing);
    });

    testWidgets('an empty name shows "Enter a name" and nothing is saved', (
      tester,
    ) async {
      await pumpSheet(tester);

      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Add category'),
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add category'));
      await tester.pump();

      expect(find.text('Enter a name'), findsOneWidget);
      // The button is usable again.
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Add category'),
            )
            .onPressed,
        isNotNull,
      );
    });

    for (final brightness in Brightness.values) {
      for (final edit in [false, true]) {
        testWidgets(
          'worst case sheet: 320dp, text scale 2.0, 40-character name, '
          '${edit ? 'edit' : 'add'} ($brightness)',
          (tester) async {
            await pumpSheet(
              tester,
              category: edit
                  ? _cat('1', 'N' * 40, seedKey: 'exp_n', archived: true)
                  : null,
              size: const Size(320, 640),
              textScale: 2.0,
              brightness: brightness,
            );
            if (!edit) {
              await tester.enterText(
                find.byKey(const ValueKey('cat_name_field')),
                'N' * 40,
              );
            }
            await tester.pump();

            expect(tester.takeException(), isNull);
            expect(
              find.byKey(const ValueKey('cat_name_field')),
              findsOneWidget,
            );
          },
        );
      }
    }
  });

  group('the Finance home card (no database)', () {
    testWidgets('a Categories card under Accounts opens the screen', (
      tester,
    ) async {
      await pumpUi(
        tester,
        const FinanceHomeScreen(),
        size: const Size(800, 1600),
        overrides: [
          recentTransactionsOverride(const []),
          accountsOverride([makeAccount(name: 'Cash', balance: 100)]),
          _manageOverride([_cat('1', 'Pets')]),
        ],
      );

      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Add, rename, archive'), findsOneWidget);
      // Below the Accounts card.
      expect(
        tester.getTopLeft(find.text('Categories')).dy,
        greaterThan(tester.getTopLeft(find.text('Accounts')).dy),
      );

      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();

      expect(find.byType(CategoriesScreen), findsOneWidget);
      expect(find.text('Pets'), findsOneWidget);
    });
  });
}
