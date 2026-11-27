import '../../../core/network/api_client.dart';
import '../domain/activity_entry.dart';

abstract final class ActivityJson {
  static ActivityEntry item(Map<String, Object?> m) => ActivityEntry(
    id: m.str('id'),
    kind: ActivityKind.values.firstWhere(
      (k) => k.name == m.strOrNull('kind'),
      orElse: () => ActivityKind.unknown,
    ),
    title: m.str('title'),
    detail: m.str('detail'),
    at: m.date('created_at'),
    reference: m.strOrNull('reference'),
    place: m.strOrNull('place'),
  );
}
