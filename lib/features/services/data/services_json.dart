import '../../../core/network/api_client.dart';
import '../domain/public_service.dart';

abstract final class ServicesJson {
  static PublicService item(Map<String, Object?> m) => PublicService(
    id: m.str('id'),
    title: m.str('title'),
    category: ServiceCategory.values.firstWhere(
      (c) => c.name == m.strOrNull('category'),
      orElse: () => ServiceCategory.other,
    ),
    description: m.str('description'),
    processingDays: m.integer('processing_days'),
    online: m.boolean('online'),
  );

  static ServiceRequest request(Map<String, Object?> m) => ServiceRequest(
    reference: m.str('reference'),
    serviceId: m.str('service_id'),
    createdAt: m.date('created_at'),
    status: switch (m.strOrNull('status')) {
      'received' => RequestStatus.received,
      'in_progress' => RequestStatus.inProgress,
      'done' => RequestStatus.done,
      _ => RequestStatus.unknown,
    },
  );
}
