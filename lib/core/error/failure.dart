/// Every error that leaves a repository is a [Failure], whatever the
/// back-end behind it (simulator, REST, Firebase, ...).
///
/// Screens never see a `DioException`, a `FirebaseException` or a `Map`:
/// they `switch` on these cases or show [title] + [message], which are
/// always plain sentences telling the user what to do.
sealed class Failure implements Exception {
  const Failure({this.requestId});

  /// Identifier of the failed request, shown in "Report a problem".
  final String? requestId;

  String get title;
  String get message;

  /// Doing the same thing again may work.
  bool get retryable => false;

  /// Wraps anything unexpected so the UI only deals with [Failure].
  static Failure from(Object error) =>
      error is Failure ? error : UnknownFailure(cause: error);

  @override
  String toString() => '$runtimeType($title)';
}

final class NetworkFailure extends Failure {
  const NetworkFailure({super.requestId});
  @override
  String get title => 'Pas de connexion';
  @override
  String get message => 'Vérifiez votre connexion Internet, puis réessayez.';
  @override
  bool get retryable => true;
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure({super.requestId});
  @override
  String get title => 'C’est un peu long';
  @override
  String get message => 'Le serveur n’a pas répondu à temps. Réessayez.';
  @override
  bool get retryable => true;
}

/// Not signed in, wrong credentials, or the session ended.
final class AuthFailure extends Failure {
  const AuthFailure({
    this.sessionEnded = false,
    this.reason = AuthFailureReason.unknown,
    super.requestId,
  });

  /// The session can't be renewed: the user must sign in again.
  final bool sessionEnded;
  final AuthFailureReason reason;

  @override
  String get title => sessionEnded
      ? 'Votre session a pris fin'
      : switch (reason) {
          AuthFailureReason.invalidCredentials => 'E-mail ou mot de passe incorrect',
          AuthFailureReason.accountLocked => 'Compte bloqué',
          _ => 'Connexion requise',
        };
  @override
  String get message => sessionEnded
      ? 'Pour votre sécurité, reconnectez-vous.'
      : switch (reason) {
          AuthFailureReason.invalidCredentials =>
            'Vérifiez votre e-mail et votre mot de passe, puis réessayez.',
          AuthFailureReason.accountLocked =>
            'Trop de tentatives. Réinitialisez votre mot de passe ou contactez l’assistance.',
          _ => 'Connectez-vous pour continuer.',
        };
}

enum AuthFailureReason { invalidCredentials, accountLocked, unknown }

/// The server refused the input. [fieldErrors] maps a field name (as in
/// the domain request) to a message shown under that field.
final class ValidationFailure extends Failure {
  const ValidationFailure({
    this.fieldErrors = const {},
    String? message,
    super.requestId,
  }) : _message = message; // ignore: prefer_initializing_formals

  final Map<String, String> fieldErrors;
  final String? _message;

  @override
  String get title => 'Vérifiez le formulaire';
  @override
  String get message =>
      _message ??
      (fieldErrors.isEmpty
          ? 'Certaines informations ne sont pas valides.'
          : fieldErrors.values.first);

  String? errorFor(String field) => fieldErrors[field];
}

final class RateLimitFailure extends Failure {
  const RateLimitFailure({this.retryAfter, super.requestId});
  final Duration? retryAfter;
  @override
  String get title => 'Trop de tentatives';
  @override
  String get message {
    final s = retryAfter?.inSeconds;
    return s == null || s <= 0
        ? 'Patientez un instant, puis réessayez.'
        : 'Patientez $s secondes, puis réessayez.';
  }

  @override
  bool get retryable => true;
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure({super.requestId});
  @override
  String get title => 'Introuvable';
  @override
  String get message => 'Cet élément n’existe pas ou n’est plus disponible.';
}

/// The action clashes with the current state (already signed, closed...).
final class ConflictFailure extends Failure {
  const ConflictFailure({String? message, super.requestId})
    : _message = message; // ignore: prefer_initializing_formals
  final String? _message;
  @override
  String get title => 'Action impossible';
  @override
  String get message =>
      _message ?? 'La situation a changé entre-temps. Actualisez et réessayez.';
}

final class ServerFailure extends Failure {
  const ServerFailure({this.statusCode, super.requestId});
  final int? statusCode;
  @override
  String get title => 'Un problème est survenu';
  @override
  String get message =>
      'Le service rencontre des difficultés. Réessayez dans quelques minutes.';
  @override
  bool get retryable => true;
}

final class CancelledFailure extends Failure {
  const CancelledFailure();
  @override
  String get title => 'Annulé';
  @override
  String get message => 'L’action a été annulée.';
}

final class UnknownFailure extends Failure {
  const UnknownFailure({this.cause, super.requestId});
  final Object? cause;
  @override
  String get title => 'Un problème est survenu';
  @override
  String get message => 'Une erreur inattendue s’est produite. Réessayez.';
  @override
  bool get retryable => true;
}
