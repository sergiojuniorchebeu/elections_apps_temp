import '../../../../core/pagination/page.dart';
import '../../../../mock/mock_server.dart';
import '../../../../mock/pager.dart';
import '../../domain/app_notification.dart';
import '../../domain/notifications_repository.dart';

/// Simulated notifications: a seeded history per account, plus one new
/// notification for every event of the simulated world.
final class MockNotificationsRepository implements NotificationsRepository {
  MockNotificationsRepository(this._server);

  final MockServer _server;
  final Map<String, List<AppNotification>> _byUser = {};
  final Map<String, int> _seenEvents = {};

  List<AppNotification> _items(String userId) {
    final list = _byUser.putIfAbsent(userId, () => _seed(userId));
    final events = _server.events.where((e) => e.userId == userId).toList();
    final seen = _seenEvents[userId] ?? 0;
    // Newest events first: the new ones are at the start.
    for (final e in events.take(events.length - seen).toList().reversed) {
      list.insert(
        0,
        AppNotification(
          id: 'n_${e.id}',
          kind: switch (e.kind) {
            'identity' => NotificationKind.identity,
            'security' => NotificationKind.security,
            'service' => NotificationKind.service,
            _ => e.targetKind == 'petition'
                ? NotificationKind.petition
                : NotificationKind.election,
          },
          title: e.title,
          body: e.body,
          at: e.at,
          read: false,
          targetId: e.targetId,
        ),
      );
    }
    _seenEvents[userId] = events.length;
    return list;
  }

  List<AppNotification> _seed(String userId) {
    final now = _server.clock();
    final s = _server.seed;
    final templates = <(NotificationKind, String, String, String?)>[
      (NotificationKind.election, 'Élections municipales dans 2 semaines',
          'Vérifiez votre bureau de vote et activez un rappel.', 'el_city'),
      (NotificationKind.petition, 'Une pétition que vous avez signée a atteint 8 000 signatures',
          '« Plus de vert. De meilleures villes. » approche de son objectif.', 'pt_green'),
      (NotificationKind.identity, 'Votre identité a servi à vous connecter',
          'Nouvelle connexion sur cet appareil. Ce n’est pas vous ? Déconnectez-vous partout.', null),
      (NotificationKind.service, 'Rendez-vous confirmé',
          'Renouvellement de passeport, mairie, guichet 3.', null),
      (NotificationKind.security, 'La protection biométrique est activée',
          'Votre code d’identité exige désormais Face ID.', null),
      (NotificationKind.petition, 'Nouvelle pétition près de chez vous',
          'Des passages piétons plus sûrs près des écoles de Riverside.', 'pt_crossings'),
      (NotificationKind.election, 'Liste électorale mise à jour',
          'Votre inscription est confirmée pour les prochaines élections.', null),
    ];
    return [
      for (var i = 0; i < 34; i++)
        () {
          final t = templates[i % templates.length];
          return AppNotification(
            id: 'n_${userId}_$i',
            kind: t.$1,
            title: t.$2,
            body: i == 5 ? '${t.$3} ${'Lisez tous les détails dans l’app. ' * 4}' : t.$3,
            at: now.subtract(Duration(hours: i * s.nextInt(5, 30))),
            read: i > 2,
            targetId: t.$4,
          );
        }(),
    ];
  }

  @override
  Future<Page<AppNotification>> list({String? cursor}) => _server.call((user) {
    if (_server.emptyLists) return const Page<AppNotification>.empty();
    return paginate(_items(user!.id), cursor);
  });

  @override
  Future<int> unreadCount() => _server.call((user) {
    if (_server.emptyLists) return 0;
    return _items(user!.id).where((n) => !n.read).length;
  });

  @override
  Future<void> markRead(String id) => _server.call(write: true, (user) {
    final list = _items(user!.id);
    final i = list.indexWhere((n) => n.id == id);
    if (i >= 0) list[i] = list[i].markedRead();
  });

  @override
  Future<void> markAllRead() => _server.call(write: true, (user) {
    final list = _items(user!.id);
    for (var i = 0; i < list.length; i++) {
      list[i] = list[i].markedRead();
    }
  });
}
