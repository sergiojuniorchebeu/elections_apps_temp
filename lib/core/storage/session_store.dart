import 'dart:convert';

import '../session/session.dart';
import 'secure_store.dart';

/// Persists the [Session] in the Keychain / Keystore only.
final class SessionStore {
  SessionStore(this._secure);

  static const _key = 'session.v1';
  final SecureStore _secure;

  Future<Session?> read() async {
    final raw = await _secure.read(_key);
    if (raw == null) return null;
    try {
      return Session.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      await _secure.delete(_key);
      return null;
    }
  }

  Future<void> write(Session session) =>
      _secure.write(_key, jsonEncode(session.toJson()));

  Future<void> clear() => _secure.delete(_key);
}
