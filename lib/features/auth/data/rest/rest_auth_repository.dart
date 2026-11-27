import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/session/session.dart';
import '../../domain/auth_repository.dart';
import '../../domain/user.dart';

/// Reference REST implementation (docs/api_contract.yaml, tag `auth`).
final class RestAuthRepository implements AuthRepository {
  RestAuthRepository(this._api, {required this.deviceId});

  final ApiClient _api;
  final String Function() deviceId;

  static User user(Object? json) {
    final m = asMap(json);
    return User(
      id: m.str('id'),
      firstName: m.str('first_name'),
      lastName: m.str('last_name'),
      email: m.str('email'),
    );
  }

  static Session session(Object? json) {
    final m = asMap(json);
    return Session(
      userId: m.str('user_id'),
      accessToken: m.str('access_token'),
      refreshToken: m.str('refresh_token'),
      expiresAt: DateTime.now().add(Duration(seconds: m.integer('expires_in'))),
    );
  }

  static AuthResult result(Object? json) {
    final m = asMap(json);
    return AuthResult(session: session(m['session']), user: user(m['user']));
  }

  @override
  Future<AuthResult> signIn({required String email, required String password}) =>
      _api.post(
        '/auth/sign-in',
        auth: false,
        body: {'email': email, 'password': password, 'device_id': deviceId()},
        decode: result,
      );

  @override
  Future<AuthResult> signUp(SignUpRequest r) => _api.post(
    '/auth/sign-up',
    auth: false,
    body: {
      'first_name': r.firstName,
      'last_name': r.lastName,
      'email': r.email,
      'password': r.password,
      'date_of_birth': r.dateOfBirth?.toIso8601String().substring(0, 10),
      'accepted_terms': r.acceptedTerms,
      'device_id': deviceId(),
    },
    decode: result,
  );

  @override
  Future<void> requestPasswordReset(String email) => _api.post(
    '/auth/password-reset',
    auth: false,
    body: {'email': email},
    decode: (_) {},
  );

  @override
  Future<Session> renew(Session current) async {
    try {
      return await _api.post(
        '/auth/refresh',
        auth: false,
        body: {'refresh_token': current.refreshToken},
        decode: session,
      );
    } on AuthFailure {
      // Any 401 on refresh means the refresh token is dead.
      throw const AuthFailure(sessionEnded: true);
    } on ValidationFailure {
      throw const AuthFailure(sessionEnded: true);
    }
  }

  @override
  Future<User> currentUser() => _api.get('/me', decode: user);

  @override
  Future<void> signOut() =>
      _api.post('/auth/sign-out', body: const {}, decode: (_) {});
}
