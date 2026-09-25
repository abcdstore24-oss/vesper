import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../db/db_provider.dart';

/// Extension of AppDatabase's generated `remoteStatusCache` table
/// accessor — mirrors UserProfileDao's pattern in user_profile_dao.dart
/// (a plain extension, not a @DriftAccessor, since this is a single
/// query and a full DAO class would need another codegen pass for no
/// real benefit at this scale).
extension RemoteStatusCacheDao on AppDatabase {
  /// Watches the single remote_status_cache row, or null if the
  /// device has never successfully checked in (table empty).
  Stream<RemoteStatusCacheRow?> watchRemoteStatus() {
    return (select(remoteStatusCache)..limit(1)).watchSingleOrNull();
  }

  /// One-off (non-stream) read of the same row, for main()'s
  /// pre-runApp seed. A StreamProvider hasn't emitted anything yet at
  /// that point in the app's lifecycle — this needs the real cached
  /// value as a single awaited Future instead.
  Future<RemoteStatusCacheRow?> getRemoteStatusOnce() {
    return (select(remoteStatusCache)..limit(1)).getSingleOrNull();
  }
}

/// Raw watch of the local cache row. Prefer [effectiveRemoteStatusProvider]
/// in UI code — this is exposed mainly for anything that needs
/// `lastCheckedAt` specifically (e.g. a future "last synced" label).
final remoteStatusCacheProvider = StreamProvider<RemoteStatusCacheRow?>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchRemoteStatus();
});

/// The current EFFECTIVE remote status: always available even fully
/// offline, since it's derived entirely from the local cache and never
/// touches the network itself.
///
/// A null cache (never successfully checked in) is treated as fully
/// open — this mirrors DATABASE.md's own column defaults
/// (maintenance_mode/kill_switch default false) without physically
/// seeding a row at startup, consistent with how user_profile is
/// already handled (nullable, no row until something creates one).
class EffectiveRemoteStatus {
  const EffectiveRemoteStatus({
    required this.maintenanceMode,
    required this.maintenanceMessage,
    required this.killSwitch,
  });

  final bool maintenanceMode;
  final String? maintenanceMessage;
  final bool killSwitch;

  static const open = EffectiveRemoteStatus(
    maintenanceMode: false,
    maintenanceMessage: null,
    killSwitch: false,
  );
}

EffectiveRemoteStatus _fromRow(RemoteStatusCacheRow? cached) {
  if (cached == null) return EffectiveRemoteStatus.open;
  return EffectiveRemoteStatus(
    maintenanceMode: cached.maintenanceMode,
    maintenanceMessage: cached.maintenanceMessage,
    killSwitch: cached.killSwitch,
  );
}

/// Cold-start-flash fix: the FIRST value this provider hands out must
/// already be the real cached status, not the `open` fallback for one
/// frame while remoteStatusCacheProvider's stream is still warming up.
///
/// [initialStatus] is set synchronously (well — awaited, pre-runApp)
/// in main() from a one-off query against the SAME AppDatabase
/// instance the rest of the app uses, via a manually-created
/// ProviderContainer + UncontrolledProviderScope. Same convention as
/// ThemeModeNotifier.initialMode / AppLockModeNotifier.initialMode.
///
/// After that seeded first value, this keeps updating reactively via
/// ref.listen on the existing remoteStatusCacheProvider stream —
/// ongoing behavior (re-check while MaintenanceScreen is mounted,
/// etc.) is unchanged; only what the first frame knows has changed.
class EffectiveRemoteStatusNotifier extends Notifier<EffectiveRemoteStatus> {
  static EffectiveRemoteStatus initialStatus = EffectiveRemoteStatus.open;

  @override
  EffectiveRemoteStatus build() {
    ref.listen<AsyncValue<RemoteStatusCacheRow?>>(remoteStatusCacheProvider, (
      previous,
      next,
    ) {
      final cached = next.valueOrNull;
      state = _fromRow(cached);
    });

    return initialStatus;
  }
}

final effectiveRemoteStatusProvider =
    NotifierProvider<EffectiveRemoteStatusNotifier, EffectiveRemoteStatus>(
      EffectiveRemoteStatusNotifier.new,
    );