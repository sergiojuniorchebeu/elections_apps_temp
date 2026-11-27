import 'dart:convert';

import 'secure_store.dart';

/// Last answer of the main screens, so they open instantly and stay
/// readable offline.
///
/// Stored in the Keychain / Keystore (encrypted at rest by the OS) and
/// dropped after [maxAge]. Cleared on sign-out.
final class OfflineStore {
  OfflineStore(this._secure, {this.maxAge = const Duration(days: 7)});

  static const _prefix = 'offline.';
  final SecureStore _secure;
  final Duration maxAge;
  DateTime Function() clock = DateTime.now;

  Future<OfflineCopy?> read(String key) async {
    final raw = await _secure.read('$_prefix$key');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, Object?>;
      final savedAt = DateTime.parse(map['saved_at']! as String);
      if (clock().difference(savedAt) > maxAge) {
        await _secure.delete('$_prefix$key');
        return null;
      }
      return OfflineCopy(map['data'], savedAt);
    } on Object {
      await _secure.delete('$_prefix$key');
      return null;
    }
  }

  Future<void> write(String key, Object? json) => _secure.write(
    '$_prefix$key',
    jsonEncode({'saved_at': clock().toIso8601String(), 'data': json}),
  );

  Future<void> clear() async {
    final all = await _secure.readAll();
    for (final key in all.keys.where((k) => k.startsWith(_prefix))) {
      await _secure.delete(key);
    }
  }
}

final class OfflineCopy {
  const OfflineCopy(this.data, this.savedAt);
  final Object? data;
  final DateTime savedAt;
}
