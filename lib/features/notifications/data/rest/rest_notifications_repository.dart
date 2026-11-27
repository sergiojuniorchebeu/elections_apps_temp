import '../../../../core/network/api_client.dart';
import '../../../../core/network/page_json.dart';
import '../../../../core/pagination/page.dart';
import '../../domain/app_notification.dart';
import '../../domain/notifications_repository.dart';
import '../notifications_json.dart';

final class RestNotificationsRepository implements NotificationsRepository {
  RestNotificationsRepository(this._api);
  final ApiClient _api;

  @override
  Future<Page<AppNotification>> list({String? cursor}) => _api.get(
    '/notifications',
    query: {'cursor': cursor, 'limit': defaultPageSize},
    decode: (j) => decodePage(j, NotificationsJson.item),
  );

  @override
  Future<int> unreadCount() => _api.get(
    '/notifications/unread-count',
    decode: (j) => asMap(j).integer('count'),
  );

  @override
  Future<void> markRead(String id) => _api.post(
    '/notifications/${Uri.encodeComponent(id)}/read',
    body: const {},
    decode: (_) {},
  );

  @override
  Future<void> markAllRead() =>
      _api.post('/notifications/read-all', body: const {}, decode: (_) {});
}
