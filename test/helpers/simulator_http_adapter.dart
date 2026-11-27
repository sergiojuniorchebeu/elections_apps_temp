import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:elections_app/core/error/failure.dart';
import 'package:elections_app/core/pagination/page.dart';
import 'package:elections_app/core/session/session.dart';
import 'package:elections_app/core/session/session_holder.dart';
import 'package:elections_app/features/auth/data/mock/mock_auth_repository.dart';
import 'package:elections_app/features/auth/domain/auth_repository.dart';
import 'package:elections_app/features/notifications/data/mock/mock_notifications_repository.dart';
import 'package:elections_app/features/notifications/domain/app_notification.dart';
import 'package:elections_app/features/petitions/data/mock/mock_petitions_repository.dart';
import 'package:elections_app/features/petitions/domain/petition.dart';
import 'package:elections_app/mock/mock_server.dart';

/// A server speaking the REST contract (docs/api_contract.yaml), backed by
/// the simulator. Lets the REST implementation run the same contract
/// suite as the simulated one, with real HTTP status codes and JSON.
final class SimulatorHttpAdapter implements HttpClientAdapter {
  SimulatorHttpAdapter(this.server, this.serverSession)
    : auth = MockAuthRepository(server),
      petitions = MockPetitionsRepository(server),
      notifications = MockNotificationsRepository(server);

  final MockServer server;

  /// The server's view of "who is calling", set from the bearer token.
  final SessionHolder serverSession;
  final MockAuthRepository auth;
  final MockPetitionsRepository petitions;
  final MockNotificationsRepository notifications;
  int requests = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    final body = options.data is Map ? (options.data as Map).cast<String, Object?>() : const <String, Object?>{};
    final path = options.uri.path.replaceFirst('/v1', '');
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    try {
      // Anonymous routes.
      switch ((options.method, path)) {
        case ('GET', '/health'):
          return _json(200, {'status': 'ok'});
        case ('POST', '/auth/sign-in'):
          final r = await auth.signIn(email: '${body['email']}', password: '${body['password']}');
          return _json(200, _result(r));
        case ('POST', '/auth/refresh'):
          final s = await server.renew(Session(
            userId: '',
            accessToken: '',
            refreshToken: '${body['refresh_token']}',
            expiresAt: DateTime(2000),
          ));
          return _json(200, _session(s));
      }
      // Authenticated routes: 401 like a real server.
      final header = options.headers['Authorization'] as String?;
      final token = header?.replaceFirst('Bearer ', '');
      final userId = token == null ? null : server.userIdForAccess(token);
      if (userId == null) {
        return _json(401, {'error': {'code': 'unauthenticated', 'message': 'Sign in.'}});
      }
      await serverSession.set(server.issueSession(userId));
      final key = options.headers['Idempotency-Key'] as String?;
      return switch ((options.method, segments)) {
        ('GET', ['me']) => _json(200, _user(await auth.currentUser())),
        ('GET', ['petitions']) => _json(200, _page(
          await petitions.list(cursor: options.uri.queryParameters['cursor']),
          _petition,
        )),
        ('GET', ['petitions', final id]) => _json(200, _petition(await petitions.get(id))),
        ('POST', ['petitions', final id, 'signatures']) =>
          _json(201, _petition(await petitions.sign(id, idempotencyKey: key ?? 'missing'))),
        ('GET', ['notifications']) => _json(200, _page(
          await notifications.list(cursor: options.uri.queryParameters['cursor']),
          _notification,
        )),
        ('GET', ['notifications', 'unread-count']) =>
          _json(200, {'count': await notifications.unreadCount()}),
        ('POST', ['notifications', 'read-all']) => await notifications.markAllRead().then((_) => _json(204, null)),
        ('POST', ['notifications', final id, 'read']) =>
          await notifications.markRead(id).then((_) => _json(204, null)),
        _ => _json(404, {'error': {'code': 'not_found', 'message': 'No route.'}}),
      };
    } on Failure catch (f) {
      return _failure(f);
    }
  }

  ResponseBody _failure(Failure f) => switch (f) {
    ValidationFailure(:final fieldErrors) => _json(422, {
      'error': {'code': 'validation_failed', 'message': f.message, 'fields': fieldErrors},
    }),
    AuthFailure(:final sessionEnded, :final reason) => _json(401, {
      'error': {
        'code': sessionEnded
            ? 'session_ended'
            : reason == AuthFailureReason.invalidCredentials
            ? 'invalid_credentials'
            : 'unauthenticated',
        'message': f.message,
      },
    }),
    NotFoundFailure() => _json(404, {'error': {'code': 'not_found', 'message': f.message}}),
    ConflictFailure() => _json(409, {'error': {'code': 'conflict', 'message': f.message}}),
    RateLimitFailure(:final retryAfter) => _json(
      429,
      {'error': {'code': 'rate_limited', 'message': f.message}},
      headers: {'retry-after': ['${retryAfter?.inSeconds ?? 30}']},
    ),
    NetworkFailure() => throw DioException.connectionError(
      requestOptions: RequestOptions(),
      reason: 'simulated',
    ),
    _ => _json(500, {'error': {'code': 'server_error', 'message': 'Boom.'}}),
  };

  static ResponseBody _json(int status, Object? body, {Map<String, List<String>>? headers}) =>
      ResponseBody.fromString(
        body == null ? '' : jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
          'x-request-id': ['req_test'],
          ...?headers,
        },
      );

  static Map<String, Object?> _page<T>(Page<T> p, Map<String, Object?> Function(T) item) => {
    'items': [for (final i in p.items) item(i)],
    'next_cursor': p.nextCursor,
  };

  static Map<String, Object?> _session(Session s) => {
    'user_id': s.userId,
    'access_token': s.accessToken,
    'refresh_token': s.refreshToken,
    'expires_in': s.expiresAt.difference(DateTime.now()).inSeconds,
  };

  static Map<String, Object?> _result(AuthResult r) => {
    'session': _session(r.session),
    'user': {'id': r.user.id, 'first_name': r.user.firstName, 'last_name': r.user.lastName, 'email': r.user.email},
  };

  static Map<String, Object?> _user(dynamic u) =>
      {'id': u.id, 'first_name': u.firstName, 'last_name': u.lastName, 'email': u.email};

  static Map<String, Object?> _petition(Petition p) => {
    'id': p.id,
    'title': p.title,
    'summary': p.summary,
    'author': p.author,
    'signatures': p.signatures,
    'goal': p.goal,
    'status': p.status.name,
    'deadline': p.deadline.toUtc().toIso8601String(),
    'signed_by_me': p.signedByMe,
    'category': p.category,
  };

  static Map<String, Object?> _notification(AppNotification n) => {
    'id': n.id,
    'kind': n.kind.name,
    'title': n.title,
    'body': n.body,
    'created_at': n.at.toUtc().toIso8601String(),
    'read': n.read,
    'target_id': n.targetId,
  };
}
