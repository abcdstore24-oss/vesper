import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// CLAUDE.md Section 4, layer 2 — local app lock modes.
enum AppLockMode { os, pin, off }

/// Persists the chosen [AppLockMode]. Mirrors ThemeModeNotifier's
/// pattern: [initialMode] is set (via [loadPersisted]) BEFORE runApp,
/// so the correct mode — and therefore whether to show the lock screen
/// at all — is known from the very first frame, not one frame late.
class AppLockModeNotifier extends Notifier<AppLockMode> {
  static const _storageKey = 'vesper.app_lock_mode';
  static const _storage = FlutterSecureStorage();

  /// CLAUDE.md Section 4: OS-level device lock is "default/recommended"
  /// — so a fresh install with nothing persisted yet starts on `os`,
  /// not `off`. Never mandatory, but on by default.
  static AppLockMode initialMode = AppLockMode.os;

  static Future<AppLockMode> loadPersisted() async {
    final stored = await _storage.read(key: _storageKey);
    if (stored == null) return AppLockMode.os;
    for (final mode in AppLockMode.values) {
      if (mode.name == stored) return mode;
    }
    return AppLockMode.os;
  }

  @override
  AppLockMode build() => initialMode;

  Future<void> setMode(AppLockMode mode) async {
    state = mode;
    await _storage.write(key: _storageKey, value: mode.name);
  }
}

final appLockModeProvider =
    NotifierProvider<AppLockModeNotifier, AppLockMode>(
      AppLockModeNotifier.new,
    );

/// Whether the app is unlocked THIS SESSION only. Always starts false
/// on a fresh process — deliberately never persisted, so a real cold
/// start always requires unlocking again when mode != off, per
/// CLAUDE.md Section 1.
class IsUnlockedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void unlock() => state = true;
  void lock() => state = false;
}

final isUnlockedProvider = NotifierProvider<IsUnlockedNotifier, bool>(
  IsUnlockedNotifier.new,
);

class AuthPromptActiveNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final authPromptActiveProvider =
    NotifierProvider<AuthPromptActiveNotifier, bool>(
      AuthPromptActiveNotifier.new,
    );