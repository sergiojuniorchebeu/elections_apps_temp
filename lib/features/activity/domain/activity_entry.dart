enum ActivityKind { identity, civic, security, service, unknown }

/// Filter of the Activity screen. `all` = no filter.
enum ActivityFilter { all, identity, civic, security, service }

final class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.detail,
    required this.at,
    this.reference,
    this.place,
  });

  final String id;
  final ActivityKind kind;
  final String title;
  final String detail;
  final DateTime at;

  /// Reference to give to support (request number...).
  final String? reference;

  /// Where it happened (device, office...), when known.
  final String? place;
}
