import '../../../../core/network/api_client.dart';
import '../../../../core/network/page_json.dart';
import '../../../../core/pagination/page.dart';
import '../../domain/civic_document.dart';
import '../../domain/documents_repository.dart';
import '../documents_json.dart';

final class RestDocumentsRepository implements DocumentsRepository {
  RestDocumentsRepository(this._api);
  final ApiClient _api;

  @override
  Future<Page<CivicDocument>> list({String? cursor}) => _api.get(
    '/documents',
    query: {'cursor': cursor, 'limit': defaultPageSize},
    decode: (j) => decodePage(j, DocumentsJson.item),
  );

  @override
  Future<CivicDocument> get(String id) => _api.get(
    '/documents/${Uri.encodeComponent(id)}',
    decode: (j) => DocumentsJson.item(asMap(j)),
  );
}
