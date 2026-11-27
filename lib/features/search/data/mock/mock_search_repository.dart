import '../../../../mock/mock_server.dart';
import '../../domain/search_result.dart';

/// Simulated search over the other simulated features (sources wired in
/// `backend.dart`).
final class MockSearchRepository implements SearchRepository {
  MockSearchRepository(this._server, this.sources);

  final MockServer _server;
  final List<List<SearchResult> Function(String userId)> sources;

  @override
  Future<List<SearchResult>> search(String query) => _server.call((user) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty || _server.emptyLists) return const <SearchResult>[];
    final all = [for (final s in sources) ...s(user!.id)];
    final starts = all.where((r) => r.title.toLowerCase().startsWith(q));
    final contains = all.where(
      (r) =>
          !r.title.toLowerCase().startsWith(q) &&
          ('${r.title} ${r.subtitle ?? ''}').toLowerCase().contains(q),
    );
    return [...starts, ...contains].take(30).toList();
  });
}
