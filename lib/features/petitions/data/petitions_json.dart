import '../../../core/network/api_client.dart';
import '../domain/petition.dart';

abstract final class PetitionsJson {
  static Petition item(Map<String, Object?> m) => Petition(
    id: m.str('id'),
    title: m.str('title'),
    summary: m.str('summary'),
    author: m.str('author'),
    signatures: m.integer('signatures'),
    goal: m.integer('goal'),
    status: PetitionStatus.values.firstWhere(
      (v) => v.name == m.strOrNull('status'),
      orElse: () => PetitionStatus.unknown,
    ),
    deadline: m.date('deadline'),
    signedByMe: m.boolean('signed_by_me'),
    category: m.strOrNull('category'),
  );
}
