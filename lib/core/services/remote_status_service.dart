import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/app_database.dart';

/// Fetches AI/API.md's public `app_status` row from Supabase — anon,
/// no auth, SELECT-only per RLS — and caches the result into the LOCAL
/// `remote_status_cache` table. Never the reverse: this service never
/// writes to `app_status`, and never should (RLS wouldn't allow it
/// anyway).
class RemoteStatusService {
  const RemoteStatusService(this._db);

  final AppDatabase _db;

  /// Short timeout so a slow or absent network never leaves the app
  /// hanging — flagged in task response, revisit if 5s proves too
  /// eager or too lax in practice.
  static const _timeout = Duration(seconds: 5);

  /// remote_status_cache is a device-scoped singleton (DATABASE.md /
  /// DECISIONS.md "remote_status_cache field set confirmed") — there
  /// is only ever one row, keyed by a fixed id rather than a generated
  /// UUID, so writes are a plain upsert with no read-then-branch race.
  static const _cacheRowId = 'remote_status_cache_singleton';

  /// Attempts a connected check against `app_status`. On success,
  /// overwrites the local cache. On ANY failure — no connectivity, a
  /// timeout, a Postgrest/RLS error, anything at all — this is a
  /// silent no-op: `remote_status_cache` is left completely untouched.
  /// Per API.md's offline rule: "absence of a successful check =
  /// fall back to cached status = normal operation if nothing was
  /// ever confirmed."
  Future<void> checkAndCache() async {
    try {
      final row = await Supabase.instance.client
          .from('app_status')
          .select('maintenance_mode, maintenance_message, kill_switch')
          .eq('id', 1)
          .single()
          .timeout(_timeout);

      final maintenanceMode = row['maintenance_mode'] as bool? ?? false;
      final maintenanceMessage = row['maintenance_message'] as String?;
      final killSwitch = row['kill_switch'] as bool? ?? false;

      // "As of the last successful check, is the app in a fully
      // normal state" — not just "did the network call succeed."
      // Confirmed semantics, see task response.
      final lastKnownGood = !maintenanceMode && !killSwitch;

      await _db
          .into(_db.remoteStatusCache)
          .insertOnConflictUpdate(
            RemoteStatusCacheCompanion(
              id: const Value(_cacheRowId),
              lastCheckedAt: Value(DateTime.now()),
              maintenanceMode: Value(maintenanceMode),
              maintenanceMessage: Value(maintenanceMessage),
              killSwitch: Value(killSwitch),
              lastKnownGood: Value(lastKnownGood),
            ),
          );
    } catch (_) {
      // Deliberately swallowed — see doc comment above. No logging of
      // the specific failure reason here either; nothing about a
      // failed status check needs to leak into app behavior beyond
      // "cache stays as it was."
    }
  }
}