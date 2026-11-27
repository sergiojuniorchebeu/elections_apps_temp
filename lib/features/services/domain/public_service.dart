enum ServiceCategory { identity, family, housing, transport, tax, other }

final class PublicService {
  const PublicService({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.processingDays,
    required this.online,
  });

  final String id;
  final String title;
  final ServiceCategory category;
  final String description;

  /// Usual processing time.
  final int processingDays;

  /// Can be requested from the app; otherwise in person only.
  final bool online;
}

enum RequestStatus { received, inProgress, done, unknown }

final class ServiceRequest {
  const ServiceRequest({
    required this.reference,
    required this.serviceId,
    required this.createdAt,
    required this.status,
  });

  final String reference;
  final String serviceId;
  final DateTime createdAt;
  final RequestStatus status;
}

abstract final class ServiceFields {
  static const note = 'note';
  static const maxNote = 500;
}
