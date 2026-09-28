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

/// The original 8 defaults from Task 2.1, plus Investments (this
/// task) — a second income-kind category so Sell (Task 2.6) and any
/// other income entry has a sensible default beyond Salary. Order
/// here doesn't affect display order (categoriesProvider sorts
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
  // NEW this task. Icon deliberately NOT chartLineUp (already
  // InvestmentType.stock's icon) or handCoins (already Salary's icon
  // AND the Sell action-button icon on the Investments tab) — see
  // task response for the collision reasoning. Color deliberately
  // reuses swatches[1] (Transport's blue) rather than Salary's olive,
  // so the two income categories stay visually distinct from each
  // other where they now appear side by side (e.g. the Sell form's
  // category dropdown).
  DefaultCategory('Investments', CategoryKind.income, 'piggyBank', CategoryPalette.swatches[1]),
];

extension CategorySeeder on AppDatabase {
  /// Seeds ALL of [defaultCategories] (now 9) for [userId] iff that
  /// user_id currently has zero category rows — "first run only,"
  /// per-user_id, unchanged from Task 2.1. A brand-new install gets
  /// Investments as part of this normal seeding path; existing
  /// installs (already non-empty) are untouched by this function —
  /// see ensureInvestmentsCategoryExists below for how they catch up.
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

  /// One-time top-up for users who already had the original 8
  /// categories seeded before this task existed — seedDefaultCategoriesIfEmpty
  /// only fires when a user has ZERO categories, so it will never run
  /// again for them and they'd otherwise never receive the 9th
  /// default. Idempotent check-then-insert (queries by exact
  /// name+kind first, inserts only if absent) — safe to call
  /// unconditionally on every app launch; see task response for the
  /// concurrency reasoning (this runs inside categoriesSeedProvider,
  /// a plain non-family FutureProvider, so Riverpod only ever
  /// invokes its body once per app session regardless of how many
  /// widgets watch it — no race between multiple simultaneous
  /// inserts is possible).
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
}