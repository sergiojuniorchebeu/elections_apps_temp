import 'dart:async';

import '../error/failure.dart';
import '../storage/session_store.dart';
import 'session.dart';

/// Renews a session from its refresh token. Throws [AuthFailure] with
/// `sessionEnded: true` when the refresh token is refused, any other
/// [Failure] (network...) when the answer is unknown.
typedef SessionRenewer = Future<Session> Function(Session current);

/// The current session, shared by every implementation (REST client,
/// simulator...). Renewal is single-flight: concurrent 401s wait for the
/// same renewal. A network error during renewal never signs out.
final class SessionHolder {
  SessionHolder(this._store);

  final SessionStore _store;
  Session? _session;
  Future<Session>? _renewing;
  SessionRenewer? renewer;

  final _ended = StreamController<void>.broadcast();

  /// Fires when the session can't be renewed: the app signs out.
  Stream<void> get onEnded => _ended.stream;

  Session? get current => _session;

  Future<Session?> restore() async => _session = await _store.read();

  Future<void> set(Session session) async {
    _session = session;
    await _store.write(session);
  }

  Future<void> clear() async {
    _session = null;
    _renewing = null;
    await _store.clear();
  }

  /// Renews once, whatever the number of callers.
  Future<Session> renew() {
    final current = _session;
    if (current == null) {
      return Future.error(const AuthFailure(sessionEnded: true));
    }
    final renewer = this.renewer;
    if (renewer == null) {
      return Future.error(const AuthFailure(sessionEnded: true));
    }
    return _renewing ??= () async {
      try {
        final next = await renewer(current);
        // Signed out meanwhile: don't resurrect the session.
        if (_session?.refreshToken != current.refreshToken) {
          throw const AuthFailure(sessionEnded: true);
        }
        await set(next);
        return next;
      } on AuthFailure catch (f) {
        if (f.sessionEnded && _session?.refreshToken == current.refreshToken) {
          await clear();
          _ended.add(null);
        }
        rethrow;
      } finally {
        _renewing = null;
      }
    }();
  }

  void dispose() => _ended.close();
}
