import '../../../../core/network/api_client.dart';
import '../../../../core/network/page_json.dart';
import '../../../../core/pagination/page.dart';
import '../../domain/public_service.dart';
import '../../domain/services_repository.dart';
import '../services_json.dart';

final class RestServicesRepository implements ServicesRepository {
  RestServicesRepository(this._api);
  final ApiClient _api;

  @override
  Future<Page<PublicService>> list({String? cursor}) => _api.get(
    '/services',
    query: {'cursor': cursor, 'limit': defaultPageSize},
    decode: (j) => decodePage(j, ServicesJson.item),
  );

  @override
  Future<PublicService> get(String id) => _api.get(
    '/services/${Uri.encodeComponent(id)}',
    decode: (j) => ServicesJson.item(asMap(j)),
  );

  @override
  Future<ServiceRequest> request(
    String serviceId, {
    required String note,
    required String idempotencyKey,
  }) => _api.post(
    '/services/${Uri.encodeComponent(serviceId)}/requests',
    idempotencyKey: idempotencyKey,
    body: {'note': note},
    decode: (j) => ServicesJson.request(asMap(j)),
  );
}
