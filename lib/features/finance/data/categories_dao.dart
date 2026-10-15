import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'categories_table.dart';

/// Read/insert access to `categories`. Deliberately small: no update and
/// NO delete. Built-in (seeded) categories may be renamed or archived
/// but never deleted, and there is no edit UI yet, so nothing here
/// offers either.
///
/// A plain class over [AppDatabase] (no @DriftAccessor), so it needs no
/// extra code generation.
class CategoriesDao {
  const CategoriesDao(this._db);

  final AppDatabase _db;

  /// Categories of [kind] for [userId], A-Z by name. Archived ones are
  /// hidden unless [includeArchived] is true.
  Stream<List<CategoryRow>> watchByKind(
    String userId,
    CategoryKind kind, {
    bool includeArchived = false,
  }) {
    final query = _db.select(_db.categories)
      ..where((t) => t.userId.equals(userId) & t.kind.equalsValue(kind))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    return query.watch();
  }

  Future<CategoryRow?> getById(String id) {
    return (_db.select(_db.categories)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// The built-in (or any) category of [userId] with [seedKey], or null if
  /// there is none, including when the key belongs to a different user.
  Future<CategoryRow?> getBySeedKey(String userId, String seedKey) {
    return (_db.select(_db.categories)
          ..where((t) => t.userId.equals(userId) & t.seedKey.equals(seedKey)))
        .getSingleOrNull();
  }

  /// Every category for [userId], archived included, A-Z by name.
  Future<List<CategoryRow>> getAll(String userId) {
    return (_db.select(_db.categories)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<void> insert(CategoriesCompanion entry) async {
    await _db.into(_db.categories).insert(entry);
  }
}