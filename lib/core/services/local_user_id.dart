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

  /// Returns the persisted local user id, generating and storing one
  /// on first call if none exists yet.
  static Future<String> get() async {
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