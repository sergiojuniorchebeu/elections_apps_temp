import '../../../../core/error/failure.dart';
import '../../../../core/pagination/page.dart';
import '../../../../mock/mock_server.dart';
import '../../../../mock/pager.dart';
import '../../domain/public_service.dart';
import '../../domain/services_repository.dart';

/// Simulated public services. Magic value: a note containing `reject`
/// is refused by the "server" (field error).
final class MockServicesRepository implements ServicesRepository {
  MockServicesRepository(this._server);
  final MockServer _server;

  static const _services = [
    PublicService(id: 'sv_passport', title: 'Renouveler un passeport', category: ServiceCategory.identity,
        description: 'Prenez rendez-vous pour renouveler votre passeport. Apportez votre passeport actuel et une photo récente.',
        processingDays: 21, online: true),
    PublicService(id: 'sv_residence', title: 'Attestation de domicile', category: ServiceCategory.housing,
        description: 'Justificatif de domicile accepté par les écoles et les banques.',
        processingDays: 2, online: true),
    PublicService(id: 'sv_birth', title: 'Copie d’acte de naissance', category: ServiceCategory.family,
        description: 'Copie intégrale ou extrait, envoyé à votre adresse.', processingDays: 5, online: true),
    PublicService(id: 'sv_parking', title: 'Carte de stationnement résident', category: ServiceCategory.transport,
        description: 'Carte annuelle pour le secteur de votre domicile.', processingDays: 7, online: true),
    PublicService(id: 'sv_tax', title: 'Échéancier de paiement des impôts', category: ServiceCategory.tax,
        description: 'Étalez vos impôts locaux sur dix mensualités.', processingDays: 10, online: true),
    PublicService(id: 'sv_marriage', title: 'Déclarer un mariage', category: ServiceCategory.family,
        description: 'Les deux partenaires viennent en personne à la mairie avec leurs pièces d’identité et deux témoins.',
        processingDays: 30, online: false),
  ];

  @override
  Future<Page<PublicService>> list({String? cursor}) => _server.call((_) {
    if (_server.emptyLists) return const Page<PublicService>.empty();
    return paginate(_services, cursor);
  });

  @override
  Future<PublicService> get(String id) => _server.call((_) {
    final s = _services.where((s) => s.id == id).firstOrNull;
    if (s == null) throw const NotFoundFailure();
    return s;
  });

  List<PublicService> all() => _services;

  @override
  Future<ServiceRequest> request(
    String serviceId, {
    required String note,
    required String idempotencyKey,
  }) => _server.call(write: true, (user) => _server.idempotent(idempotencyKey, () async {
    final s = _services.where((s) => s.id == serviceId).firstOrNull;
    if (s == null) throw const NotFoundFailure();
    if (!s.online) {
      throw const ConflictFailure(message: 'Ce service n’est disponible que sur place.');
    }
    if (note.length > ServiceFields.maxNote) {
      throw const ValidationFailure(fieldErrors: {
        ServiceFields.note: 'Votre note doit faire moins de ${ServiceFields.maxNote} caractères.',
      });
    }
    if (note.toLowerCase().contains('reject')) {
      throw const ValidationFailure(fieldErrors: {
        ServiceFields.note: 'Le service n’a pas pu accepter cette note (simulé).',
      });
    }
    final reference = 'REQ-${_server.seed.nextInt(10000, 99999)}';
    _server.record(
      user!.id,
      kind: 'service',
      title: 'Demande envoyée',
      body: '${s.title} · $reference',
    );
    return ServiceRequest(
      reference: reference,
      serviceId: serviceId,
      createdAt: _server.clock(),
      status: RequestStatus.received,
    );
  }));
}
