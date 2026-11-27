enum NotificationKind { election, petition, identity, security, service, unknown }

final class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.at,
    required this.read,
    this.targetId,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime at;
  final bool read;

  /// Id of the election / petition... it is about, if any.
  final String? targetId;

  AppNotification markedRead() => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    at: at,
    read: true,
    targetId: targetId,
  );
}
