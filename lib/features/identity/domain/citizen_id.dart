enum IdStatus { verified, pending, suspended, unknown }

/// The digital citizen ID. The full citizen number never reaches the app:
/// only its last four digits.
final class CitizenId {
  const CitizenId({
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.numberLast4,
    required this.status,
    required this.issuedAt,
    required this.expiresAt,
    required this.email,
    this.phone,
    this.address,
    this.biometricProtection = false,
  });

  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String numberLast4;
  final IdStatus status;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String email;
  final String? phone;
  final String? address;

  /// Showing the ID code requires Face ID / fingerprint.
  final bool biometricProtection;

  String get fullName => '$firstName $lastName'.trim();
  bool get isVerified => status == IdStatus.verified;

  CitizenId copyWith({String? phone, String? address, bool? biometricProtection}) =>
      CitizenId(
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        numberLast4: numberLast4,
        status: status,
        issuedAt: issuedAt,
        expiresAt: expiresAt,
        email: email,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        biometricProtection: biometricProtection ?? this.biometricProtection,
      );
}

/// Short-lived code shown as a QR to prove one's identity in person.
final class PresentationCode {
  const PresentationCode({required this.payload, required this.expiresAt});
  final String payload;
  final DateTime expiresAt;
}

/// What a share link reveals. The citizen chooses.
enum SharedField { fullName, dateOfBirth, verificationStatus, address }

final class ShareLink {
  const ShareLink({
    required this.url,
    required this.code,
    required this.expiresAt,
    required this.fields,
  });

  final String url;

  /// Same link as a short code to read aloud or type.
  final String code;
  final DateTime expiresAt;
  final Set<SharedField> fields;
}

/// Result of checking someone else's code.
final class VerificationResult {
  const VerificationResult({
    required this.valid,
    this.fullName,
    this.status = IdStatus.unknown,
  });

  final bool valid;
  final String? fullName;
  final IdStatus status;
}

abstract final class IdentityFields {
  static const phone = 'phone';
  static const address = 'address';
  static const code = 'code';
}

final class ContactUpdate {
  const ContactUpdate({required this.phone, required this.address});
  final String phone;
  final String address;
}
