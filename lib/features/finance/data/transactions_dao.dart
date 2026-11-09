import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/money.dart';
import 'accounts_dao.dart';
import 'balance_queries.dart';
import 'categories_dao.dart';
import 'categories_table.dart';
import 'transaction_queries.dart';
import 'transactions_table.dart';

/// Why a transaction change was rejected.
enum TransactionValidationError {
  invalidAmount,
  accountNotFound,
  toAccountNotFound,
  sameAccount,
  accountArchived,
  categoryRequired,
  categoryInvalid,
  categoryNotAllowed,
  noteTooLong,
  futureDate,
  sourceIncomplete,
  linkedToSource,
  notFound,
  balanceOutOfRange,
}

/// Thrown by [TransactionsDao] when a change breaks a rule. Deliberately
/// carries no user text (no note, amount or name), so it is safe to log.
class TransactionValidationException implements Exception {
  const TransactionValidationException(this.error);

  final TransactionValidationError error;

  @override
  String toString() => 'TransactionValidationException(${error.name})';
}

/// Insert, update, delete and read access to `transactions`.
///
/// EVERY change runs in ONE database transaction: validate, write, then
/// check that no affected account's computed balance leaves +/-
/// Money.maxPaise. Any failure throws [TransactionValidationException]
/// (or rolls back) and NOTHING is written.
///
/// A plain class over [AppDatabase] (no @DriftAccessor), like the other
/// DAOs. [clock] is for tests (defaults to DateTime.now).
class TransactionsDao {
  TransactionsDao(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Longest allowed note, in characters (Unicode code points).
  static const int maxNoteLength = 100;

  final AppDatabase _db;
  final DateTime Function() _clock;

  /// Creates a transaction and returns its id.
  ///
  /// - [amountPaise]: 1..[Money.maxPaise]; the direction comes from [type].
  /// - income/expense: [categoryId] is required (see the rules below);
  ///   [toAccountId] must be null.
  /// - transfer: [toAccountId] is required and must differ from
  ///   [accountId]; [categoryId] and [source] must be null.
  /// - [source] and [sourceId] are both null or both set. A row with a
  ///   source is made by a loan payment or investment trade; its category
  ///   must be a `system` category. Without a source, the category must be
  ///   a non-archived income/expense category matching [type].
  /// - Both accounts must exist, belong to [userId] and not be archived.
  /// - [occurredAt] must not be later than the end of today (local time).
  Future<String> insert({
    required String userId,
    required String accountId,
    required TransactionType type,
    required int amountPaise,
    String? categoryId,
    String? toAccountId,
    String? note,
    required DateTime occurredAt,
    TransactionSource? source,
    String? sourceId,
  }) {
    return _db.transaction(() async {
      final cleanNote = await _validate(
        userId: userId,
        accountId: accountId,
        type: type,
        amountPaise: amountPaise,
        categoryId: categoryId,
        toAccountId: toAccountId,
        note: note,
        occurredAt: occurredAt,
        source: source,
        sourceId: sourceId,
      );

      final id = generateId();
      await _db
          .into(_db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: id,
              userId: userId,
              accountId: accountId,
              type: type,
              amount: amountPaise,
              occurredAt: occurredAt,
              toAccountId: Value(toAccountId),
              categoryId: Value(categoryId),
              note: Value(cleanNote),
              sourceType: Value(source),
              sourceId: Value(sourceId),
            ),
          );

      await _checkBalances(userId, {accountId, ?toAccountId});
      return id;
    });
  }

  /// Replaces the editable fields of transaction [id] with the values given
  /// (they are the NEW complete state: a null [categoryId], [toAccountId] or
  /// [note] clears it), with the same validation as [insert], and sets
  /// updated_at. The row's user and source cannot be changed.
  ///
  /// A row with a source throws [TransactionValidationError.linkedToSource]
  /// unless [bySource] is true. [bySource] is for the loans/investments
  /// code that owns such rows; no UI uses it.
  ///
  /// Category rule on update: an ARCHIVED category is accepted when it equals
  /// the row's CURRENT category_id (the row may keep it); any other category
  /// must still be active, and every other category rule is unchanged.
  /// Accounts are not relaxed: an archived account is still rejected.
  Future<void> update(
    String id, {
    required String accountId,
    required TransactionType type,
    required int amountPaise,
    String? categoryId,
    String? toAccountId,
    String? note,
    required DateTime occurredAt,
    bool bySource = false,
  }) {
    return _db.transaction(() async {
      final old = await getById(id);
      if (old == null) {
        throw const TransactionValidationException(
          TransactionValidationError.notFound,
        );
      }
      if (old.sourceType != null && !bySource) {
        throw const TransactionValidationException(
          TransactionValidationError.linkedToSource,
        );
      }

      final cleanNote = await _validate(
        userId: old.userId,
        accountId: accountId,
        type: type,
        amountPaise: amountPaise,
        categoryId: categoryId,
        toAccountId: toAccountId,
        note: note,
        occurredAt: occurredAt,
        source: old.sourceType,
        sourceId: old.sourceId,
        keepCategoryId: old.categoryId,
      );

      await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(
          accountId: Value(accountId),
          toAccountId: Value(toAccountId),
          categoryId: Value(categoryId),
          amount: Value(amountPaise),
          type: Value(type),
          note: Value(cleanNote),
          occurredAt: Value(occurredAt),
          updatedAt: Value(_clock()),
        ),
      );

      await _checkBalances(old.userId, {
        old.accountId,
        ?old.toAccountId,
        accountId,
        ?toAccountId,
      });
    });
  }

  /// Deletes transaction [id]. A row with a source throws
  /// [TransactionValidationError.linkedToSource] unless [bySource] is true.
  /// Deleting can push a balance out of range (for example an income that
  /// was offsetting a large negative starting balance), which is rejected
  /// with [TransactionValidationError.balanceOutOfRange].
  Future<void> delete(String id, {bool bySource = false}) {
    return _db.transaction(() async {
      final old = await getById(id);
      if (old == null) {
        throw const TransactionValidationException(
          TransactionValidationError.notFound,
        );
      }
      if (old.sourceType != null && !bySource) {
        throw const TransactionValidationException(
          TransactionValidationError.linkedToSource,
        );
      }

      await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();

      await _checkBalances(old.userId, {old.accountId, ?old.toAccountId});
    });
  }

  /// Watches [userId]'s [limit] most recent transactions with category and
  /// account names, newest first. Re-emits when transactions, categories or
  /// accounts change.
  Stream<List<TransactionListItem>> watchRecent(
    String userId, {
    int limit = 5,
  }) {
    return selectRecentTransactions(_db, userId: userId, limit: limit).watch();
  }

  /// Watches ALL of [userId]'s transactions, newest first, optionally only
  /// those of [type] (null = every type; filtered in SQL). No limit: the UI
  /// builds its list lazily. Re-emits when transactions, categories or
  /// accounts change.
  Stream<List<TransactionListItem>> watchAll(
    String userId, {
    TransactionType? type,
  }) {
    return selectRecentTransactions(_db, userId: userId, type: type).watch();
  }

  Future<TransactionRow?> getById(String id) {
    return (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Validates a complete transaction state and returns the normalized note
  /// (trimmed; empty becomes null). Must run inside the write transaction.
  Future<String?> _validate({
    required String userId,
    required String accountId,
    required TransactionType type,
    required int amountPaise,
    required String? categoryId,
    required String? toAccountId,
    required String? note,
    required DateTime occurredAt,
    required TransactionSource? source,
    required String? sourceId,
    String? keepCategoryId,
  }) async {
    // Source: both set or both null. A transfer cannot carry one (reported
    // as sourceIncomplete: the source information is inconsistent).
    final sourceIdBlank = sourceId != null && sourceId.trim().isEmpty;
    if ((source == null) != (sourceId == null) ||
        sourceIdBlank ||
        (type == TransactionType.transfer && source != null)) {
      throw const TransactionValidationException(
        TransactionValidationError.sourceIncomplete,
      );
    }

    if (amountPaise < 1 || amountPaise > Money.maxPaise) {
      throw const TransactionValidationException(
        TransactionValidationError.invalidAmount,
      );
    }

    final cleanNote = _normalizeNote(note);

    // A future-dated entry would change today's balance, so none are
    // allowed: later than the end of today (local time) is rejected.
    final now = _clock();
    final startOfTomorrow = DateTime(now.year, now.month, now.day + 1);
    if (!occurredAt.isBefore(startOfTomorrow)) {
      throw const TransactionValidationException(
        TransactionValidationError.futureDate,
      );
    }

    final accountsDao = AccountsDao(_db);

    if (type == TransactionType.transfer) {
      if (toAccountId == null) {
        throw const TransactionValidationException(
          TransactionValidationError.toAccountNotFound,
        );
      }
      if (toAccountId == accountId) {
        throw const TransactionValidationException(
          TransactionValidationError.sameAccount,
        );
      }
      if (categoryId != null) {
        throw const TransactionValidationException(
          TransactionValidationError.categoryNotAllowed,
        );
      }
    } else if (toAccountId != null) {
      // Only transfers have a destination account.
      throw const TransactionValidationException(
        TransactionValidationError.toAccountNotFound,
      );
    }

    final from = await accountsDao.getById(accountId);
    if (from == null || from.userId != userId) {
      throw const TransactionValidationException(
        TransactionValidationError.accountNotFound,
      );
    }
    if (from.isArchived) {
      throw const TransactionValidationException(
        TransactionValidationError.accountArchived,
      );
    }
    if (toAccountId != null) {
      final to = await accountsDao.getById(toAccountId);
      if (to == null || to.userId != userId) {
        throw const TransactionValidationException(
          TransactionValidationError.toAccountNotFound,
        );
      }
      if (to.isArchived) {
        throw const TransactionValidationException(
          TransactionValidationError.accountArchived,
        );
      }
    }

    if (type != TransactionType.transfer) {
      if (categoryId == null) {
        throw const TransactionValidationException(
          TransactionValidationError.categoryRequired,
        );
      }
      final category = await CategoriesDao(_db).getById(categoryId);
      if (category == null || category.userId != userId) {
        throw const TransactionValidationException(
          TransactionValidationError.categoryInvalid,
        );
      }
      if (source == null) {
        final expected = type == TransactionType.income
            ? CategoryKind.income
            : CategoryKind.expense;
        // An archived category is accepted only when it is the one the row
        // already has (update passes it as [keepCategoryId]); the kind must
        // still match the chosen type.
        final archivedNotKept =
            category.isArchived && category.id != keepCategoryId;
        if (archivedNotKept || category.kind != expected) {
          throw const TransactionValidationException(
            TransactionValidationError.categoryInvalid,
          );
        }
      } else if (category.kind != CategoryKind.system) {
        throw const TransactionValidationException(
          TransactionValidationError.categoryInvalid,
        );
      }
    }

    return cleanNote;
  }

  String? _normalizeNote(String? raw) {
    if (raw == null) return null;
    final note = raw.trim();
    if (note.isEmpty) return null;
    if (note.runes.length > maxNoteLength) {
      throw const TransactionValidationException(
        TransactionValidationError.noteTooLong,
      );
    }
    return note;
  }

  /// After the write: no affected account's computed balance may fall
  /// outside +/- Money.maxPaise (so a balance can always be displayed).
  /// Throwing here rolls the whole database transaction back.
  Future<void> _checkBalances(String userId, Set<String> accountIds) async {
    final accounts = await selectAccountsWithBalance(
      _db,
      userId: userId,
      accountIds: accountIds,
    ).get();
    for (final a in accounts) {
      if (a.balancePaise > Money.maxPaise || a.balancePaise < -Money.maxPaise) {
        throw const TransactionValidationException(
          TransactionValidationError.balanceOutOfRange,
        );
      }
    }
  }
}
