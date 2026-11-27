import '../../../core/utils/initials.dart';

/// Everything the home screen shows, in one call (fast first paint and a
/// single offline copy).
final class HomeFeed {
  const HomeFeed({
    required this.firstName,
    required this.lastName,
    required this.idLast4,
    required this.idVerified,
    this.nextElection,
    this.featuredPetition,
  });

  final String firstName;
  final String lastName;
  final String idLast4;
  final bool idVerified;
  final ElectionTeaser? nextElection;
  final PetitionTeaser? featuredPetition;

  String get fullName => '$firstName $lastName'.trim();
  String get initials => initialsOf(firstName, lastName);
}

final class ElectionTeaser {
  const ElectionTeaser({required this.id, required this.title, required this.date});
  final String id;
  final String title;
  final DateTime date;
}

final class PetitionTeaser {
  const PetitionTeaser({
    required this.id,
    required this.title,
    required this.signatures,
    required this.goal,
  });

  final String id;
  final String title;
  final int signatures;
  final int goal;

  double get progress => goal <= 0 ? 0 : (signatures / goal).clamp(0, 1);
}
