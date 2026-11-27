import '../../../../core/error/failure.dart';
import '../../../../core/pagination/page.dart';
import '../../../../mock/mock_server.dart';
import '../../../../mock/pager.dart';
import '../../../../mock/seed.dart';
import '../../domain/petition.dart';
import '../../domain/petitions_repository.dart';

/// Simulated petitions. `pt_green` is the home screen's one (8,420 of
/// 10,000); `pt_closed` is closed (signing -> conflict).
final class MockPetitionsRepository implements PetitionsRepository {
  MockPetitionsRepository(this._server) {
    _seed();
  }

  final MockServer _server;
  final Map<String, _Row> _rows = {};

  void _seed() {
    final now = _server.clock();
    final s = _server.seed;
    void add(String id, String title, String summary, int signatures, int goal,
        {PetitionStatus status = PetitionStatus.open, int days = 40, String? category}) {
      _rows[id] = _Row(
        id: id,
        title: title,
        summary: summary,
        author: s.fullName(),
        signatures: signatures,
        goal: goal,
        status: status,
        deadline: now.add(Duration(days: days)),
        category: category,
      );
    }

    add('pt_green', 'Plus de vert. De meilleures villes.',
        'Planter 5 000 arbres en deux ans et transformer trois parkings en parcs ombragés.',
        8420, 10000, category: 'Environnement');
    add('pt_crossings', 'Des passages piétons plus sûrs près des écoles de Riverside',
        MockSeed.longText, 2310, 5000, category: 'Mobilité');
    add('pt_library', 'Ouvrir la médiathèque centrale le dimanche',
        'Étudiants et familles ont besoin d’un lieu calme pour lire et travailler le week-end.',
        4120, 4000, status: PetitionStatus.successful, days: -3, category: 'Culture');
    add('pt_closed', 'Sauver l’ancienne halle du marché',
        'Protéger la halle des années 1920 et la garder ouverte aux producteurs locaux.',
        1802, 6000, status: PetitionStatus.closed, days: -20, category: 'Patrimoine');
    const topics = [
      'Plus de bus de nuit', 'Une piscine publique à Northgate', 'Des fontaines à eau gratuites',
      'Des pistes cyclables rue du Port', 'Des rues plus calmes après 22 h',
      'Des panneaux solaires sur les écoles', 'De l’éclairage public à Hillcrest',
      'Des jardins partagés', 'Un repair café dans chaque quartier',
    ];
    for (var i = 0; i < 24; i++) {
      final goal = s.pick(const [1000, 2500, 5000, 10000]);
      add('pt_$i', '${topics[i % topics.length]}${i >= topics.length ? ' (${s.city()})' : ''}',
          'Une proposition des habitants de ${s.city()}.',
          s.nextInt(0, goal), goal, days: s.nextInt(3, 90),
          category: s.pick(const ['Mobilité', 'Environnement', 'Culture', 'Sécurité']));
    }
  }

  Petition _view(_Row r, String userId) => Petition(
    id: r.id,
    title: r.title,
    summary: r.summary,
    author: r.author,
    signatures: r.signatures,
    goal: r.goal,
    status: r.status,
    deadline: r.deadline,
    signedByMe: r.signers.contains(userId),
    category: r.category,
  );

  List<_Row> _sorted() {
    final open = _rows.values.where((r) => r.status == PetitionStatus.open).toList()
      ..sort((a, b) => b.signatures.compareTo(a.signatures));
    final others = _rows.values.where((r) => r.status != PetitionStatus.open).toList()
      ..sort((a, b) => b.deadline.compareTo(a.deadline));
    return [...open, ...others];
  }

  /// Used by the simulated home screen.
  Petition featured(String userId) => _view(_rows['pt_green']!, userId);

  List<Petition> all(String userId) => [for (final r in _rows.values) _view(r, userId)];

  @override
  Future<Page<Petition>> list({String? cursor}) => _server.call((user) {
    if (_server.emptyLists) return const Page<Petition>.empty();
    return paginate([for (final r in _sorted()) _view(r, user!.id)], cursor);
  });

  @override
  Future<Petition> get(String id) => _server.call((user) {
    final r = _rows[id];
    if (r == null) throw const NotFoundFailure();
    return _view(r, user!.id);
  });

  @override
  Future<Petition> sign(String id, {required String idempotencyKey}) =>
      _server.call(write: true, (user) => _server.idempotent(idempotencyKey, () async {
        final r = _rows[id];
        if (r == null) throw const NotFoundFailure();
        if (r.status != PetitionStatus.open) {
          throw const ConflictFailure(message: 'Cette pétition est close.');
        }
        if (r.signers.contains(user!.id)) {
          throw const ConflictFailure(message: 'Vous avez déjà signé cette pétition.');
        }
        r.signers.add(user.id);
        r.signatures++;
        if (r.signatures >= r.goal) r.status = PetitionStatus.successful;
        _server.record(
          user.id,
          kind: 'civic',
          title: 'Pétition signée',
          body: r.title,
          targetKind: 'petition',
          targetId: id,
        );
        return _view(r, user.id);
      }));
}

class _Row {
  _Row({
    required this.id,
    required this.title,
    required this.summary,
    required this.author,
    required this.signatures,
    required this.goal,
    required this.status,
    required this.deadline,
    this.category,
  });

  final String id;
  final String title;
  final String summary;
  final String author;
  int signatures;
  final int goal;
  PetitionStatus status;
  final DateTime deadline;
  final String? category;
  final Set<String> signers = {};
}
