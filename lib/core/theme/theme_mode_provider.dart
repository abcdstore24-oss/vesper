import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _storageKey = 'vesper.theme_mode';
  static const _storage = FlutterSecureStorage();

  static ThemeMode initialMode = ThemeMode.system;

  @override
  ThemeMode build() => initialMode;

  static Future<ThemeMode> loadPersisted() async {
    final stored = await _storage.read(key: _storageKey);
    if (stored == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _storage.write(key: _storageKey, value: mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);