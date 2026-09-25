import '../../../core/db/app_database.dart';
import '../domain/category_kind.dart';
import '../domain/category_style.dart';

class DefaultCategory {
  const DefaultCategory(this.name, this.kind, this.iconKey, this.swatch);
  final String name;
  final CategoryKind kind;
  final String iconKey;
  final CategorySwatch swatch;
}

/// The 8 defaults from the task brief, mapped to the approved palette
/// in the same order it was presented and approved.
final defaultCategories = <DefaultCategory>[
  DefaultCategory('Food', CategoryKind.expense, 'forkKnife', CategoryPalette.swatches[0]),
  DefaultCategory('Transport', CategoryKind.expense, 'carSimple', CategoryPalette.swatches[1]),
  DefaultCategory('Bills', CategoryKind.expense, 'receipt', CategoryPalette.swatches[2]),
  DefaultCategory('Salary', CategoryKind.income, 'handCoins', CategoryPalette.swatches[3]),
  DefaultCategory('Shopping', CategoryKind.expense, 'shoppingBag', CategoryPalette.swatches[4]),
  DefaultCategory('Health', CategoryKind.expense, 'heartbeat', CategoryPalette.swatches[5]),
  DefaultCategory('Entertainment', CategoryKind.expense, 'filmSlate', CategoryPalette.swatches[6]),
  DefaultCategory('Other', CategoryKind.expense, 'archiveBox', CategoryPalette.swatches[7]),
];

extension CategorySeeder on AppDatabase {
  /// Seeds [defaultCategories] for [userId] iff that user_id currently
  /// has zero category rows — "first run only," scoped per-user_id
  /// per the task's locked decision, not a global once-ever flag.
  Future<void> seedDefaultCategoriesIfEmpty(String userId) async {
    final existing = await (select(categories)
          ..where((c) => c.userId.equals(userId)))
        .get();
    if (existing.isNotEmpty) return;

    await batch((b) {
      b.insertAll(categories, [
        for (final d in defaultCategories)
          CategoriesCompanion.insert(
            id: generateId(),
            userId: userId,
            name: d.name,
            icon: d.iconKey,
            color: d.swatch.lightHex,
            kind: d.kind.name,
          ),
      ]);
    });
  }
}