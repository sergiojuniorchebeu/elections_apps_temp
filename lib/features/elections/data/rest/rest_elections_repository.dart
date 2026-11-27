import '../../../../core/network/api_client.dart';
import '../../../../core/network/page_json.dart';
import '../../../../core/pagination/page.dart';
import '../../domain/election.dart';
import '../../domain/elections_repository.dart';
import '../elections_json.dart';

final class RestElectionsRepository implements ElectionsRepository {
  RestElectionsRepository(this._api);
  final ApiClient _api;

  @override
  Future<Page<Election>> list({String? cursor}) => _api.get(
    '/elections',
    query: {'cursor': cursor, 'limit': defaultPageSize},
    decode: (j) => decodePage(j, ElectionsJson.item),
  );

  @override
  Future<Election> get(String id) => _api.get(
    '/elections/${Uri.encodeComponent(id)}',
    decode: (j) => ElectionsJson.item(asMap(j)),
  );

  @override
  Future<Election> setReminder(String id, bool enabled) => _api.post(
    '/elections/${Uri.encodeComponent(id)}/reminder',
    body: {'enabled': enabled},
    decode: (j) => ElectionsJson.item(asMap(j)),
  );
}
