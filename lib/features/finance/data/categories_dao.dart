import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'categories_table.dart';

/// Why a category write was rejected.
enum CategoryValidationError {
  emptyName,
  nameTooLong,

  /// An ACTIVE category of the same kind already has this name.
  duplicateName,

  /// An ARCHIVED category of the same kind already has this name (archived
  /// categories keep their names reserved, so a restore can never clash).
  duplicateNameArchived,
  invalidIcon,
  invalidColor,

  /// Only expense and income categories can be created.
  kindNotAllowed,
  notFound,

  /// System categories (loans/investments) are never edited or archived here.
  systemCategory,
}

/// Thrown by [CategoriesDao] for an invalid category write. Deliberately
/// carries no user text, so it is safe to log.
class CategoryValidationException implements Exception {
  const CategoryValidationException(this.error);

  final CategoryValidationError error;

  @override
  String toString() => 'CategoryValidationException(${error.name})';
}

/// Read/insert/edit/archive access to `categories`. Categories are NEVER
/// deleted: built-in (seeded) and user-made ones can be renamed, restyled and
/// archived (and restored), nothing more. Nothing here offers a delete.
///
/// Name rules (create and edit): trimmed, 1-40 characters, unique per
/// (user, kind) ignoring case, ARCHIVED rows included. Icon: a snake_case key.
/// Colour: opaque 0xFFRRGGBB. The DAO knows no palettes; the UI limits the
/// choices. `kind` and `seed_key` never change after a row exists.
///
/// A plain class over [AppDatabase] (no @DriftAccessor), so it needs no
/// extra code generation.
class CategoriesDao {
  const CategoriesDao(this._db);

  /// Longest allowed category name, in characters (Unicode code points).
  static const int maxNameLength = 40;

  /// Longest allowed icon key.
  static const int maxIconLength = 40;

  static final RegExp _iconKey = RegExp(r'^[a-z][a-z0-9_]*$');

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
    return (_db.select(
      _db.categories,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
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

  /// Creates a category of [kind] (expense or income) for [userId] and
  /// returns its id. seed_key stays null.
  ///
  /// Throws [CategoryValidationException]: kindNotAllowed for `system`, the
  /// name errors, invalidIcon, invalidColor.
  Future<String> create({
    required String userId,
    required String name,
    required CategoryKind kind,
    required String icon,
    required int color,
  }) async {
    if (kind == CategoryKind.system) {
      throw const CategoryValidationException(
        CategoryValidationError.kindNotAllowed,
      );
    }
    final cleanName = _validateName(name);
    _validateIcon(icon);
    _validateColor(color);

    return _db.transaction(() async {
      await _ensureNameFree(userId, kind, cleanName);
      final id = generateId();
      await _db
          .into(_db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: id,
              userId: userId,
              name: cleanName,
              icon: icon,
              color: color,
              kind: kind,
            ),
          );
      return id;
    });
  }

  /// Changes the given fields of category [id] (null = leave unchanged) and
  /// sets updated_at. Same validation as [create]; keeping the row's own name
  /// is fine. The kind and seed_key never change.
  ///
  /// Throws [CategoryValidationException]: notFound, systemCategory, or a
  /// name/icon/colour error.
  Future<void> edit(String id, {String? name, String? icon, int? color}) async {
    final cleanName = name == null ? null : _validateName(name);
    if (icon != null) _validateIcon(icon);
    if (color != null) _validateColor(color);

    await _db.transaction(() async {
      final current = await _requireEditable(id);
      if (cleanName != null) {
        await _ensureNameFree(
          current.userId,
          current.kind,
          cleanName,
          excludeId: id,
        );
      }
      await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
        CategoriesCompanion(
          name: Value.absentIfNull(cleanName),
          icon: Value.absentIfNull(icon),
          color: Value.absentIfNull(color),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  /// Archives ([archived] true) or restores category [id] and sets
  /// updated_at. Archiving only hides it from pickers; nothing is deleted.
  ///
  /// Throws [CategoryValidationException]: notFound, systemCategory.
  Future<void> setArchived(String id, bool archived) async {
    await _db.transaction(() async {
      await _requireEditable(id);
      await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
        CategoriesCompanion(
          isArchived: Value(archived),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  /// The row [id], or notFound / systemCategory.
  Future<CategoryRow> _requireEditable(String id) async {
    final current = await getById(id);
    if (current == null) {
      throw const CategoryValidationException(CategoryValidationError.notFound);
    }
    if (current.kind == CategoryKind.system) {
      throw const CategoryValidationException(
        CategoryValidationError.systemCategory,
      );
    }
    return current;
  }

  String _validateName(String raw) {
    final name = raw.trim();
    if (name.isEmpty) {
      throw const CategoryValidationException(
        CategoryValidationError.emptyName,
      );
    }
    if (name.runes.length > maxNameLength) {
      throw const CategoryValidationException(
        CategoryValidationError.nameTooLong,
      );
    }
    return name;
  }

  void _validateIcon(String icon) {
    if (icon.length > maxIconLength || !_iconKey.hasMatch(icon)) {
      throw const CategoryValidationException(
        CategoryValidationError.invalidIcon,
      );
    }
  }

  /// Opaque 0xFFRRGGBB only.
  void _validateColor(int color) {
    if (color < 0xFF000000 || color > 0xFFFFFFFF) {
      throw const CategoryValidationException(
        CategoryValidationError.invalidColor,
      );
    }
  }

  /// Case-insensitive duplicate check within ([userId], [kind]), compared in
  /// Dart (SQLite's lower() only folds ASCII). ARCHIVED rows count too, so a
  /// restore can never clash. An active match is reported before an archived
  /// one.
  Future<void> _ensureNameFree(
    String userId,
    CategoryKind kind,
    String name, {
    String? excludeId,
  }) async {
    final key = name.toLowerCase();
    final matches = (await getAll(userId)).where(
      (c) => c.kind == kind && c.id != excludeId && c.name.toLowerCase() == key,
    );
    if (matches.isEmpty) return;
    final activeMatch = matches.any((c) => !c.isArchived);
    throw CategoryValidationException(
      activeMatch
          ? CategoryValidationError.duplicateName
          : CategoryValidationError.duplicateNameArchived,
    );
  }
}
