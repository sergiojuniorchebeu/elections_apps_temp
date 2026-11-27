import '../../../core/utils/initials.dart';

/// The signed-in person, as the app needs it.
final class User {
  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;

  String get fullName => '$firstName $lastName'.trim();
  String get initials => initialsOf(firstName, lastName);
}
