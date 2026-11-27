import '../../../../core/network/api_client.dart';
import '../../../../core/network/page_json.dart';
import '../../../../core/pagination/page.dart';
import '../../domain/petition.dart';
import '../../domain/petitions_repository.dart';
import '../petitions_json.dart';

final class RestPetitionsRepository implements PetitionsRepository {
  RestPetitionsRepository(this._api);
  final ApiClient _api;

  @override
  Future<Page<Petition>> list({String? cursor}) => _api.get(
    '/petitions',
    query: {'cursor': cursor, 'limit': defaultPageSize},
    decode: (j) => decodePage(j, PetitionsJson.item),
  );

  @override
  Future<Petition> get(String id) => _api.get(
    '/petitions/${Uri.encodeComponent(id)}',
    decode: (j) => PetitionsJson.item(asMap(j)),
  );

  @override
  Future<Petition> sign(String id, {required String idempotencyKey}) =>
      _api.post(
        '/petitions/${Uri.encodeComponent(id)}/signatures',
        idempotencyKey: idempotencyKey,
        body: const {},
        decode: (j) => PetitionsJson.item(asMap(j)),
      );
}
