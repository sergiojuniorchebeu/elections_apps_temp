import '../../../core/network/api_client.dart';
import '../domain/app_notification.dart';

abstract final class NotificationsJson {
  static NotificationKind kind(String? raw) => NotificationKind.values
      .firstWhere((k) => k.name == raw, orElse: () => NotificationKind.unknown);

  static AppNotification item(Map<String, Object?> m) => AppNotification(
    id: m.str('id'),
    kind: kind(m.strOrNull('kind')),
    title: m.str('title'),
    body: m.str('body'),
    at: m.date('created_at'),
    read: m.boolean('read'),
    targetId: m.strOrNull('target_id'),
  );
}
