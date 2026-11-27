import '../../../../core/error/failure.dart';
import '../../../../core/pagination/page.dart';
import '../../../../mock/mock_server.dart';
import '../../../../mock/pager.dart';
import '../../domain/election.dart';
import '../../domain/elections_repository.dart';

/// Simulated elections. `el_city` (City Council, in ~2 weeks) is the one
/// of the home screen; `el_old` is closed (reminder -> conflict).
final class MockElectionsRepository implements ElectionsRepository {
  MockElectionsRepository(this._server) {
    _elections = _seed();
  }

  final MockServer _server;
  late final List<Election> _elections;
  final Map<String, Set<String>> _reminders = {};

  List<Election> _seed() {
    final now = _server.clock();
    final s = _server.seed;
    List<Candidate> candidates(int n) => [
      for (var i = 0; i < n; i++)
        Candidate(
          name: s.fullName(),
          party: i == n - 1 ? null : s.pick(const [
            'Avenir Vert', 'Union Citoyenne', 'Priorité aux Habitants', 'Ville Ouverte',
          ]),
        ),
    ];
    Election e(
      String id,
      String title,
      ElectionLevel level,
      int days, {
      String? station,
      int candidatesCount = 4,
      String? description,
    }) => Election(
      id: id,
      title: title,
      level: level,
      status: days < 0 ? ElectionStatus.closed : ElectionStatus.upcoming,
      date: DateTime(now.year, now.month, now.day + days, 8),
      description: description ??
          'Choisissez celles et ceux qui vous représenteront pour le prochain mandat. '
              'Bureaux de vote ouverts de 8 h à 20 h.',
      pollingStation: station,
      candidates: candidates(candidatesCount),
    );
    return [
      e('el_city', 'Conseil municipal', ElectionLevel.municipal, 15,
          station: 'École primaire de Riverside, salle 2'),
      e('el_region', 'Conseil régional', ElectionLevel.regional, 74,
          station: 'Mairie, salle des fêtes'),
      e('el_ref', 'Référendum sur la nouvelle ligne de tram', ElectionLevel.referendum, 120,
          candidatesCount: 0,
          description: 'La ville doit-elle construire une ligne de tram entre la gare '
              'et le campus universitaire ? Répondez par oui ou par non.'),
      e('el_national', 'Élections législatives', ElectionLevel.national, 210),
      for (var i = 0; i < 22; i++)
        e('el_past_$i', '${s.pick(const ['Conseil de district', 'Conseil d’école', 'Conseil de quartier', 'Conseil municipal'])} ${2025 - i ~/ 3}',
            ElectionLevel.municipal, -30 - i * 45),
      e('el_old', 'Élection partielle de la Vieille Ville', ElectionLevel.municipal, -12),
    ];
  }

  Election _forUser(Election e, String userId) =>
      e.withReminder(_reminders[userId]?.contains(e.id) ?? false);

  List<Election> _sorted() {
    final upcoming = _elections.where((e) => e.status != ElectionStatus.closed).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final past = _elections.where((e) => e.status == ElectionStatus.closed).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return [...upcoming, ...past];
  }

  /// Used by the simulated home screen.
  Election? nextUpcoming() => _sorted().where((e) => e.status != ElectionStatus.closed).firstOrNull;

  List<Election> all() => List.unmodifiable(_elections);

  @override
  Future<Page<Election>> list({String? cursor}) => _server.call((user) {
    if (_server.emptyLists) return const Page<Election>.empty();
    return paginate([for (final e in _sorted()) _forUser(e, user!.id)], cursor);
  });

  @override
  Future<Election> get(String id) => _server.call((user) {
    final e = _elections.where((e) => e.id == id).firstOrNull;
    if (e == null) throw const NotFoundFailure();
    return _forUser(e, user!.id);
  });

  @override
  Future<Election> setReminder(String id, bool enabled) =>
      _server.call(write: true, (user) {
        final e = _elections.where((e) => e.id == id).firstOrNull;
        if (e == null) throw const NotFoundFailure();
        if (e.status == ElectionStatus.closed) {
          throw const ConflictFailure(message: 'Cette élection est terminée.');
        }
        final set = _reminders.putIfAbsent(user!.id, () => {});
        enabled ? set.add(id) : set.remove(id);
        if (enabled) {
          _server.record(
            user.id,
            kind: 'civic',
            title: 'Rappel activé',
            body: e.title,
            targetKind: 'election',
            targetId: id,
          );
        }
        return _forUser(e, user.id);
      });
}
