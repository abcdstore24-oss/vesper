import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/db/app_database.dart';
import 'package:vesper/features/finance/data/categories_table.dart';
import 'package:vesper/features/finance/presentation/category_list_entries.dart';

CategoryRow _row(
  String id,
  String name, {
  bool archived = false,
  CategoryKind kind = CategoryKind.expense,
  String? seedKey,
}) => CategoryRow(
  id: id,
  userId: 'user-1',
  name: name,
  icon: 'tag',
  color: 0xFFC97B84,
  kind: kind,
  seedKey: seedKey,
  isArchived: archived,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);

List<String> _shape(List<CategoryListEntry> entries) => [
  for (final e in entries)
    switch (e) {
      CategoryArchivedHeader() => 'H:Archived',
      CategoryRowEntry(:final category) => 'R:${category.name}',
    },
];

void main() {
  test('empty input gives no entries', () {
    expect(flattenCategories(const []), isEmpty);
  });

  test('active rows A-Z, ignoring case, and no header without archived', () {
    final entries = flattenCategories([
      _row('1', 'zebra'),
      _row('2', 'Apple'),
      _row('3', 'banana'),
      _row('4', 'Cherry'),
    ]);

    expect(_shape(entries), ['R:Apple', 'R:banana', 'R:Cherry', 'R:zebra']);
  });

  test('archived rows come after an "Archived" header, A-Z', () {
    final entries = flattenCategories([
      _row('1', 'Rent', archived: true),
      _row('2', 'Food'),
      _row('3', 'Books', archived: true),
      _row('4', 'Gym'),
    ]);

    expect(_shape(entries), [
      'R:Food',
      'R:Gym',
      'H:Archived',
      'R:Books',
      'R:Rent',
    ]);
  });

  test('only archived rows: the header comes first', () {
    final entries = flattenCategories([
      _row('1', 'Rent', archived: true),
      _row('2', 'Books', archived: true),
    ]);
    expect(_shape(entries), ['H:Archived', 'R:Books', 'R:Rent']);
  });

  test('system categories never appear', () {
    final entries = flattenCategories([
      _row('1', 'Loan given', kind: CategoryKind.system, seedKey: 'sys_a'),
      _row(
        '2',
        'Loan taken',
        kind: CategoryKind.system,
        seedKey: 'sys_b',
        archived: true,
      ),
      _row('3', 'Food', seedKey: 'exp_food'),
    ]);
    expect(_shape(entries), ['R:Food']);
  });

  test('the input list is not modified', () {
    final input = [_row('1', 'b'), _row('2', 'a')];
    flattenCategories(input);
    expect(input.map((c) => c.name), ['b', 'a']);
  });
}
