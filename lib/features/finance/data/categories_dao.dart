import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';
import '../domain/category_kind.dart';
import 'category_seeder.dart';

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

  Future<void> deleteCategory(String id) {
    return (delete(categories)..where((c) => c.id.equals(id))).go();
  }
}

/// Ensures the 8 defaults exist for this user_id — cheap no-op after
/// the first successful run (checked via seedDefaultCategoriesIfEmpty).
final categoriesSeedProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final userId = await LocalUserId.get();
  await db.seedDefaultCategoriesIfEmpty(userId);
});

final categoriesProvider = StreamProvider<List<CategoryRow>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final userId = await LocalUserId.get();
  yield* db.watchCategories(userId);
});