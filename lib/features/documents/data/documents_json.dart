import '../../../core/network/api_client.dart';
import '../domain/civic_document.dart';

abstract final class DocumentsJson {
  static DocumentType type(String? raw) => switch (raw) {
    'passport' => DocumentType.passport,
    'driving_licence' => DocumentType.drivingLicence,
    'birth_certificate' => DocumentType.birthCertificate,
    'residence' => DocumentType.residence,
    'tax_notice' => DocumentType.taxNotice,
    _ => DocumentType.unknown,
  };

  static DocumentStatus status(String? raw) => switch (raw) {
    'valid' => DocumentStatus.valid,
    'expiring_soon' => DocumentStatus.expiringSoon,
    'expired' => DocumentStatus.expired,
    'pending' => DocumentStatus.pending,
    _ => DocumentStatus.unknown,
  };

  static CivicDocument item(Map<String, Object?> m) => CivicDocument(
    id: m.str('id'),
    type: type(m.strOrNull('type')),
    title: m.str('title'),
    status: status(m.strOrNull('status')),
    issuer: m.str('issuer'),
    issuedAt: m.date('issued_at'),
    numberLast4: m.strOrNull('number_last4'),
    expiresAt: m.dateOrNull('expires_at'),
  );
}
