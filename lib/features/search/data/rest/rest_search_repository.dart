import '../../../../core/network/api_client.dart';
import '../../domain/search_result.dart';

final class RestSearchRepository implements SearchRepository {
  RestSearchRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<SearchResult>> search(String query) async {
    if (query.trim().isEmpty) return const [];
    return _api.get(
      '/search',
      query: {'q': query.trim()},
      decode: (j) => [
        for (final m in asMap(j).list('items'))
          SearchResult(
            kind: SearchKind.values.firstWhere(
              (k) => k.name == m.strOrNull('kind'),
              orElse: () => SearchKind.unknown,
            ),
            id: m.str('id'),
            title: m.str('title'),
            subtitle: m.strOrNull('subtitle'),
          ),
      ],
    );
  }
}
