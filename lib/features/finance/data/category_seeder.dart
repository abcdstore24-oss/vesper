import 'package:drift/drift.dart';

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

/// The original 8 (Task 2.1), Investments/Investment Purchase, and
/// now 4 loan categories (this task). Full collision check against
/// every fixed icon used across Finance done in plan — gift,
/// graduationCap, shieldCheck, book were the remaining unused
/// candidates.
final defaultCategories = <DefaultCategory>[
  DefaultCategory('Food', CategoryKind.expense, 'forkKnife', CategoryPalette.swatches[0]),
  DefaultCategory('Transport', CategoryKind.expense, 'carSimple', CategoryPalette.swatches[1]),
  DefaultCategory('Bills', CategoryKind.expense, 'receipt', CategoryPalette.swatches[2]),
  DefaultCategory('Salary', CategoryKind.income, 'handCoins', CategoryPalette.swatches[3]),
  DefaultCategory('Shopping', CategoryKind.expense, 'shoppingBag', CategoryPalette.swatches[4]),
  DefaultCategory('Health', CategoryKind.expense, 'heartbeat', CategoryPalette.swatches[5]),
  DefaultCategory('Entertainment', CategoryKind.expense, 'filmSlate', CategoryPalette.swatches[6]),
  DefaultCategory('Other', CategoryKind.expense, 'archiveBox', CategoryPalette.swatches[7]),
  DefaultCategory('Investments', CategoryKind.income, 'piggyBank', CategoryPalette.swatches[1]),
  DefaultCategory('Investment Purchase', CategoryKind.expense, 'tag', CategoryPalette.swatches[5]),
  // NEW this task.
  DefaultCategory('Loan Given', CategoryKind.expense, 'gift', CategoryPalette.swatches[2]),
  DefaultCategory('Loan Taken', CategoryKind.income, 'graduationCap', CategoryPalette.swatches[0]),
  DefaultCategory('Loan Repayment Received', CategoryKind.income, 'shieldCheck', CategoryPalette.swatches[6]),
  DefaultCategory('Loan Repayment Paid', CategoryKind.expense, 'book', CategoryPalette.swatches[7]),
];

extension CategorySeeder on AppDatabase {
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

  /// CHANGED this task: consolidates what were two near-identical
  /// functions (ensureInvestmentsCategoryExists,
  /// ensureInvestmentPurchaseCategoryExists) — and what would
  /// otherwise have become 4 more copies for this task's new
  /// categories — into one, looked up by name against
  /// defaultCategories. Idempotent check-then-insert, same shape as
  /// before, called once per default name from categoriesSeedProvider.
  Future<void> ensureDefaultCategoryExists(String userId, String name) async {
    final defaultEntry = defaultCategories.firstWhere((d) => d.name == name);
    final existing = await (select(categories)
          ..where((c) =>
              c.userId.equals(userId) &
              c.name.equals(name) &
              c.kind.equals(defaultEntry.kind.name)))
        .get();
    if (existing.isNotEmpty) return;

    await into(categories).insert(
      CategoriesCompanion.insert(
        id: generateId(),
        userId: userId,
        name: defaultEntry.name,
        icon: defaultEntry.iconKey,
        color: defaultEntry.swatch.lightHex,
        kind: defaultEntry.kind.name,
      ),
    );
  }
}