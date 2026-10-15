import 'package:drift/drift.dart';

/// What a category is for.
///
/// - [income] / [expense]: what the user picks for ordinary money coming
///   in or going out; these are the ones budgets and income/expense
///   charts count.
/// - [system]: labels for loan and investment money movements. Never
///   user-pickable, never counted as income or expense, never shown in
///   normal pickers or budgets.
///
/// Stored by NAME (`'income'` / `'expense'` / `'system'`) via `textEnum`,
/// never by index, and with no SQL CHECK constraint, so adding a value
/// needs no schema change. Only ever APPEND new values, and never rename
/// one (the name is what is stored).
enum CategoryKind { income, expense, system }

/// DATABASE.md `categories`: (id, user_id, name, icon, color, kind) plus
/// the general created_at/updated_at columns (Non-negotiable Rule 3) and
/// two additions from the Phase 2 Task 2 spec: `seed_key` and
/// `is_archived`.
///
/// - `icon` is a Phosphor icon KEY in snake_case (e.g. `fork_knife`).
///   The key -> icon mapping is a UI concern and comes later.
/// - `color` is an ARGB int, `0xFFRRGGBB`.
/// - `seed_key` is a stable id for the built-in categories (`exp_food`).
///   NULL for categories the user creates. SQLite treats NULLs as
///   distinct, so user-made categories never collide on the unique key.
/// - `user_id` is NOT NULL here (unlike user_profile): the unique
///   (user_id, seed_key) key would silently stop protecting against
///   duplicates if user_id could be NULL. Every row is scoped to the
///   device-local user id created at startup.
@DataClassName('CategoryRow')
@TableIndex(name: 'categories_user_kind_idx', columns: {#userId, #kind})
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  IntColumn get color => integer()();
  TextColumn get kind => textEnum<CategoryKind>()();
  TextColumn get seedKey => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {userId, seedKey},
  ];
}