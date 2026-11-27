import '../../../core/network/api_client.dart';
import '../domain/citizen_id.dart';

/// JSON <-> domain for the Digital ID. Used by the REST implementation and
/// for offline copies (the shape is the REST contract's `CitizenId`).
abstract final class IdentityJson {
  static IdStatus status(String? raw) => switch (raw) {
    'verified' => IdStatus.verified,
    'pending' => IdStatus.pending,
    'suspended' => IdStatus.suspended,
    _ => IdStatus.unknown,
  };

  static CitizenId citizenId(Object? json) {
    final m = asMap(json);
    return CitizenId(
      firstName: m.str('first_name'),
      lastName: m.str('last_name'),
      dateOfBirth: DateTime.parse(m.str('date_of_birth')),
      numberLast4: m.str('number_last4'),
      status: status(m.strOrNull('status')),
      issuedAt: m.date('issued_at'),
      expiresAt: m.date('expires_at'),
      email: m.str('email'),
      phone: m.strOrNull('phone'),
      address: m.strOrNull('address'),
      biometricProtection: m.boolean('biometric_protection'),
    );
  }

  static Map<String, Object?> encode(CitizenId c) => {
    'first_name': c.firstName,
    'last_name': c.lastName,
    'date_of_birth': c.dateOfBirth.toIso8601String().substring(0, 10),
    'number_last4': c.numberLast4,
    'status': c.status.name,
    'issued_at': c.issuedAt.toUtc().toIso8601String(),
    'expires_at': c.expiresAt.toUtc().toIso8601String(),
    'email': c.email,
    'phone': c.phone,
    'address': c.address,
    'biometric_protection': c.biometricProtection,
  };

  static SharedField? field(String raw) => switch (raw) {
    'full_name' => SharedField.fullName,
    'date_of_birth' => SharedField.dateOfBirth,
    'verification_status' => SharedField.verificationStatus,
    'address' => SharedField.address,
    _ => null,
  };

  static String fieldName(SharedField f) => switch (f) {
    SharedField.fullName => 'full_name',
    SharedField.dateOfBirth => 'date_of_birth',
    SharedField.verificationStatus => 'verification_status',
    SharedField.address => 'address',
  };

  static const offlineKey = 'identity.citizen_id';
}
