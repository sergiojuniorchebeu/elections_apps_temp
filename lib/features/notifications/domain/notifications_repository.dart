import '../../../core/pagination/page.dart';
import 'app_notification.dart';

abstract interface class NotificationsRepository {
  /// Newest first.
  Future<Page<AppNotification>> list({String? cursor});

  Future<int> unreadCount();

  Future<void> markRead(String id);

  Future<void> markAllRead();
}
