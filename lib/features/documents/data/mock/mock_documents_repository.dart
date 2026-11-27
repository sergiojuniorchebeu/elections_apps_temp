import '../../../../core/error/failure.dart';
import '../../../../core/pagination/page.dart';
import '../../../../mock/mock_server.dart';
import '../../../../mock/pager.dart';
import '../../domain/civic_document.dart';
import '../../domain/documents_repository.dart';

/// Simulated documents: every status is represented (valid, expiring
/// soon, expired, pending, unknown type).
final class MockDocumentsRepository implements DocumentsRepository {
  MockDocumentsRepository(this._server);
  final MockServer _server;

  List<CivicDocument> _of(String userId) {
    final now = _server.clock();
    DateTime d(int days) => now.add(Duration(days: days));
    return [
      CivicDocument(id: 'doc_passport', type: DocumentType.passport, title: 'Passeport',
          status: DocumentStatus.valid, issuer: 'Ministère de l’Intérieur',
          issuedAt: d(-900), expiresAt: d(2750), numberLast4: '7731'),
      CivicDocument(id: 'doc_licence', type: DocumentType.drivingLicence, title: 'Permis de conduire',
          status: DocumentStatus.expiringSoon, issuer: 'Agence des transports',
          issuedAt: d(-3600), expiresAt: d(40), numberLast4: '0912'),
      CivicDocument(id: 'doc_birth', type: DocumentType.birthCertificate, title: 'Acte de naissance',
          status: DocumentStatus.valid, issuer: 'État civil de Riverside', issuedAt: d(-11500)),
      CivicDocument(id: 'doc_residence', type: DocumentType.residence, title: 'Attestation de domicile',
          status: DocumentStatus.pending, issuer: 'Mairie', issuedAt: d(-2)),
      CivicDocument(id: 'doc_tax', type: DocumentType.taxNotice, title: 'Avis d’imposition 2025',
          status: DocumentStatus.valid, issuer: 'Tax Office', issuedAt: d(-120)),
      CivicDocument(id: 'doc_old_id', type: DocumentType.passport, title: 'Ancien passeport',
          status: DocumentStatus.expired, issuer: 'Ministère de l’Intérieur',
          issuedAt: d(-4600), expiresAt: d(-950), numberLast4: '2208'),
      CivicDocument(id: 'doc_misc', type: DocumentType.unknown,
          title: 'Attestation de participation à la concertation de quartier sur la rénovation urbaine',
          status: DocumentStatus.unknown, issuer: 'Old Town District', issuedAt: d(-60)),
    ];
  }

  @override
  Future<Page<CivicDocument>> list({String? cursor}) => _server.call((user) {
    if (_server.emptyLists) return const Page<CivicDocument>.empty();
    return paginate(_of(user!.id), cursor);
  });

  @override
  Future<CivicDocument> get(String id) => _server.call((user) {
    final doc = _of(user!.id).where((d) => d.id == id).firstOrNull;
    if (doc == null) throw const NotFoundFailure();
    return doc;
  });
}
