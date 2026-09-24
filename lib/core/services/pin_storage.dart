import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Hashes and stores the custom PIN (App Lock mode b). Never stores the
/// PIN in plain text: SHA-256 over PIN + a random salt, both persisted
/// in flutter_secure_storage (Keystore/Keychain-backed) — the same
/// "treat as sensitive" rule already applied to the SQLCipher key in
/// app_database.dart. See task response for why SHA-256 via `crypto`
/// rather than a hand-rolled hash.
class PinStorage {
  const PinStorage._();

  /// Fixed PIN length used by both entry (LockScreen) and setup
  /// (PinSetupScreen) — must stay in sync between the two.
  static const pinLength = 6;

  static const _storage = FlutterSecureStorage();
  static const _saltKey = 'vesper.pin_salt';
  static const _hashKey = 'vesper.pin_hash';

  static Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    final hash = _hash(pin, salt);
    await _storage.write(key: _saltKey, value: salt);
    await _storage.write(key: _hashKey, value: hash);
  }

  static Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _saltKey);
    final storedHash = await _storage.read(key: _hashKey);
    if (salt == null || storedHash == null) return false;
    return _hash(pin, salt) == storedHash;
  }

  static Future<bool> hasPin() async {
    final storedHash = await _storage.read(key: _hashKey);
    return storedHash != null;
  }

  static Future<void> clearPin() async {
    await _storage.delete(key: _saltKey);
    await _storage.delete(key: _hashKey);
  }

  static String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String _hash(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }
}
