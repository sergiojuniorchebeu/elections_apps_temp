import 'package:elections_app/core/network/api_client.dart';
import 'package:elections_app/core/session/session_holder.dart';
import 'package:elections_app/core/storage/offline_store.dart';
import 'package:elections_app/core/storage/secure_store.dart';
import 'package:elections_app/core/storage/session_store.dart';
import 'package:elections_app/features/auth/data/mock/mock_auth_repository.dart';
import 'package:elections_app/features/auth/data/rest/rest_auth_repository.dart';
import 'package:elections_app/features/auth/domain/auth_repository.dart';
import 'package:elections_app/features/notifications/data/mock/mock_notifications_repository.dart';
import 'package:elections_app/features/notifications/data/rest/rest_notifications_repository.dart';
import 'package:elections_app/features/notifications/domain/notifications_repository.dart';
import 'package:elections_app/features/petitions/data/mock/mock_petitions_repository.dart';
import 'package:elections_app/features/petitions/data/rest/rest_petitions_repository.dart';
import 'package:elections_app/features/petitions/domain/petitions_repository.dart';
import 'package:elections_app/mock/mock_accounts.dart';
import 'package:elections_app/mock/mock_server.dart';

import '../helpers/simulator_http_adapter.dart';

/// What a contract suite needs from an implementation. To check YOUR
/// back-end, write an env that builds your repositories (see
/// docs/BACKEND.md) and call the suites with it.
abstract class ContractEnv {
  String get name;
  AuthRepository get auth;
  PetitionsRepository get petitions;
  NotificationsRepository get notifications;

  /// The client-side session (where implementations read their tokens).
  SessionHolder get session;

  Future<void> signIn() async {
    final r = await auth.signIn(
      email: MockAccounts.demoEmail,
      password: MockAccounts.demoPassword,
    );
    await session.set(r.session);
  }

  /// Makes the current access token invalid; the next call must renew it.
  Future<void> expireAccess();
}

SessionHolder _holder() => SessionHolder(SessionStore(MemorySecureStore()));

final class MockEnv extends ContractEnv {
  MockEnv() {
    session.renewer = server.renew;
  }

  @override
  final session = _holder();
  late final server = MockServer(
    session: session,
    latencyMin: Duration.zero,
    latencyMax: Duration.zero,
  );

  @override
  String get name => 'simulator';
  @override
  late final AuthRepository auth = MockAuthRepository(server);
  @override
  late final PetitionsRepository petitions = MockPetitionsRepository(server);
  @override
  late final NotificationsRepository notifications = MockNotificationsRepository(server);

  @override
  Future<void> expireAccess() async => server.expireAccessToken();
}

final class RestEnv extends ContractEnv {
  RestEnv() {
    session.renewer = (s) => auth.renew(s);
  }

  @override
  final session = _holder();
  final serverSession = _holder();
  late final server = MockServer(
    session: serverSession,
    latencyMin: Duration.zero,
    latencyMax: Duration.zero,
  );
  late final adapter = SimulatorHttpAdapter(server, serverSession);
  late final api = ApiClient.create(
    baseUrl: 'https://api.example.org/v1',
    session: session,
    offline: OfflineStore(MemorySecureStore()),
    adapter: adapter,
  );

  @override
  String get name => 'REST';
  @override
  late final AuthRepository auth = RestAuthRepository(api, deviceId: () => 'device-test');
  @override
  late final PetitionsRepository petitions = RestPetitionsRepository(api);
  @override
  late final NotificationsRepository notifications = RestNotificationsRepository(api);

  @override
  Future<void> expireAccess() async {
    final s = session.current!;
    await session.set(s.copyWithAccess('mock.at.${s.userId}.0'));
  }
}
