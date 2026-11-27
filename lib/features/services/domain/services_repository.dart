import '../../../core/pagination/page.dart';
import 'public_service.dart';

abstract interface class ServicesRepository {
  Future<Page<PublicService>> list({String? cursor});
  Future<PublicService> get(String id);

  /// Starts a request. Throws `ConflictFailure` for an in-person-only
  /// service, `ValidationFailure` on [ServiceFields.note].
  Future<ServiceRequest> request(
    String serviceId, {
    required String note,
    required String idempotencyKey,
  });
}
