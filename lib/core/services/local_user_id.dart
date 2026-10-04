import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../db/app_database.dart' show generateId;

/// The local, device-generated stand-in for `user_id`, used by every
/// row this app writes while no Supabase account exists — DATABASE.md
/// rule 3: "user_id... backed by a local device-generated UUID
/// until/unless an account is created."
///
/// This is the first real implementation of that mechanism — nothing
/// in the codebase populated it before this task (see the task
/// response: `user_profile.userId` is nullable and never set by
/// anything). Generated once via the existing `generateId()` (no
/// `uuid` package, per DECISIONS.md's standing approach) and persisted
/// in flutter_secure_storage — same storage class already used for the
/// SQLCipher key (app_database.dart) and the PIN hash
/// (pin_storage.dart).
///
/// Every future feature that writes user-scoped rows should call
/// [LocalUserId.get] rather than generating or storing a second local
/// id — this is meant to be the one mechanism, per the task brief.
class LocalUserId {
  const LocalUserId._();

  static const _storage = FlutterSecureStorage();
  static const _key = 'vesper.local_user_id';

  /// FIXED this task: memoizes the in-flight Future itself, not just
  /// the resolved string. On a fresh install, many providers call
  /// get() near-simultaneously; without this, each concurrent call
  /// would independently see "no ID exists yet" (the secure-storage
  /// read hadn't completed for any of them), each generate a
  /// DIFFERENT id, and each write — different parts of the app then
  /// operating under different user_ids until a cold restart forced
  /// everyone to re-read whichever value ended up persisted last.
  /// Confirmed via real on-device reproduction (see task).
  ///
  /// get() is deliberately NOT async — its body has no await, so it
  /// runs to completion in one uninterrupted turn of Dart's
  /// single-threaded event loop. The first call's `??=` creates and
  /// caches _loadOrCreate()'s Future; every call after that —
  /// regardless of how many arrive before the first one resolves —
  /// returns that SAME cached Future reference, so all callers end up
  /// awaiting one shared read-or-create operation rather than each
  /// starting their own.
  ///
  /// Known, accepted limitation (not fixed here, matches the exact
  /// approach specified): if _loadOrCreate() ever throws, _future
  /// caches as a failed Future and every subsequent call repeats that
  /// same failure — there's no retry.
  static Future<String>? _future;

  static Future<String> get() {
    return _future ??= _loadOrCreate();
  }

  static Future<String> _loadOrCreate() async {
    final existing = await _storage.read(key: _key);
    if (existing != null) return existing;

    final generated = generateId();
    await _storage.write(key: _key, value: generated);
    return generated;
  }
}

/// Riverpod-friendly wrapper, for widgets/providers that need the id
/// without importing flutter_secure_storage directly.
final localUserIdProvider = FutureProvider<String>((ref) => LocalUserId.get());