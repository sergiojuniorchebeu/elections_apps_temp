/// THE plug point: which implementation answers each repository.
///
/// Screens and controllers only know the interfaces (`domain/`) and the
/// providers declared in each feature's `application/`. This file maps
/// them to an implementation, according to `--dart-define=BACKEND=...`.
///
/// To add your back-end (see docs/BACKEND.md):
/// 1. implement the repository interfaces (`features/*/domain/*_repository.dart`);
/// 2. add a value to [BackendKind] and a `case` below;
/// 3. run the contract tests (`test/contract/`).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import 'core/config/app_config.dart';
import 'core/config/demo_info.dart';
import 'core/core_providers.dart';
import 'core/network/api_client.dart';
import 'core/network/reachability.dart';
import 'features/activity/application/activity_providers.dart';
import 'features/activity/data/mock/mock_activity_repository.dart';
import 'features/activity/data/rest/rest_activity_repository.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/auth/data/mock/mock_auth_repository.dart';
import 'features/auth/data/rest/rest_auth_repository.dart';
import 'features/documents/application/documents_providers.dart';
import 'features/documents/data/mock/mock_documents_repository.dart';
import 'features/documents/data/rest/rest_documents_repository.dart';
import 'features/elections/application/elections_providers.dart';
import 'features/elections/data/mock/mock_elections_repository.dart';
import 'features/elections/data/rest/rest_elections_repository.dart';
import 'features/home/application/home_providers.dart';
import 'features/home/data/mock/mock_home_repository.dart';
import 'features/home/data/rest/rest_home_repository.dart';
import 'features/home/domain/home_feed.dart';
import 'features/identity/application/identity_providers.dart';
import 'features/identity/data/mock/mock_identity_repository.dart';
import 'features/identity/data/rest/rest_identity_repository.dart';
import 'features/notifications/application/notifications_providers.dart';
import 'features/notifications/data/mock/mock_notifications_repository.dart';
import 'features/notifications/data/rest/rest_notifications_repository.dart';
import 'features/petitions/application/petitions_providers.dart';
import 'features/petitions/data/mock/mock_petitions_repository.dart';
import 'features/petitions/data/rest/rest_petitions_repository.dart';
import 'features/search/application/search_providers.dart';
import 'features/search/data/mock/mock_search_repository.dart';
import 'features/search/data/rest/rest_search_repository.dart';
import 'features/search/domain/search_result.dart';
import 'features/services/application/services_providers.dart';
import 'features/services/data/mock/mock_services_repository.dart';
import 'features/services/data/rest/rest_services_repository.dart';
import 'l10n/strings.dart';
import 'mock/mock_accounts.dart';
import 'mock/mock_providers.dart';

List<Override> backendOverrides(AppConfig config) => switch (config.backend) {
  BackendKind.mock => mockOverrides(),
  BackendKind.rest => restOverrides(config),
};

/// Lets the session holder renew tokens through whichever [AuthRepository]
/// is plugged. Call once the container exists.
void connectSession(ProviderContainer container) {
  container.read(sessionHolderProvider).renewer = (s) =>
      container.read(authRepositoryProvider).renew(s);
}

// ------------------------------------------------------------- simulator

final _mockElections = Provider(
  (ref) => MockElectionsRepository(ref.watch(mockServerProvider)),
);
final _mockPetitions = Provider(
  (ref) => MockPetitionsRepository(ref.watch(mockServerProvider)),
);
final _mockServices = Provider(
  (ref) => MockServicesRepository(ref.watch(mockServerProvider)),
);
final _mockDocuments = Provider(
  (ref) => MockDocumentsRepository(ref.watch(mockServerProvider)),
);

List<Override> mockOverrides() => [
  demoInfoProvider.overrideWithValue(
    const DemoInfo(
      accounts: [MockAccounts.demoEmail, MockAccounts.secondEmail],
      password: MockAccounts.demoPassword,
      hints: [
        'Tout autre mot de passe → refusé',
        '${MockAccounts.lockedEmail} → trop de tentatives',
        'Inscription avec ${MockAccounts.takenEmail} → e-mail déjà utilisé',
      ],
    ),
  ),
  reachabilityProvider.overrideWith(
    (ref) => MockReachability(ref.watch(mockServerProvider)),
  ),
  authRepositoryProvider.overrideWith(
    (ref) => MockAuthRepository(ref.watch(mockServerProvider)),
  ),
  identityRepositoryProvider.overrideWith(
    (ref) => MockIdentityRepository(
      ref.watch(mockServerProvider),
      ref.watch(offlineStoreProvider),
    ),
  ),
  homeRepositoryProvider.overrideWith((ref) {
    final elections = ref.watch(_mockElections);
    final petitions = ref.watch(_mockPetitions);
    return MockHomeRepository(
      ref.watch(mockServerProvider),
      ref.watch(offlineStoreProvider),
      nextElection: () {
        final e = elections.nextUpcoming();
        return e == null
            ? null
            : ElectionTeaser(id: e.id, title: e.title, date: e.date);
      },
      featuredPetition: (userId) {
        final p = petitions.featured(userId);
        return PetitionTeaser(
          id: p.id,
          title: p.title,
          signatures: p.signatures,
          goal: p.goal,
        );
      },
    );
  }),
  notificationsRepositoryProvider.overrideWith(
    (ref) => MockNotificationsRepository(ref.watch(mockServerProvider)),
  ),
  activityRepositoryProvider.overrideWith(
    (ref) => MockActivityRepository(ref.watch(mockServerProvider)),
  ),
  electionsRepositoryProvider.overrideWith((ref) => ref.watch(_mockElections)),
  petitionsRepositoryProvider.overrideWith((ref) => ref.watch(_mockPetitions)),
  documentsRepositoryProvider.overrideWith((ref) => ref.watch(_mockDocuments)),
  servicesRepositoryProvider.overrideWith((ref) => ref.watch(_mockServices)),
  searchRepositoryProvider.overrideWith((ref) {
    final elections = ref.watch(_mockElections);
    final petitions = ref.watch(_mockPetitions);
    final services = ref.watch(_mockServices);
    return MockSearchRepository(ref.watch(mockServerProvider), [
      (_) => [
        for (final e in elections.all())
          SearchResult(
            kind: SearchKind.election,
            id: e.id,
            title: e.title,
            subtitle: SearchStrings.election,
          ),
      ],
      (userId) => [
        for (final p in petitions.all(userId))
          SearchResult(
            kind: SearchKind.petition,
            id: p.id,
            title: p.title,
            subtitle: p.category ?? SearchStrings.petition,
          ),
      ],
      (_) => [
        for (final s in services.all())
          SearchResult(
            kind: SearchKind.service,
            id: s.id,
            title: s.title,
            subtitle: SearchStrings.service,
          ),
      ],
      (_) => const [
        SearchResult(kind: SearchKind.document, id: 'doc_passport', title: 'Passeport', subtitle: SearchStrings.document),
        SearchResult(kind: SearchKind.document, id: 'doc_licence', title: 'Permis de conduire', subtitle: SearchStrings.document),
        SearchResult(kind: SearchKind.document, id: 'doc_tax', title: 'Avis d’imposition 2025', subtitle: SearchStrings.document),
      ],
    ]);
  }),
];

// ------------------------------------------------------------------ REST

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  return ApiClient.create(
    baseUrl: config.apiBaseUrl,
    session: ref.watch(sessionHolderProvider),
    offline: ref.watch(offlineStoreProvider),
  );
});

final class RestReachability implements Reachability {
  RestReachability(this._api);
  final ApiClient _api;

  @override
  Future<bool> check() async {
    try {
      await _api.get('/health', auth: false, decode: (_) {});
      return true;
    } on Object catch (e) {
      if (kDebugMode) debugPrint('[health] $e');
      return false;
    }
  }
}

List<Override> restOverrides(AppConfig config) => [
  reachabilityProvider.overrideWith(
    (ref) => RestReachability(ref.watch(apiClientProvider)),
  ),
  authRepositoryProvider.overrideWith(
    (ref) => RestAuthRepository(
      ref.watch(apiClientProvider),
      deviceId: () => ref.read(deviceIdentityProvider).id,
    ),
  ),
  identityRepositoryProvider.overrideWith(
    (ref) => RestIdentityRepository(
      ref.watch(apiClientProvider),
      ref.watch(offlineStoreProvider),
    ),
  ),
  homeRepositoryProvider.overrideWith(
    (ref) => RestHomeRepository(
      ref.watch(apiClientProvider),
      ref.watch(offlineStoreProvider),
    ),
  ),
  notificationsRepositoryProvider.overrideWith(
    (ref) => RestNotificationsRepository(ref.watch(apiClientProvider)),
  ),
  activityRepositoryProvider.overrideWith(
    (ref) => RestActivityRepository(ref.watch(apiClientProvider)),
  ),
  electionsRepositoryProvider.overrideWith(
    (ref) => RestElectionsRepository(ref.watch(apiClientProvider)),
  ),
  petitionsRepositoryProvider.overrideWith(
    (ref) => RestPetitionsRepository(ref.watch(apiClientProvider)),
  ),
  documentsRepositoryProvider.overrideWith(
    (ref) => RestDocumentsRepository(ref.watch(apiClientProvider)),
  ),
  servicesRepositoryProvider.overrideWith(
    (ref) => RestServicesRepository(ref.watch(apiClientProvider)),
  ),
  searchRepositoryProvider.overrideWith(
    (ref) => RestSearchRepository(ref.watch(apiClientProvider)),
  ),
];
