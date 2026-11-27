import '../../../../core/network/api_client.dart';
import '../../../../core/storage/offline_store.dart';
import '../../domain/citizen_id.dart';
import '../../domain/identity_repository.dart';
import '../identity_json.dart';

/// Reference REST implementation (tag `identity`).
final class RestIdentityRepository implements IdentityRepository {
  RestIdentityRepository(this._api, this._offline);

  final ApiClient _api;
  final OfflineStore _offline;

  @override
  Future<CitizenId> citizenId() => _api.get(
    '/me/citizen-id',
    offlineKey: IdentityJson.offlineKey,
    decode: IdentityJson.citizenId,
  );

  @override
  Future<CitizenId?> peek() async {
    try {
      final copy = await _offline.read(IdentityJson.offlineKey);
      return copy == null ? null : IdentityJson.citizenId(copy.data);
    } on Object {
      return null;
    }
  }

  @override
  Future<PresentationCode> presentationCode() => _api.post(
    '/me/citizen-id/presentation-codes',
    body: const {},
    decode: (json) {
      final m = asMap(json);
      return PresentationCode(
        payload: m.str('payload'),
        expiresAt: m.date('expires_at'),
      );
    },
  );

  @override
  Future<ShareLink> share(
    Set<SharedField> fields, {
    required String idempotencyKey,
  }) => _api.post(
    '/me/citizen-id/shares',
    idempotencyKey: idempotencyKey,
    body: {'fields': fields.map(IdentityJson.fieldName).toList()},
    decode: (json) {
      final m = asMap(json);
      return ShareLink(
        url: m.str('url'),
        code: m.str('code'),
        expiresAt: m.date('expires_at'),
        fields: {
          for (final f in (m['fields'] as List? ?? const []))
            ?IdentityJson.field('$f'),
        },
      );
    },
  );

  @override
  Future<VerificationResult> verify(String code) => _api.post(
    '/verifications',
    body: {'code': code.trim()},
    decode: (json) {
      final m = asMap(json);
      return VerificationResult(
        valid: m.boolean('valid'),
        fullName: m.strOrNull('full_name'),
        status: IdentityJson.status(m.strOrNull('status')),
      );
    },
  );

  @override
  Future<CitizenId> updateContact(
    ContactUpdate update, {
    required String idempotencyKey,
  }) => _api.patch(
    '/me/citizen-id/contact',
    idempotencyKey: idempotencyKey,
    body: {'phone': update.phone.trim(), 'address': update.address.trim()},
    decode: IdentityJson.citizenId,
  );

  @override
  Future<CitizenId> setBiometricProtection(bool enabled) => _api.patch(
    '/me/citizen-id/settings',
    body: {'biometric_protection': enabled},
    decode: IdentityJson.citizenId,
  );
}
