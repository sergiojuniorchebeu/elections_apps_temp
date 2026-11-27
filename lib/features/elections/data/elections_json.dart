import '../../../core/network/api_client.dart';
import '../domain/election.dart';

abstract final class ElectionsJson {
  static Election item(Map<String, Object?> m) => Election(
    id: m.str('id'),
    title: m.str('title'),
    level: ElectionLevel.values.firstWhere(
      (v) => v.name == m.strOrNull('level'),
      orElse: () => ElectionLevel.unknown,
    ),
    status: ElectionStatus.values.firstWhere(
      (v) => v.name == m.strOrNull('status'),
      orElse: () => ElectionStatus.unknown,
    ),
    date: m.date('date'),
    description: m.str('description'),
    pollingStation: m.strOrNull('polling_station'),
    candidates: [
      for (final c in m.list('candidates'))
        Candidate(name: c.str('name'), party: c.strOrNull('party')),
    ],
    reminderSet: m.boolean('reminder_set'),
  );
}
