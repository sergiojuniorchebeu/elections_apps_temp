enum DocumentType { passport, drivingLicence, birthCertificate, residence, taxNotice, unknown }

enum DocumentStatus { valid, expiringSoon, expired, pending, unknown }

final class CivicDocument {
  const CivicDocument({
    required this.id,
    required this.type,
    required this.title,
    required this.status,
    required this.issuer,
    required this.issuedAt,
    this.numberLast4,
    this.expiresAt,
  });

  final String id;
  final DocumentType type;
  final String title;
  final DocumentStatus status;
  final String issuer;
  final DateTime issuedAt;
  final String? numberLast4;

  /// Null for documents that never expire.
  final DateTime? expiresAt;
}
