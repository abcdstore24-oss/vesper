import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';
import '../domain/category_kind.dart';
import '../domain/recurrence_frequency.dart';
import 'transactions_dao.dart'; // insertTransaction

extension RecurringRulesDao on AppDatabase {
  Stream<List<RecurringTransactionRuleRow>> watchRules(String userId) {
    return (select(recurringTransactionRules)
          ..where((r) => r.userId.equals(userId))
          ..orderBy([(r) => OrderingTerm.asc(r.nextDueDate)]))
        .watch();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> insertRule({
    required String userId,
    required String accountId,
    required String categoryId,
    required int amountCents,
    required String note,
    required RecurrenceFrequency frequency,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final id = generateId();
    final startDateOnly = _dateOnly(startDate);
    final endDateOnly = endDate == null ? null : _dateOnly(endDate);

    await transaction(() async {
      await into(recurringTransactionRules).insert(
        RecurringTransactionRulesCompanion.insert(
          id: id,
          userId: userId,
          accountId: accountId,
          categoryId: categoryId,
          amountCents: amountCents,
          note: Value(note),
          frequency: frequency.name,
          startDate: startDateOnly,
          endDate: Value(endDateOnly),
          nextDueDate: startDateOnly,
        ),
      );

      // CHANGED this task (ripple from Bug 3's fix): previously
      // constructed a RecurringTransactionRuleRow manually in memory
      // to pass to _generateForRule. Now that _generateForRule
      // re-selects fresh by id (Bug 3), this just calls it with the
      // id just inserted — simpler, and re-reads the real committed
      // row rather than trusting a hand-built copy.
      await _generateForRule(userId, id);
    });
  }

  Future<void> updateRule({
    required String id,
    required String accountId,
    required String categoryId,
    required int amountCents,
    required String note,
    required RecurrenceFrequency frequency,
    DateTime? endDate,
  }) {
    return (update(recurringTransactionRules)..where((r) => r.id.equals(id))).write(
      RecurringTransactionRulesCompanion(
        accountId: Value(accountId),
        categoryId: Value(categoryId),
        amountCents: Value(amountCents),
        note: Value(note),
        frequency: Value(frequency.name),
        endDate: Value(endDate == null ? null : _dateOnly(endDate)),
        updatedAt: Value(DateTime.now()),
      ),
    );
    // Bug 7 (frequency edit not realigning nextDueDate) is NOT fixed
    // here — confirmed minor, deferred per task response. Logged in
    // DECISIONS.md.
  }

  /// CHANGED this task (Bug 2, required fix): reactivating a paused
  /// rule no longer backfills the paused window. If the rule's
  /// current nextDueDate is before today, it's advanced forward
  /// (using the SAME nextAfter logic generation uses, anchored to
  /// rule.startDate — never a different/evolving date) to the first
  /// occurrence on or after today, with NO transactions generated for
  /// anything skipped. If nextDueDate is already >= today, nothing
  /// about it changes.
  Future<void> setRuleActive({required String id, required bool isActive}) async {
    if (!isActive) {
      // Pausing: just flip the flag. nextDueDate is untouched —
      // generation already only ever selects isActive==true rules,
      // so this alone is what freezes it (unchanged from before).
      await (update(recurringTransactionRules)..where((r) => r.id.equals(id))).write(
        RecurringTransactionRulesCompanion(isActive: Value(false), updatedAt: Value(DateTime.now())),
      );
      return;
    }

    await transaction(() async {
      final rule = await (select(recurringTransactionRules)..where((r) => r.id.equals(id))).getSingle();
      final todayDateOnly = _dateOnly(DateTime.now());
      final freq = RecurrenceFrequency.values.byName(rule.frequency);

      var due = rule.nextDueDate;
      // Skip-forward only — no insertTransaction call anywhere in
      // this loop, by construction. anchor is always rule.startDate,
      // read once from this same freshly-selected row, never
      // reassigned.
      while (_dateOnly(due).isBefore(todayDateOnly)) {
        due = freq.nextAfter(due, rule.startDate);
      }

      await (update(recurringTransactionRules)..where((r) => r.id.equals(id))).write(
        RecurringTransactionRulesCompanion(
          isActive: const Value(true),
          nextDueDate: Value(due),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<void> deleteRule(String id) {
    return (delete(recurringTransactionRules)..where((r) => r.id.equals(id))).go();
  }

  Future<int> countRulesForAccount(String accountId) async {
    final rows = await (select(recurringTransactionRules)..where((r) => r.accountId.equals(accountId))).get();
    return rows.length;
  }

  Future<int> countRulesForCategory(String categoryId) async {
    final rows = await (select(recurringTransactionRules)..where((r) => r.categoryId.equals(categoryId))).get();
    return rows.length;
  }

  /// CHANGED this task (Bug 3, required fix): now takes a String
  /// ruleId instead of a RecurringTransactionRuleRow. The rule is
  /// re-selected by id as the FIRST statement here — since this
  /// entire function body runs inside the caller's transaction()
  /// block (checkAndGenerateDueTransactions, or insertRule's own),
  /// this re-select is the first statement INSIDE that transaction,
  /// exactly closing the race where two overlapping checks could
  /// both act on the same stale in-memory nextDueDate.
  Future<int> _generateForRule(String userId, String ruleId) async {
    final rule = await (select(recurringTransactionRules)..where((r) => r.id.equals(ruleId))).getSingleOrNull();
    if (rule == null || !rule.isActive) return 0;

    final todayDateOnly = _dateOnly(DateTime.now());
    final freq = RecurrenceFrequency.values.byName(rule.frequency);
    var due = rule.nextDueDate;
    var count = 0;

    while (count < 60) {
      final dueDateOnly = _dateOnly(due);
      // THE guard — nothing below this line runs if due is in the
      // future. Unchanged from last task; still the core safety
      // property this whole feature depends on.
      if (dueDateOnly.isAfter(todayDateOnly)) break;
      if (rule.endDate != null && dueDateOnly.isAfter(_dateOnly(rule.endDate!))) break;

      final category = await (select(categories)..where((c) => c.id.equals(rule.categoryId))).getSingleOrNull();
      if (category == null) {
        // Defense-in-depth only (Bug 6) — structurally unreachable
        // under normal use now that deleteCategory blocks on
        // referencing rules, per task response. Still visibly
        // surfaced in recurring_screen.dart rather than silently
        // stalling with zero indication.
        break;
      }
      final kind = CategoryKind.values.byName(category.kind);

      await insertTransaction(
        userId: userId,
        accountId: rule.accountId,
        categoryId: rule.categoryId,
        amountCents: rule.amountCents,
        type: kind,
        note: rule.note,
        occurredAt: due,
        isRecurring: true,
        recurringRuleId: rule.id,
      );

      count += 1;
      // anchor is rule.startDate — the same fresh row read above,
      // never a reassigned or evolving variable. due is the one
      // thing that advances each iteration.
      due = freq.nextAfter(due, rule.startDate);
    }

    if (count > 0) {
      await (update(recurringTransactionRules)..where((r) => r.id.equals(rule.id))).write(
        RecurringTransactionRulesCompanion(
          nextDueDate: Value(due),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }

    return count;
  }

  /// CHANGED this task: fetches only ids for the initial scan (the
  /// outer, non-transactional read now decides WHICH rules to
  /// attempt, never acts on their data directly — the per-rule
  /// transaction's internal re-select, above, is what's authoritative).
  Future<({int transactionCount, int ruleCount})> checkAndGenerateDueTransactions(String userId) async {
    final activeRuleIds = await (select(recurringTransactionRules)
          ..where((r) => r.userId.equals(userId) & r.isActive.equals(true)))
        .map((r) => r.id)
        .get();

    var totalGenerated = 0;
    var rulesThatFired = 0;
    for (final ruleId in activeRuleIds) {
      final generated = await transaction(() => _generateForRule(userId, ruleId));
      if (generated > 0) {
        totalGenerated += generated;
        rulesThatFired += 1;
      }
    }
    return (transactionCount: totalGenerated, ruleCount: rulesThatFired);
  }
}

class AccountHasRecurringRuleException implements Exception {
  AccountHasRecurringRuleException(this.count);
  final int count;
}

class CategoryHasRecurringRuleException implements Exception {
  CategoryHasRecurringRuleException(this.count);
  final int count;
}

final recurringRulesProvider = StreamProvider<List<RecurringTransactionRuleRow>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final userId = await LocalUserId.get();
  yield* db.watchRules(userId);
});

final recurringGenerationProvider = FutureProvider<({int transactionCount, int ruleCount})>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final userId = await LocalUserId.get();
  return db.checkAndGenerateDueTransactions(userId);
});