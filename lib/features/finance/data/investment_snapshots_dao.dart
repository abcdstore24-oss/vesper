import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/services/local_user_id.dart';

extension InvestmentSnapshotsDao on AppDatabase {
  /// Inserts one snapshot at [recordedAt] (always DateTime.now() at
  /// every call site in this project — see the doc comment on
  /// InvestmentValueSnapshots.recordedAt in app_database.dart for the
  /// backdated-sale limitation this implies). Plain insert, no
  /// transaction of its own — every call site wraps this inside its
  /// OWN db.transaction, so nothing nests.
  Future<void> recordInvestmentSnapshot({
    required String userId,
    required String investmentId,
    required int valueCents,
    required DateTime recordedAt,
  }) async {
    await into(investmentValueSnapshots).insert(
      InvestmentValueSnapshotsCompanion.insert(
        id: generateId(),
        userId: userId,
        investmentId: investmentId,
        valueCents: valueCents,
        recordedAt: recordedAt,
      ),
    );
  }

  /// One-time top-up for investments that predate this task and
  /// therefore have zero snapshots — same standing pattern as
  /// ensureInvestmentsCategoryExists (categories_dao.dart). Inserts
  /// exactly one snapshot, at now, using each such investment's
  /// current_value_cents.
  ///
  /// Idempotency: check-then-insert, wrapped in ONE db.transaction
  /// (stronger than the category top-up, per task response) — the
  /// "which investments already have a snapshot" read and every
  /// insert for this call happen inside a single transaction, so a
  /// concurrent write from a user action (e.g. Update Value, which
  /// also writes a snapshot) that lands mid-transaction is either
  /// fully visible to this read (if it committed first) or fully
  /// isolated from it (if it hasn't yet) — never a partial view that
  /// could cause a duplicate. Combined with this running inside a
  /// plain non-family FutureProvider (below), whose body Riverpod
  /// only ever invokes once per app session regardless of watcher
  /// count, there's no path to a duplicate snapshot from this
  /// function, across launches or within one.
  Future<void> ensureInvestmentSnapshotsExist(String userId) async {
    await transaction(() async {
      final userInvestments = await (select(investments)..where((i) => i.userId.equals(userId))).get();
      if (userInvestments.isEmpty) return;

      final covered = await (selectOnly(investmentValueSnapshots)
            ..addColumns([investmentValueSnapshots.investmentId])
            ..where(investmentValueSnapshots.userId.equals(userId))
            ..groupBy([investmentValueSnapshots.investmentId]))
          .map((row) => row.read(investmentValueSnapshots.investmentId)!)
          .get();
      final coveredIds = covered.toSet();

      final now = DateTime.now();
      final toInsert = userInvestments.where((inv) => !coveredIds.contains(inv.id)).toList();
      if (toInsert.isEmpty) return;

      await batch((b) {
        b.insertAll(investmentValueSnapshots, [
          for (final inv in toInsert)
            InvestmentValueSnapshotsCompanion.insert(
              id: generateId(),
              userId: userId,
              investmentId: inv.id,
              valueCents: inv.currentValueCents,
              recordedAt: now,
            ),
        ]);
      });
    });
  }
  /// NEW this task — all of userId's investment value snapshots,
  /// across EVERY investment, unfiltered by date. One subscription
  /// for the Charts tab's net worth section to fold as-of-date values
  /// from in Dart for all 6 months, rather than one subscription per
  /// investment (investmentSalesProvider-style) or per month.
  Stream<List<InvestmentValueSnapshotRow>> watchAllInvestmentSnapshots(String userId) {
    return (select(investmentValueSnapshots)..where((s) => s.userId.equals(userId))).watch();
  }
}

/// Sibling to categoriesSeedProvider (categories_dao.dart) — a plain
/// non-family FutureProvider, watched from investments_list_screen.dart
/// (the one place investmentsProvider is watched), so the top-up runs
/// on normal app use and only once per session regardless of watcher
/// count.
final investmentSnapshotsSeedProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final userId = await LocalUserId.get();
  await db.ensureInvestmentSnapshotsExist(userId);
});

final allInvestmentSnapshotsProvider = StreamProvider<List<InvestmentValueSnapshotRow>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final userId = await LocalUserId.get();
  yield* db.watchAllInvestmentSnapshots(userId);
});