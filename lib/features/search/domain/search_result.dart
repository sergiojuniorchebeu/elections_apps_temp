enum SearchKind { election, petition, document, service, unknown }

final class SearchResult {
  const SearchResult({
    required this.kind,
    required this.id,
    required this.title,
    this.subtitle,
  });

  final SearchKind kind;
  final String id;
  final String title;
  final String? subtitle;
}

abstract interface class SearchRepository {
  /// At most 30 results, best first. Empty query -> empty list.
  Future<List<SearchResult>> search(String query);
}
