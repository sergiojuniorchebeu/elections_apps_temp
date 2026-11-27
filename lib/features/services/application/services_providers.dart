import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/pagination/page.dart';
import '../../../core/state/action_controller.dart';
import '../../../core/state/cache_for.dart';
import '../../../core/state/offline_first.dart';
import '../../../core/state/paginated_notifier.dart';
import '../domain/public_service.dart';
import '../domain/services_repository.dart';

final servicesRepositoryProvider = Provider<ServicesRepository>(
  (_) => throw UnimplementedError('Provided by backend.dart'),
);

final servicesProvider =
    NotifierProvider.autoDispose<ServicesNotifier, PagedState<PublicService>>(
      ServicesNotifier.new,
    );

class ServicesNotifier extends PaginatedNotifier<PublicService> {
  @override
  Future<Page<PublicService>> fetchPage(String? cursor) =>
      ref.read(servicesRepositoryProvider).list(cursor: cursor);
}

final serviceProvider = AsyncNotifierProvider.autoDispose
    .family<ServiceNotifier, PublicService, String>(ServiceNotifier.new);

class ServiceNotifier extends DetailNotifier<PublicService> {
  ServiceNotifier(super.id);

  @override
  Future<PublicService> build() {
    ref.cacheFor(const Duration(minutes: 5));
    return super.build();
  }

  @override
  Future<PublicService> fetch(String id) =>
      ref.read(servicesRepositoryProvider).get(id);
}

final requestControllerProvider = NotifierProvider.autoDispose
    .family<RequestController, ActionState<ServiceRequest>, String>(
      RequestController.new,
    );

class RequestController extends ActionController<ServiceRequest> {
  RequestController(this.serviceId);
  final String serviceId;

  Future<ServiceRequest?> submit(String note) => run(
    (key) => ref
        .read(servicesRepositoryProvider)
        .request(serviceId, note: note.trim(), idempotencyKey: key),
  );
}
