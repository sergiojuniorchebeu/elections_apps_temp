import '../../../../core/pagination/page.dart';
import '../../../../mock/mock_server.dart';
import '../../../../mock/pager.dart';
import '../../domain/activity_entry.dart';
import '../../domain/activity_repository.dart';

/// Simulated activity: months of seeded history per account, plus every
/// event of the simulated world (petition signed, ID shared...).
final class MockActivityRepository implements ActivityRepository {
  MockActivityRepository(this._server);

  final MockServer _server;
  final Map<String, List<ActivityEntry>> _seeded = {};

  static ActivityKind _kind(String raw) => switch (raw) {
    'identity' => ActivityKind.identity,
    'security' => ActivityKind.security,
    'service' => ActivityKind.service,
    'civic' => ActivityKind.civic,
    _ => ActivityKind.unknown,
  };

  List<ActivityEntry> _seed(String userId) {
    final s = _server.seed;
    final now = _server.clock();
    const templates = <(ActivityKind, String, String, String?)>[
      (ActivityKind.security, 'Connexion', 'Nouvelle connexion sur iPhone', 'iPhone · Riverside'),
      (ActivityKind.identity, 'Identité présentée', 'Votre code a été scanné à La Poste', 'La Poste · Vieille Ville'),
      (ActivityKind.civic, 'Pétition signée', 'Des passages piétons plus sûrs près des écoles', null),
      (ActivityKind.service, 'Demande envoyée', 'Attestation de domicile', 'Mairie'),
      (ActivityKind.identity, 'Identité partagée', 'Partagée avec une agence de location de voitures', null),
      (ActivityKind.civic, 'Rappel activé', 'Élections régionales', null),
      (ActivityKind.security, 'Mot de passe modifié', 'Depuis cet appareil', 'Android · Northgate'),
      (ActivityKind.unknown, 'Mise à jour du compte', 'Une modification a été apportée à votre compte', null),
    ];
    final list = [
      for (var i = 0; i < 57; i++)
        () {
          final t = templates[s.nextInt(0, templates.length - 1)];
          return ActivityEntry(
            id: 'a_${userId}_$i',
            kind: t.$1,
            title: t.$2,
            detail: i == 7 ? 'Attestation de domicile pour l’inscription scolaire de vos deux enfants, avec le justificatif de domicile envoyé le même jour' : t.$3,
            at: now.subtract(Duration(hours: i * 31 + s.nextInt(0, 20))),
            reference: t.$1 == ActivityKind.service ? 'REQ-${s.nextInt(10000, 99999)}' : null,
            place: t.$4,
          );
        }(),
    ];
    return list;
  }

  List<ActivityEntry> _all(String userId) {
    final seeded = _seeded.putIfAbsent(userId, () => _seed(userId));
    final live = [
      for (final e in _server.events.where((e) => e.userId == userId))
        ActivityEntry(
          id: e.id,
          kind: _kind(e.kind),
          title: e.title,
          detail: e.body,
          at: e.at,
        ),
    ];
    return [...live, ...seeded];
  }

  @override
  Future<Page<ActivityEntry>> list({
    String? cursor,
    ActivityFilter filter = ActivityFilter.all,
  }) => _server.call((user) {
    if (_server.emptyLists) return const Page<ActivityEntry>.empty();
    final all = _all(user!.id);
    final filtered = filter == ActivityFilter.all
        ? all
        : all.where((e) => e.kind.name == filter.name).toList();
    return paginate(filtered, cursor);
  });
}
