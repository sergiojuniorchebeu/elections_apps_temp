import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Key/value contract over the Keychain (iOS) / Keystore (Android).
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
  Future<Map<String, String>> readAll();
}

/// "This device only": never synced to iCloud, never restored on another
/// phone (Android backups are off: `allowBackup="false"`).
final class KeychainStore implements SecureStore {
  KeychainStore()
    : _storage = const FlutterSecureStorage(
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
          synchronizable: false,
        ),
      );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
  @override
  Future<void> deleteAll() => _storage.deleteAll();
  @override
  Future<Map<String, String>> readAll() => _storage.readAll();
}

final class MemorySecureStore implements SecureStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
  @override
  Future<void> deleteAll() async => values.clear();
  @override
  Future<Map<String, String>> readAll() async => {...values};
}
