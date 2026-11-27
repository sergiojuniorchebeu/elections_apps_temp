import '../../../core/services/social_sign_in.dart';
import '../../../core/session/session.dart';
import 'user.dart';

/// Result of a successful sign-in or sign-up.
final class AuthResult {
  const AuthResult({required this.session, required this.user});
  final Session session;
  final User user;
}

/// Field names used in [SignUpRequest] validation errors
/// (`ValidationFailure.fieldErrors` keys). Same as the REST contract.
abstract final class AuthFields {
  static const firstName = 'first_name';
  static const lastName = 'last_name';
  static const email = 'email';
  static const password = 'password';
  static const dateOfBirth = 'date_of_birth';
  static const acceptedTerms = 'accepted_terms';
}

final class SignUpRequest {
  const SignUpRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.dateOfBirth,
    required this.acceptedTerms,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final DateTime? dateOfBirth;
  final bool acceptedTerms;
}

/// Authentication contract. Every implementation throws only `Failure`s:
/// wrong credentials = `AuthFailure(reason: invalidCredentials)`, refused
/// renewal = `AuthFailure(sessionEnded: true)`, bad input =
/// `ValidationFailure` keyed by [AuthFields].
abstract interface class AuthRepository {
  Future<AuthResult> signIn({required String email, required String password});

  Future<AuthResult> signUp(SignUpRequest request);

  /// Signs in (or creates the account) from a provider's proof of
  /// identity. An invalid or expired token =
  /// `AuthFailure(reason: invalidCredentials)`.
  Future<AuthResult> signInWithProvider(SocialCredential credential);

  /// Always succeeds for a well-formed email (never tells whether an
  /// account exists).
  Future<void> requestPasswordReset(String email);

  /// New tokens from the refresh token.
  Future<Session> renew(Session current);

  Future<User> currentUser();

  /// Revokes the session on the server. Best effort.
  Future<void> signOut();
}
