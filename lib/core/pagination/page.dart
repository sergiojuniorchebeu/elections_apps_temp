/// One page of a cursor-paginated list. Pure Dart: used by domain
/// interfaces of every feature.
final class Page<T> {
  const Page({required this.items, this.nextCursor});

  const Page.empty() : items = const [], nextCursor = null;

  final List<T> items;

  /// Opaque cursor for the next page; `null` when this is the last one.
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}

/// Page size the screens ask for. Implementations may return fewer.
const defaultPageSize = 20;
