import 'dart:async';
import 'dart:math';

import '../core/error/failure.dart';
import '../core/session/session.dart';
import '../core/session/session_holder.dart';
import 'mock_accounts.dart';
import 'scenario.dart';
import 'seed.dart';

/// Something that happened in the simulated world (petition signed, ID
/// shared...). Activity and notifications of the simulator read it.
final class MockEvent {
  MockEvent({
    required this.id,
    required this.userId,
    required this.kind,
    required this.title,
    required this.body,
    required this.at,
    this.targetKind,
    this.targetId,
  });

  final String id;
  final String userId;

  /// identity | civic | security | service
  final String kind;
  final String title;
  final String body;
  final DateTime at;
  final String? targetKind;
  final String? targetId;
}

/// The simulator engine shared by every simulated repository: latency,
/// scenarios, session (tokens that expire and renew), idempotency and the
/// in-memory world that changes as the user acts.
///
/// Part of the app (demo mode) and of the tests: one single source of
/// fakes.
final class MockServer {
  MockServer({
    required this.session,
    this.latencyMin = const Duration(milliseconds: 300),
    this.latencyMax = const Duration(milliseconds: 800),
    int seed = 42,
    DateTime Function()? clock,
  }) : seed = MockSeed(seed),
       clock = clock ?? DateTime.now {
    _seedAccounts();
  }

  final SessionHolder session;
  Duration latencyMin;
  Duration latencyMax;
  final MockSeed seed;
  final DateTime Function() clock;
  final _random = Random(7);

  /// Access tokens live this long; renewal is silent.
  static const accessTtl = Duration(minutes: 15);

  MockScenario _scenario = MockScenario.normal;
  final _scenarioChanges = StreamController<MockScenario>.broadcast();
  MockScenario get scenario => _scenario;
  Stream<MockScenario> get scenarioChanges => _scenarioChanges.stream;
  set scenario(MockScenario value) {
    _scenario = value;
    _scenarioChanges.add(value);
  }

  final Map<String, MockAccount> accounts = {};
  final Set<String> _revokedRefresh = {};
  final List<MockEvent> events = [];
  final Map<String, Object?> _idempotent = {};
  int _requestCounter = 0;
  int _ids = 0;

  /// Unique id for created records.
  String newId(String prefix) => '${prefix}_${++_ids}';

  // ---------------------------------------------------------------- calls

  /// Runs one simulated request: latency, scenario, session, then [body].
  Future<T> call<T>(
    FutureOr<T> Function(MockAccount? user) body, {
    bool authenticated = true,
    bool write = false,
  }) async {
    final requestId = 'req_${(++_requestCounter).toString().padLeft(5, '0')}';
    await _latency();
    switch (_scenario) {
      case MockScenario.offline:
        throw const NetworkFailure();
      case MockScenario.serverError:
        throw ServerFailure(statusCode: 500, requestId: requestId);
      case MockScenario.rateLimited:
        throw RateLimitFailure(
          retryAfter: const Duration(seconds: 30),
          requestId: requestId,
        );
      case MockScenario.validationRejected when write:
        throw ValidationFailure(
          message: 'Le serveur a refusé cette demande (simulé).',
          requestId: requestId,
        );
      default:
    }
    MockAccount? user;
    if (authenticated) user = await _authenticate();
    return body(user);
  }

  /// Same answer for the same [key]: a write sent twice happens once.
  Future<T> idempotent<T>(String key, Future<T> Function() run) async {
    if (_idempotent.containsKey(key)) return _idempotent[key] as T;
    final value = await run();
    _idempotent[key] = value;
    return value;
  }

  bool get emptyLists => _scenario == MockScenario.empty;

  Future<void> _latency() {
    if (_scenario == MockScenario.slow) {
      return Future.delayed(Duration(milliseconds: 3000 + _random.nextInt(2000)));
    }
    final min = latencyMin.inMilliseconds;
    final span = latencyMax.inMilliseconds - min;
    final ms = min + (span > 0 ? _random.nextInt(span + 1) : 0);
    return ms == 0 ? Future.value() : Future.delayed(Duration(milliseconds: ms));
  }

  /// Like a server behind the client's session interceptor: an expired
  /// access token is renewed once (single-flight in [SessionHolder]).
  Future<MockAccount> _authenticate() async {
    var current = session.current;
    if (current == null) throw const AuthFailure(sessionEnded: true);
    if (_scenario == MockScenario.sessionExpired) {
      // One shot: once signed out, signing in again works.
      scenario = MockScenario.normal;
      _revokedRefresh.add(current.refreshToken);
      expireAccessToken();
      current = session.current!;
    }
    if (!_accessValid(current.accessToken)) {
      current = await session.renew();
    }
    final user = accounts[current.userId];
    if (user == null) throw const AuthFailure(sessionEnded: true);
    return user;
  }

  // -------------------------------------------------------------- session

  /// Tokens describe themselves, so a session saved before a restart is
  /// still recognised by a fresh simulator.
  Session issueSession(String userId) {
    final expires = clock().add(accessTtl);
    return Session(
      userId: userId,
      accessToken: 'mock.at.$userId.${expires.millisecondsSinceEpoch}',
      refreshToken: 'mock.rt.$userId.${clock().microsecondsSinceEpoch}',
      expiresAt: expires,
    );
  }

  /// User of a valid access token, or null (used by the HTTP simulator
  /// in tests to answer 401 like a real server).
  String? userIdForAccess(String token) =>
      _accessValid(token) ? token.split('.')[2] : null;

  bool _accessValid(String token) {
    final parts = token.split('.');
    if (parts.length != 4 || parts[1] != 'at') return false;
    final exp = int.tryParse(parts[3]);
    return exp != null &&
        accounts.containsKey(parts[2]) &&
        clock().millisecondsSinceEpoch < exp;
  }

  /// `POST /auth/refresh` of the simulator.
  Future<Session> renew(Session current) async {
    await _latency();
    if (_scenario == MockScenario.offline) throw const NetworkFailure();
    final parts = current.refreshToken.split('.');
    if (_revokedRefresh.contains(current.refreshToken) ||
        parts.length != 4 ||
        parts[1] != 'rt' ||
        !accounts.containsKey(parts[2])) {
      throw const AuthFailure(sessionEnded: true);
    }
    _revokedRefresh.add(current.refreshToken);
    return issueSession(parts[2]);
  }

  void revoke(String refreshToken) => _revokedRefresh.add(refreshToken);

  /// Scenario panel: the next call will renew the token (silently).
  void expireAccessToken() {
    final s = session.current;
    if (s == null) return;
    final parts = s.accessToken.split('.');
    if (parts.length != 4) return;
    session.set(
      Session(
        userId: s.userId,
        accessToken: 'mock.at.${parts[2]}.0',
        refreshToken: s.refreshToken,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
  }

  // --------------------------------------------------------------- events

  void record(
    String userId, {
    required String kind,
    required String title,
    required String body,
    String? targetKind,
    String? targetId,
  }) => events.insert(
    0,
    MockEvent(
      id: newId('evt'),
      userId: userId,
      kind: kind,
      title: title,
      body: body,
      at: clock(),
      targetKind: targetKind,
      targetId: targetId,
    ),
  );

  void _seedAccounts() {
    accounts['u_alex'] = MockAccount(
      id: 'u_alex',
      email: MockAccounts.demoEmail,
      password: MockAccounts.demoPassword,
      firstName: 'Alex',
      lastName: 'Morgan',
      dateOfBirth: DateTime(1994, 5, 14),
      citizenNumber: '301874624829',
      phone: '+33 6 12 34 56 78',
      address: '18 rue du Port, Riverside',
    );
    accounts['u_sam'] = MockAccount(
      id: 'u_sam',
      email: MockAccounts.secondEmail,
      password: MockAccounts.demoPassword,
      firstName: 'Sam',
      lastName: 'Lee',
      dateOfBirth: DateTime(1988, 11, 2),
      citizenNumber: '402559017733',
      verified: false,
    )..biometricProtection = false;
  }

  void dispose() => _scenarioChanges.close();
}
