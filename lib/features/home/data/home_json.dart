import '../../../core/network/api_client.dart';
import '../domain/home_feed.dart';

/// JSON <-> domain for the home feed (REST contract `HomeFeed`), also
/// used for the offline copy.
abstract final class HomeJson {
  static const offlineKey = 'home.feed';

  static HomeFeed feed(Object? json) {
    final m = asMap(json);
    final e = m['next_election'] == null ? null : asMap(m['next_election']);
    final p = m['featured_petition'] == null ? null : asMap(m['featured_petition']);
    return HomeFeed(
      firstName: m.str('first_name'),
      lastName: m.str('last_name'),
      idLast4: m.str('id_last4'),
      idVerified: m.boolean('id_verified'),
      nextElection: e == null
          ? null
          : ElectionTeaser(id: e.str('id'), title: e.str('title'), date: e.date('date')),
      featuredPetition: p == null
          ? null
          : PetitionTeaser(
              id: p.str('id'),
              title: p.str('title'),
              signatures: p.integer('signatures'),
              goal: p.integer('goal'),
            ),
    );
  }

  static Map<String, Object?> encode(HomeFeed f) => {
    'first_name': f.firstName,
    'last_name': f.lastName,
    'id_last4': f.idLast4,
    'id_verified': f.idVerified,
    'next_election': f.nextElection == null
        ? null
        : {
            'id': f.nextElection!.id,
            'title': f.nextElection!.title,
            'date': f.nextElection!.date.toUtc().toIso8601String(),
          },
    'featured_petition': f.featuredPetition == null
        ? null
        : {
            'id': f.featuredPetition!.id,
            'title': f.featuredPetition!.title,
            'signatures': f.featuredPetition!.signatures,
            'goal': f.featuredPetition!.goal,
          },
  };
}
