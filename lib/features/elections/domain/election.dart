enum ElectionLevel { municipal, regional, national, referendum, unknown }

enum ElectionStatus { upcoming, open, closed, unknown }

final class Candidate {
  const Candidate({required this.name, this.party});
  final String name;
  final String? party;
}

final class Election {
  const Election({
    required this.id,
    required this.title,
    required this.level,
    required this.status,
    required this.date,
    required this.description,
    this.pollingStation,
    this.candidates = const [],
    this.reminderSet = false,
  });

  final String id;
  final String title;
  final ElectionLevel level;
  final ElectionStatus status;
  final DateTime date;
  final String description;

  /// The citizen's polling station, when registered.
  final String? pollingStation;
  final List<Candidate> candidates;
  final bool reminderSet;

  Election withReminder(bool value) => Election(
    id: id,
    title: title,
    level: level,
    status: status,
    date: date,
    description: description,
    pollingStation: pollingStation,
    candidates: candidates,
    reminderSet: value,
  );
}
