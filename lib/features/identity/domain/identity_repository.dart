import 'citizen_id.dart';

/// Digital ID contract.
abstract interface class IdentityRepository {
  Future<CitizenId> citizenId();

  /// Last known ID (offline copy), or null. Never throws.
  Future<CitizenId?> peek();

  Future<PresentationCode> presentationCode();

  /// Same [idempotencyKey] = same link (the action was replayed).
  Future<ShareLink> share(Set<SharedField> fields, {required String idempotencyKey});

  /// Checks a code shown by someone else. Throws `ValidationFailure`
  /// (field [IdentityFields.code]) for a malformed code.
  Future<VerificationResult> verify(String code);

  Future<CitizenId> updateContact(ContactUpdate update, {required String idempotencyKey});

  Future<CitizenId> setBiometricProtection(bool enabled);
}
