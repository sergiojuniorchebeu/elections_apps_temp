import 'auth_repository.dart';

/// Pure validation rules, shared by the forms (instant feedback) and the
/// simulator (which answers like a real server).
abstract final class AuthRules {
  static const minPassword = 8;
  static const minAge = 16;
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? email(String value) {
    if (value.trim().isEmpty) return 'Saisissez votre adresse e-mail.';
    if (!_email.hasMatch(value.trim())) return 'Cette adresse e-mail n’est pas valide.';
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return 'Saisissez un mot de passe.';
    if (value.length < minPassword) {
      return 'Utilisez au moins $minPassword caractères.';
    }
    return null;
  }

  static String? name(String value, String what) =>
      value.trim().isEmpty ? 'Saisissez votre $what.' : null;

  static String? dateOfBirth(DateTime? value, DateTime now) {
    if (value == null) return 'Saisissez votre date de naissance.';
    final age = now.year - value.year -
        ((now.month < value.month ||
                (now.month == value.month && now.day < value.day))
            ? 1
            : 0);
    if (value.isAfter(now)) return 'Cette date est dans le futur.';
    if (age < minAge) return 'Vous devez avoir au moins $minAge ans.';
    return null;
  }

  /// All errors of a sign-up form, keyed by [AuthFields].
  static Map<String, String> signUp(SignUpRequest r, DateTime now) => {
    for (final e in {
      AuthFields.firstName: name(r.firstName, 'prénom'),
      AuthFields.lastName: name(r.lastName, 'nom'),
      AuthFields.email: email(r.email),
      AuthFields.password: password(r.password),
      AuthFields.dateOfBirth: dateOfBirth(r.dateOfBirth, now),
      AuthFields.acceptedTerms: r.acceptedTerms
          ? null
          : 'Acceptez les conditions pour continuer.',
    }.entries)
      if (e.value != null) e.key: e.value!,
  };
}
