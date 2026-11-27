import 'citizen_id.dart';

abstract final class IdentityRules {
  static final _phone = RegExp(r'^\+?[0-9 ()-]{6,20}$');

  static Map<String, String> contact(ContactUpdate u) => {
    if (!_phone.hasMatch(u.phone.trim()))
      IdentityFields.phone: 'Saisissez un numéro de téléphone, ex. +33 6 12 34 56 78.',
    if (u.address.trim().length < 6)
      IdentityFields.address: 'Saisissez votre adresse complète.',
    if (u.address.length > 160)
      IdentityFields.address: 'L’adresse doit faire moins de 160 caractères.',
  };

  static String? code(String code) {
    final c = code.trim();
    if (c.isEmpty) return 'Saisissez le code affiché sur l’autre téléphone.';
    if (!RegExp(r'^[A-Za-z0-9-]{6,40}$').hasMatch(c)) {
      return 'Ce code n’est pas valide. Vérifiez-le et réessayez.';
    }
    return null;
  }
}
