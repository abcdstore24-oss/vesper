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

/// The original 8 defaults from Task 2.1, plus Investments (income,
/// added so Sell has a sensible default beyond Salary) and now
/// Investment Purchase (expense, this task — so funding a new
/// investment from an account has a sensible default category).
/// Order here doesn't affect display order (categoriesProvider sorts
/// alphabetically by name), only seeding order.
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
  // NEW this task. Icon 'tag' checked against every fixed icon
  // assignment in Finance, not just CategoryIcons.options's other
  // default entries: also avoided house/briefcase (InvestmentType's
  // Real Estate/Other icons) and bank/creditCard/wallet (AccountType's
  // Bank/Card/Other icons) — all five are present in
  // CategoryIcons.options too, and none of that was caught by only
  // checking against category-icon usage. Swatch reuses Health's teal
  // (swatches[5]) rather than Investments' own blue (swatches[1]) —
  // pairing this with "Investments" itself would be the most
  // confusing possible same-color collision, expense vs income though
  // they are; Health and Investment Purchase are unrelated and
  // unlikely to dominate the same month's spending chart together.
  DefaultCategory('Investment Purchase', CategoryKind.expense, 'tag', CategoryPalette.swatches[5]),
];

extension CategorySeeder on AppDatabase {
  /// Seeds ALL of [defaultCategories] (now 10) for [userId] iff that
  /// user_id currently has zero category rows — "first run only,"
  /// per-user_id, unchanged since Task 2.1. A brand-new install gets
  /// Investment Purchase as part of this normal seeding path; existing
  /// installs (already non-empty) are untouched by this function —
  /// see ensureInvestmentsCategoryExists /
  /// ensureInvestmentPurchaseCategoryExists below for how they catch
  /// up.
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

  Future<void> ensureInvestmentsCategoryExists(String userId) async {
    final existing = await (select(categories)
          ..where((c) =>
              c.userId.equals(userId) &
              c.name.equals('Investments') &
              c.kind.equals(CategoryKind.income.name)))
        .get();
    if (existing.isNotEmpty) return;

    final investmentsDefault = defaultCategories.firstWhere((d) => d.name == 'Investments');
    await into(categories).insert(
      CategoriesCompanion.insert(
        id: generateId(),
        userId: userId,
        name: investmentsDefault.name,
        icon: investmentsDefault.iconKey,
        color: investmentsDefault.swatch.lightHex,
        kind: investmentsDefault.kind.name,
      ),
    );
  }

  /// NEW this task — one-time top-up for users who already had the
  /// prior 9 categories seeded before "Investment Purchase" existed.
  /// Exact same idempotent check-then-insert shape as
  /// ensureInvestmentsCategoryExists above: safe to call
  /// unconditionally on every app launch (a second run finds the
  /// category already present and inserts nothing), and safe against
  /// concurrent watchers for the same reason — this runs inside
  /// categoriesSeedProvider, a plain non-family FutureProvider, so
  /// Riverpod invokes its body once per app session regardless of how
  /// many widgets watch it.
  Future<void> ensureInvestmentPurchaseCategoryExists(String userId) async {
    final existing = await (select(categories)
          ..where((c) =>
              c.userId.equals(userId) &
              c.name.equals('Investment Purchase') &
              c.kind.equals(CategoryKind.expense.name)))
        .get();
    if (existing.isNotEmpty) return;

    final investmentPurchaseDefault = defaultCategories.firstWhere((d) => d.name == 'Investment Purchase');
    await into(categories).insert(
      CategoriesCompanion.insert(
        id: generateId(),
        userId: userId,
        name: investmentPurchaseDefault.name,
        icon: investmentPurchaseDefault.iconKey,
        color: investmentPurchaseDefault.swatch.lightHex,
        kind: investmentPurchaseDefault.kind.name,
      ),
    );
  }
}