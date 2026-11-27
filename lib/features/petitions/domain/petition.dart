enum PetitionStatus { open, closed, successful, unknown }

final class Petition {
  const Petition({
    required this.id,
    required this.title,
    required this.summary,
    required this.author,
    required this.signatures,
    required this.goal,
    required this.status,
    required this.deadline,
    this.signedByMe = false,
    this.category,
  });

  final String id;
  final String title;
  final String summary;
  final String author;
  final int signatures;
  final int goal;
  final PetitionStatus status;
  final DateTime deadline;
  final bool signedByMe;
  final String? category;

  double get progress => goal <= 0 ? 0 : (signatures / goal).clamp(0, 1);
  bool get canSign => status == PetitionStatus.open && !signedByMe;
}
