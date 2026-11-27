import '../pagination/page.dart';
import 'api_client.dart';

/// REST contract for lists: `{"items": [...], "next_cursor": "..." | null}`.
Page<T> decodePage<T>(Object? json, T Function(Map<String, Object?>) item) {
  final m = asMap(json);
  return Page(
    items: [for (final e in m.list('items')) item(e)],
    nextCursor: m.strOrNull('next_cursor'),
  );
}
