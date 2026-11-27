import '../../../../core/error/failure.dart';
import '../../../../core/services/social_sign_in.dart';
import '../../../../core/session/session.dart';
import '../../../../mock/mock_accounts.dart';
import '../../../../mock/mock_server.dart';
import '../../domain/auth_repository.dart';
import '../../domain/auth_rules.dart';
import '../../domain/user.dart';

/// Simulated authentication. Demo accounts and magic values: see
/// [MockAccounts].
final class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._server);
  final MockServer _server;

  static User toUser(MockAccount a) => User(
    id: a.id,
    firstName: a.firstName,
    lastName: a.lastName,
    email: a.email,
  );

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) => _server.call(authenticated: false, write: true, (_) {
    final errors = {
      AuthFields.email: ?AuthRules.email(email),
      if (password.isEmpty) AuthFields.password: 'Saisissez votre mot de passe.',
    };
    if (errors.isNotEmpty) throw ValidationFailure(fieldErrors: errors);
    final normalized = email.trim().toLowerCase();
    if (normalized == MockAccounts.lockedEmail) {
      throw const RateLimitFailure(retryAfter: Duration(seconds: 60));
    }
    final known = _accountFor(normalized);
    final universal = password == MockAccounts.universalPassword;
    if (known == null && !universal ||
        known != null && !universal && known.password != password) {
      throw const AuthFailure(reason: AuthFailureReason.invalidCredentials);
    }
    final account = known ?? _create(normalized);
    return AuthResult(
      session: _server.issueSession(account.id),
      user: toUser(account),
    );
  });

  @override
  Future<AuthResult> signInWithProvider(SocialCredential credential) =>
      _server.call(authenticated: false, write: true, (_) {
        // The simulated provider signs its tokens "sim:<provider>:...".
        if (!credential.idToken.startsWith('sim:${credential.provider.name}:')) {
          throw const AuthFailure(reason: AuthFailureReason.invalidCredentials);
        }
        final email = (credential.email ?? MockAccounts.demoEmail).trim().toLowerCase();
        final account =
            _accountFor(email) ??
            _create(email, firstName: credential.firstName, lastName: credential.lastName);
        return AuthResult(
          session: _server.issueSession(account.id),
          user: toUser(account),
        );
      });

  MockAccount? _accountFor(String email) =>
      _server.accounts.values.where((a) => a.email == email).firstOrNull;

  /// Demo: an unknown e-mail signed in with the universal password (or a
  /// provider) gets a verified citizen, named after the e-mail.
  MockAccount _create(String email, {String? firstName, String? lastName}) {
    final parts = email
        .split('@')
        .first
        .split(RegExp(r'[._-]+'))
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
        .toList();
    final id = _server.newId('u');
    final account = MockAccount(
      id: id,
      email: email,
      password: MockAccounts.universalPassword,
      firstName: firstName ?? (parts.isEmpty ? 'Citoyen' : parts.first),
      lastName: lastName ?? (parts.length > 1 ? parts.sublist(1).join(' ') : 'Démo'),
      dateOfBirth: DateTime(1990, 1, 1),
      citizenNumber: '6${_server.seed.nextInt(10000000, 99999999)}${_server.seed.nextInt(100, 999)}',
    );
    _server.accounts[id] = account;
    return account;
  }

  @override
  Future<AuthResult> signUp(SignUpRequest request) =>
      _server.call(authenticated: false, write: true, (_) {
        final errors = AuthRules.signUp(request, _server.clock());
        final email = request.email.trim().toLowerCase();
        if (!errors.containsKey(AuthFields.email) &&
            (email == MockAccounts.takenEmail ||
                _server.accounts.values.any((a) => a.email == email))) {
          errors[AuthFields.email] = 'Cet e-mail est déjà utilisé.';
        }
        if (errors.isNotEmpty) throw ValidationFailure(fieldErrors: errors);
        final id = _server.newId('u');
        final account = MockAccount(
          id: id,
          email: email,
          password: request.password,
          firstName: request.firstName.trim(),
          lastName: request.lastName.trim(),
          dateOfBirth: request.dateOfBirth!,
          citizenNumber: '5${_server.seed.nextInt(10000000, 99999999)}${_server.seed.nextInt(100, 999)}',
          verified: false,
        )..biometricProtection = false;
        _server.accounts[id] = account;
        _server.record(
          id,
          kind: 'identity',
          title: 'Compte créé',
          body: 'La vérification de votre identité est en cours.',
        );
        return AuthResult(
          session: _server.issueSession(id),
          user: toUser(account),
        );
      });

  @override
  Future<void> requestPasswordReset(String email) =>
      _server.call(authenticated: false, write: true, (_) {
        if (AuthRules.email(email) case final e?) {
          throw ValidationFailure(fieldErrors: {AuthFields.email: e});
        }
      });

  @override
  Future<Session> renew(Session current) => _server.renew(current);

  @override
  Future<User> currentUser() => _server.call((user) => toUser(user!));

  @override
  Future<void> signOut() async {
    final s = _server.session.current;
    if (s != null) _server.revoke(s.refreshToken);
  }
}
