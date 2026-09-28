import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';
import '../domain/category_kind.dart';
import 'budgets_dao.dart';
import 'category_seeder.dart';
import 'transactions_dao.dart';

extension CategoriesDao on AppDatabase {
  Stream<List<CategoryRow>> watchCategories(String userId) {
    return (select(categories)
          ..where((c) => c.userId.equals(userId))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  Future<void> insertCategory({
    required String userId,
    required String name,
    required String iconKey,
    required String colorHex,
    required CategoryKind kind,
  }) async {
    await into(categories).insert(
      CategoriesCompanion.insert(
        id: generateId(),
        userId: userId,
        name: name,
        icon: iconKey,
        color: colorHex,
        kind: kind.name,
      ),
    );
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required String iconKey,
    required String colorHex,
    required CategoryKind kind,
  }) {
    return (update(categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(name),
        icon: Value(iconKey),
        color: Value(colorHex),
        kind: Value(kind.name),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteCategory(String id) async {
    final transactionCount = await countTransactionsForCategory(id);
    if (transactionCount > 0) {
      throw CategoryHasTransactionsException(transactionCount);
    }
    final budgetCount = await countBudgetsForCategory(id);
    if (budgetCount > 0) {
      throw CategoryHasBudgetsException(budgetCount);
    }
    await (delete(categories)..where((c) => c.id.equals(id))).go();
  }
}

/// CHANGED this task: now also runs ensureInvestmentsCategoryExists
/// alongside the original seedDefaultCategoriesIfEmpty — both are
/// no-ops after their respective conditions are already satisfied, so
/// this stays cheap on every call after the first. Every existing
/// ref.watch(categoriesSeedProvider) call site (categories_list_screen.dart,
/// transactions_list_screen.dart, summary_screen.dart,
/// budgets_list_screen.dart) picks this up automatically — no new
/// watch call sites needed anywhere, per the plan.
final categoriesSeedProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final userId = await LocalUserId.get();
  await db.seedDefaultCategoriesIfEmpty(userId);
  await db.ensureInvestmentsCategoryExists(userId);
});

final categoriesProvider = StreamProvider<List<CategoryRow>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final userId = await LocalUserId.get();
  yield* db.watchCategories(userId);
});