import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/money.dart';
import 'account_balance.dart';
import 'balance_queries.dart';
import 'accounts_table.dart';

/// Why an account name was rejected.
enum AccountValidationError { emptyName, nameTooLong, duplicateName }

/// Thrown by [AccountsDao] for an invalid account name. Deliberately
/// carries no user text, so it is safe to log.
class AccountValidationException implements Exception {
  const AccountValidationException(this.error);

  final AccountValidationError error;

  @override
  String toString() => 'AccountValidationException(${error.name})';
}

/// Read/insert/update access to `accounts`. Deliberately small: no delete
/// and no archive method yet.
///
/// A plain class over [AppDatabase] (no @DriftAccessor), like
/// CategoriesDao, so it needs no extra code generation.
class AccountsDao {
  const AccountsDao(this._db);

  /// Longest allowed account name, in characters (Unicode code points).
  static const int maxNameLength = 40;

  final AppDatabase _db;

  /// Creates an account and returns its id.
  ///
  /// Throws [AccountValidationException] for an empty (after trimming),
  /// over-long or duplicate name (case-insensitive, per user), and
  /// [ArgumentError] if |startingBalancePaise| > [Money.maxPaise].
  Future<String> insert({
    required String userId,
    required String name,
    required AccountType type,
    required int startingBalancePaise,
  }) async {
    final cleanName = _validateName(name);
    _validateBalance(startingBalancePaise);

    return _db.transaction(() async {
      await _ensureNameFree(userId, cleanName);
      final id = generateId();
      await _db
          .into(_db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: id,
              userId: userId,
              name: cleanName,
              type: type,
              startingBalance: startingBalancePaise,
            ),
          );
      return id;
    });
  }

  /// Updates the given fields of account [id] (null = leave unchanged) and
  /// sets updated_at. Same validation as [insert]; renaming an account to
  /// its own current name is fine.
  ///
  /// Throws [ArgumentError] if there is no account with [id].
  Future<void> update(
    String id, {
    String? name,
    AccountType? type,
    int? startingBalancePaise,
  }) async {
    final cleanName = name == null ? null : _validateName(name);
    if (startingBalancePaise != null) _validateBalance(startingBalancePaise);

    await _db.transaction(() async {
      final current = await getById(id);
      if (current == null) {
        throw ArgumentError.value(id, 'id', 'no such account');
      }
      if (cleanName != null) {
        await _ensureNameFree(current.userId, cleanName, excludeId: id);
      }
      await (_db.update(_db.accounts)..where((t) => t.id.equals(id))).write(
        AccountsCompanion(
          name: Value.absentIfNull(cleanName),
          type: Value.absentIfNull(type),
          startingBalance: Value.absentIfNull(startingBalancePaise),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<AccountRow?> getById(String id) {
    return (_db.select(
      _db.accounts,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Every account for [userId] (archived included), oldest first, then by
  /// name.
  Future<List<AccountRow>> getAll(String userId) {
    return _selectForUser(userId).get();
  }

  /// Watches [userId]'s accounts with their computed balances, oldest
  /// first, then by name. Archived accounts are included; use
  /// [totalBalancePaise] and [creditCardDuesPaise] (which skip archived
  /// accounts) for the totals.
  ///
  /// Balances include the account's transactions (summed in SQL, see
  /// balance_queries.dart) and the stream re-emits when either accounts or
  /// transactions change.
  Stream<List<AccountWithBalance>> watchAccountsWithBalance(String userId) {
    return selectAccountsWithBalance(_db, userId: userId).watch();
  }

  SimpleSelectStatement<$AccountsTable, AccountRow> _selectForUser(
    String userId,
  ) {
    return _db.select(_db.accounts)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([
        (t) => OrderingTerm.asc(t.createdAt),
        (t) => OrderingTerm.asc(t.name),
      ]);
  }

  String _validateName(String raw) {
    final name = raw.trim();
    if (name.isEmpty) {
      throw const AccountValidationException(AccountValidationError.emptyName);
    }
    if (name.runes.length > maxNameLength) {
      throw const AccountValidationException(
        AccountValidationError.nameTooLong,
      );
    }
    return name;
  }

  void _validateBalance(int paise) {
    if (paise > Money.maxPaise || paise < -Money.maxPaise) {
      throw ArgumentError.value(
        paise,
        'startingBalancePaise',
        'must be within +/- Money.maxPaise (${Money.maxPaise})',
      );
    }
  }

  /// Case-insensitive duplicate check, compared in Dart (SQLite's lower()
  /// only folds ASCII). Archived accounts keep their names reserved.
  Future<void> _ensureNameFree(
    String userId,
    String name, {
    String? excludeId,
  }) async {
    final key = name.toLowerCase();
    final existing = await getAll(userId);
    final taken = existing.any(
      (a) => a.id != excludeId && a.name.toLowerCase() == key,
    );
    if (taken) {
      throw const AccountValidationException(
        AccountValidationError.duplicateName,
      );
    }
  }
}
