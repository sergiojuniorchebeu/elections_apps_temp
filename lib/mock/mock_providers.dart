import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/core_providers.dart';
import '../core/network/reachability.dart';
import 'mock_server.dart';
import 'scenario.dart';

/// The simulator of this app instance (demo mode and tests).
final mockServerProvider = Provider<MockServer>((ref) {
  final config = ref.watch(appConfigProvider);
  final server = MockServer(
    session: ref.watch(sessionHolderProvider),
    latencyMin: config.mockLatencyMin,
    latencyMax: config.mockLatencyMax,
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(server.dispose);
  return server;
});

/// Current scenario, mirrored for the panel.
final mockScenarioProvider = NotifierProvider<MockScenarioController, MockScenario>(
  MockScenarioController.new,
);

class MockScenarioController extends Notifier<MockScenario> {
  @override
  MockScenario build() {
    final server = ref.watch(mockServerProvider);
    final sub = server.scenarioChanges.listen((s) => state = s);
    ref.onDispose(sub.cancel);
    return server.scenario;
  }

  void set(MockScenario s) => ref.read(mockServerProvider).scenario = s;
}

final class MockReachability implements Reachability {
  MockReachability(this._server);
  final MockServer _server;

  @override
  Future<bool> check() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _server.scenario != MockScenario.offline;
  }
}
