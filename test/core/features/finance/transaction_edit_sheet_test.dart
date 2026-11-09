import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/core/utils/money.dart';
import 'package:vesper/features/finance/data/accounts_table.dart';
import 'package:vesper/features/finance/data/categories_table.dart';
import 'package:vesper/features/finance/data/transaction_queries.dart';
import 'package:vesper/features/finance/data/transactions_table.dart';
import 'package:vesper/features/finance/presentation/providers/transactions_providers.dart';
import 'package:vesper/features/finance/presentation/widgets/transaction_form_sheet.dart';
import 'package:vesper/shared/widgets/picker_sheet.dart';

import '../../../support/ui_test_helpers.dart';

CategoryRow _category(String id, String name, CategoryKind kind) => CategoryRow(
  id: id,
  userId: 'user-1',
  name: name,
  icon: 'fork_knife',
  color: 0xFFC97B84,
  kind: kind,
  isArchived: false,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);

final _amountField = find.byKey(const ValueKey('tx_amount_field'));
final _noteField = find.byKey(const ValueKey('tx_note_field'));
final _categoryField = find.byKey(const ValueKey('category_field'));
final _dateField = find.byKey(const ValueKey('tx_date_field'));
final _saveButton = find.descendant(
  of: find.byType(TransactionFormSheet),
  matching: find.byType(ElevatedButton),
);

String _textOf(WidgetTester tester, Finder field) =>
    tester.widget<TextField>(field).controller!.text;

void main() {
  setUpAll(disableFontFetching);

  /// The sheet in edit mode, without a database. [accounts] default to
  /// a1 "Bank" and a2 "Visa" (the ids makeTransactionItem uses);
  /// [categories] are the ACTIVE ones.
  Future<void> pumpEdit(
    WidgetTester tester,
    TransactionListItem item, {
    List<CategoryRow>? categories,
    List<Override> extra = const [],
    Size size = const Size(800, 1600),
    double textScale = 1.0,
    Brightness brightness = Brightness.light,
  }) {
    final cats =
        categories ??
        [
          _category('c1', 'Food & Dining', CategoryKind.expense),
          _category('c2', 'Groceries', CategoryKind.expense),
          _category('c3', 'Salary', CategoryKind.income),
        ];
    return pumpUi(
      tester,
      Scaffold(
        body: TransactionFormSheet(key: UniqueKey(), existing: item),
      ),
      size: size,
      textScale: textScale,
      brightness: brightness,
      overrides: [
        accountsOverride([
          makeAccount(id: 'a1', name: 'Bank', balance: 100000),
          makeAccount(
            id: 'a2',
            name: 'Visa',
            type: AccountType.creditCard,
            balance: 0,
          ),
        ]),
        categoriesByKindProvider.overrideWith(
          (ref, kind) => Stream.value([
            for (final c in cats)
              if (c.kind == kind) c,
          ]),
        ),
        recentCategoriesProvider.overrideWith(
          (ref, kind) => Stream.value(const <CategoryRow>[]),
        ),
        ...extra,
      ],
    );
  }

  group('Money round trip for the prefill', () {
    test('format without symbol, commas removed, parses back exactly', () {
      for (final paise in [
        1,
        5,
        99,
        100,
        101,
        12345,
        99999,
        100000,
        123456789,
        1234567890123,
        Money.maxPaise - 1,
        Money.maxPaise,
      ]) {
        final text = Money.format(paise, symbol: false).replaceAll(',', '');
        expect(text, matches(RegExp(r'^\d+\.\d{2}$')), reason: '$paise');
        expect(Money.parse(text, allowNegative: false), paise, reason: text);
      }
    });
  });

  group('edit mode', () {
    testWidgets('title, button and prefill of an expense', (tester) async {
      final at = DateTime.now().subtract(const Duration(minutes: 3));
      await pumpEdit(
        tester,
        makeTransactionItem(
          id: 'e',
          amount: 125050,
          note: 'Electricity bill',
          categoryName: 'Food & Dining',
          occurredAt: at,
        ),
      );

      expect(find.text('Edit transaction'), findsOneWidget);
      expect(find.text('Add transaction'), findsNothing);
      expect(
        find.descendant(of: _saveButton, matching: find.text('Save changes')),
        findsOneWidget,
      );
      expect(find.text('Add expense'), findsNothing);

      expect(_textOf(tester, _amountField), '1250.50');
      expect(_textOf(tester, _noteField), 'Electricity bill');
      expect(
        find.descendant(
          of: _categoryField,
          matching: find.text('Food & Dining'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const ValueKey('type_chip_expense')))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const ValueKey('from_chip_a1')))
            .selected,
        isTrue,
      );
      expect(
        find.descendant(of: _dateField, matching: find.text('Today')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the largest amount is pre-filled exactly', (tester) async {
      await pumpEdit(
        tester,
        makeTransactionItem(id: 'big', amount: Money.maxPaise, note: null),
      );
      expect(_textOf(tester, _amountField), '1000000000000.00');
      expect(Money.parse(_textOf(tester, _amountField)), Money.maxPaise);
    });

    testWidgets('an income is pre-filled with its type', (tester) async {
      await pumpEdit(
        tester,
        makeTransactionItem(
          id: 'i',
          type: TransactionType.income,
          amount: 5000000,
          categoryName: 'Salary',
        ),
        categories: [_category('c1', 'Salary', CategoryKind.income)],
      );
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const ValueKey('type_chip_income')))
            .selected,
        isTrue,
      );
      expect(_textOf(tester, _amountField), '50000.00');
      expect(
        find.descendant(of: _categoryField, matching: find.text('Salary')),
        findsOneWidget,
      );
    });

    testWidgets('a transfer is pre-filled with its type and both accounts', (
      tester,
    ) async {
      await pumpEdit(
        tester,
        makeTransactionItem(
          id: 'x',
          type: TransactionType.transfer,
          amount: 30000,
          note: 'Pay card',
        ),
      );
      ChoiceChip chip(String key) =>
          tester.widget<ChoiceChip>(find.byKey(ValueKey(key)));
      expect(chip('type_chip_transfer').selected, isTrue);
      expect(chip('from_chip_a1').selected, isTrue);
      expect(chip('to_chip_a2').selected, isTrue);
      expect(_categoryField, findsNothing);
      expect(_textOf(tester, _noteField), 'Pay card');
    });

    testWidgets('an archived category is shown as selected and marked', (
      tester,
    ) async {
      // c1 is the row's category but is NOT in the active list.
      await pumpEdit(
        tester,
        makeTransactionItem(id: 'e', categoryName: 'Food & Dining'),
        categories: [_category('c2', 'Groceries', CategoryKind.expense)],
      );

      expect(
        find.descendant(
          of: _categoryField,
          matching: find.text('Food & Dining (archived)'),
        ),
        findsOneWidget,
      );

      await tester.tap(_categoryField);
      await tester.pumpAndSettle();
      final picker = find.byType(PickerSheet<String>);
      expect(picker, findsOneWidget);
      expect(
        find.descendant(
          of: picker,
          matching: find.text('Food & Dining (archived)'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: picker, matching: find.text('Groceries')),
        findsOneWidget,
      );
    });

    testWidgets(
      'switching type clears the category; the archived one is gone',
      (tester) async {
        await pumpEdit(
          tester,
          makeTransactionItem(id: 'e', categoryName: 'Food & Dining'),
          categories: [_category('c3', 'Salary', CategoryKind.income)],
        );

        await tapChip(tester, find.byKey(const ValueKey('type_chip_income')));
        await tester.pump();
        await tester.pump();
        expect(
          find.descendant(
            of: _categoryField,
            matching: find.text('Choose a category'),
          ),
          findsOneWidget,
        );

        // Back to expense: still cleared (not silently restored).
        await tapChip(tester, find.byKey(const ValueKey('type_chip_expense')));
        await tester.pump();
        await tester.pump();
        expect(
          find.descendant(
            of: _categoryField,
            matching: find.text('Choose a category'),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('(archived)'), findsNothing);
      },
    );

    testWidgets('an archived account is shown, marked, in its own slot', (
      tester,
    ) async {
      await pumpUi(
        tester,
        Scaffold(
          body: TransactionFormSheet(
            existing: makeTransactionItem(id: 'e', accountName: 'Old bank'),
          ),
        ),
        size: const Size(800, 1600),
        overrides: [
          accountsOverride([
            makeAccount(id: 'a1', name: 'Old bank', isArchived: true),
            makeAccount(id: 'a9', name: 'Cash', type: AccountType.cash),
          ]),
          categoriesByKindProvider.overrideWith(
            (ref, kind) => Stream.value([
              _category('c1', 'Food & Dining', CategoryKind.expense),
            ]),
          ),
          recentCategoriesProvider.overrideWith(
            (ref, kind) => Stream.value(const <CategoryRow>[]),
          ),
        ],
      );

      final archivedChip = find.byKey(const ValueKey('from_chip_a1'));
      expect(archivedChip, findsOneWidget);
      expect(
        find.descendant(
          of: archivedChip,
          matching: find.text('Old bank (archived)'),
        ),
        findsOneWidget,
      );
      expect(tester.widget<ChoiceChip>(archivedChip).selected, isTrue);
      expect(find.byKey(const ValueKey('from_chip_a9')), findsOneWidget);
    });
  });

  for (final brightness in Brightness.values) {
    for (final type in TransactionType.values) {
      testWidgets(
        'worst case in edit mode: 320dp, text scale 2.0, 100-char note, '
        'maxPaise, ${type.name} ($brightness)',
        (tester) async {
          await pumpEdit(
            tester,
            makeTransactionItem(
              id: 'w',
              type: type,
              amount: Money.maxPaise,
              note: 'n' * 100,
              categoryName: 'C' * 40,
              accountName: 'A' * 40,
              toAccountName: 'B' * 40,
            ),
            categories: [
              _category('c1', 'C' * 40, CategoryKind.expense),
              _category('c3', 'D' * 40, CategoryKind.income),
            ],
            size: const Size(320, 640),
            textScale: 2.0,
            brightness: brightness,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('Edit transaction'), findsOneWidget);
          expect(_amountField, findsOneWidget);
        },
      );
    }
  }
}
