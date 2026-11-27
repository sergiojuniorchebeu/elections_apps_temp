import '../../../../core/error/failure.dart';
import '../../../../core/storage/offline_store.dart';
import '../../../../mock/mock_accounts.dart';
import '../../../../mock/mock_server.dart';
import '../../domain/citizen_id.dart';
import '../../domain/identity_repository.dart';
import '../../domain/identity_rules.dart';
import '../identity_json.dart';

/// Simulated Digital ID.
///
/// Magic values: verification code `000000` -> "not valid"; any other
/// well-formed code -> a verified person. Contact phone `+000000` ->
/// refused by the "server".
final class MockIdentityRepository implements IdentityRepository {
  MockIdentityRepository(this._server, this._offline);

  final MockServer _server;
  final OfflineStore _offline;

  static const invalidCode = '000000';
  static const refusedPhone = '+000000';

  CitizenId _of(MockAccount a) => CitizenId(
    firstName: a.firstName,
    lastName: a.lastName,
    dateOfBirth: a.dateOfBirth,
    numberLast4: a.citizenNumber.substring(a.citizenNumber.length - 4),
    status: a.verified ? IdStatus.verified : IdStatus.pending,
    issuedAt: DateTime(2023, 3, 2),
    expiresAt: DateTime(2033, 3, 1),
    email: a.email,
    phone: a.phone,
    address: a.address,
    biometricProtection: a.biometricProtection,
  );

  Future<CitizenId> _save(CitizenId id) async {
    await _offline.write(IdentityJson.offlineKey, IdentityJson.encode(id));
    return id;
  }

  @override
  Future<CitizenId> citizenId() =>
      _server.call((user) => _save(_of(user!)));

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
  Future<PresentationCode> presentationCode() => _server.call((user) {
    final now = _server.clock();
    return PresentationCode(
      payload: 'civic:id:${user!.id}:${now.millisecondsSinceEpoch}',
      expiresAt: now.add(const Duration(minutes: 2)),
    );
  });

  @override
  Future<ShareLink> share(
    Set<SharedField> fields, {
    required String idempotencyKey,
  }) => _server.call(write: true, (user) {
    if (fields.isEmpty) {
      throw const ValidationFailure(message: 'Choisissez au moins une information à partager.');
    }
    return _server.idempotent(idempotencyKey, () async {
      final code = 'SHR-${_server.seed.nextInt(100000, 999999)}';
      _server.record(
        user!.id,
        kind: 'identity',
        title: 'ID shared',
        body: 'A share link was created ($code), valid 24 h.',
      );
      return ShareLink(
        url: 'https://id.example.org/s/$code',
        code: code,
        expiresAt: _server.clock().add(const Duration(hours: 24)),
        fields: fields,
      );
    });
  });

  @override
  Future<VerificationResult> verify(String code) => _server.call((user) {
    if (IdentityRules.code(code) case final error?) {
      throw ValidationFailure(fieldErrors: {IdentityFields.code: error});
    }
    _server.record(
      user!.id,
      kind: 'identity',
      title: 'ID checked',
      body: 'Vous avez vérifié un code d’identité.',
    );
    if (code.trim() == invalidCode) {
      return const VerificationResult(valid: false);
    }
    return VerificationResult(
      valid: true,
      fullName: _server.seed.fullName(),
      status: IdStatus.verified,
    );
  });

  @override
  Future<CitizenId> updateContact(
    ContactUpdate update, {
    required String idempotencyKey,
  }) => _server.call(write: true, (user) {
    final errors = IdentityRules.contact(update);
    if (update.phone.replaceAll(' ', '') == refusedPhone) {
      errors[IdentityFields.phone] = 'Ce numéro ne peut pas recevoir de messages.';
    }
    if (errors.isNotEmpty) throw ValidationFailure(fieldErrors: errors);
    return _server.idempotent(idempotencyKey, () async {
      user!
        ..phone = update.phone.trim()
        ..address = update.address.trim();
      _server.record(
        user.id,
        kind: 'identity',
        title: 'Coordonnées mises à jour',
        body: 'Votre numéro de téléphone et votre adresse ont été modifiés.',
      );
      return _save(_of(user));
    });
  });

  @override
  Future<CitizenId> setBiometricProtection(bool enabled) =>
      _server.call(write: true, (user) {
        user!.biometricProtection = enabled;
        _server.record(
          user.id,
          kind: 'security',
          title: enabled ? 'Protection biométrique activée' : 'Protection biométrique désactivée',
          body: enabled
              ? 'Votre code d’identité exige désormais la biométrie.'
              : 'Votre code d’identité n’exige plus la biométrie.',
        );
        return _save(_of(user));
      });
}
