import 'dart:io';

import 'package:elections_app/app/app.dart';
import 'package:elections_app/app/router/app_router.dart';
import 'package:elections_app/backend.dart';
import 'package:elections_app/bootstrap.dart';
import 'package:elections_app/core/config/app_config.dart';
import 'package:elections_app/core/core_providers.dart';
import 'package:elections_app/core/services/services.dart';
import 'package:elections_app/core/state/fresh.dart';
import 'package:elections_app/core/storage/preferences.dart';
import 'package:elections_app/core/storage/secure_store.dart';
import 'package:elections_app/mock/mock_providers.dart';
import 'package:elections_app/mock/mock_server.dart';
import 'package:elections_app/mock/scenario.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Reference sizes (README "Responsive").
abstract final class TestSizes {
  static const small = Size(320, 568);
  static const phone = Size(430, 932);
  static const tablet = Size(820, 1180);
}

/// Authenticator answering instantly, for tests.
final class FakeAuthenticator implements DeviceAuthenticator {
  FakeAuthenticator({this.available = true, this.approve = true});
  bool available;
  bool approve;
  int calls = 0;

  @override
  String get label => 'Face ID';
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<bool> authenticate(String reason) async {
    calls++;
    return approve;
  }
}

final class RecordingAnalytics implements Analytics {
  final events = <(String, Map<String, Object>)>[];
  @override
  void track(String event, [Map<String, Object> properties = const {}]) =>
      events.add((event, properties));
  @override
  Future<void> flush() async {}
}

/// The whole app (real router, real controllers) on the simulator.
final class TestApp {
  TestApp(this.tester, this.container);

  final WidgetTester tester;
  final ProviderContainer container;

  MockServer get server => container.read(mockServerProvider);

  Future<void> go(String location) async {
    container.read(routerProvider).go(location);
    await tester.pumpAndSettle();
  }

  set scenario(MockScenario s) => server.scenario = s;

  /// Unmounts the app and disposes the container: no timer survives.
  Future<void> dispose() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pump();
  }
}

/// Starts the app on the simulator.
///
/// * [size] / [textScale]: screen and text size;
/// * [signedIn]: starts with a valid session of [userId];
/// * [scenario]: forced simulator scenario;
/// * [location]: first route (deep link);
/// * [overrides]: fake services (authenticator, analytics...).
Future<TestApp> pumpApp(
  WidgetTester tester, {
  Size size = TestSizes.phone,
  double textScale = 1,
  bool signedIn = true,
  String userId = 'u_alex',
  MockScenario scenario = MockScenario.normal,
  String? location,
  ThemeMode themeMode = ThemeMode.light,
  List<Override> overrides = const [],
  Preferences? preferences,
  DeviceAuthenticator? authenticator,
  DateTime Function()? clock,
  bool devPanel = true,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  tester.platformDispatcher
    ..textScaleFactorTestValue = textScale
    // Stops decorative animations (skeleton pulse) so pumpAndSettle ends.
    ..accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);

  final config = AppConfig(
    mockLatencyMin: Duration.zero,
    mockLatencyMax: Duration.zero,
    showDevPanel: devPanel,
  );
  final freshness = FreshnessObserver();
  final prefs = preferences ?? MemoryPreferences({PrefKeys.themeMode: themeMode.name});
  final container = ProviderContainer(
    overrides: [
      ...appOverrides(
        config: config,
        preferences: prefs,
        secureStore: MemorySecureStore(),
        freshness: freshness,
        authenticator: authenticator ?? FakeAuthenticator(),
      ),
      if (clock != null) clockProvider.overrideWithValue(clock),
      ...overrides,
    ],
    observers: [freshness],
    retry: (_, _) => null,
  );
  connectSession(container);
  final server = container.read(mockServerProvider);
  if (signedIn) {
    await container.read(sessionHolderProvider).set(server.issueSession(userId));
  }
  server.scenario = scenario;
  if (location != null) container.read(routerProvider).go(location);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const App()),
  );
  await tester.pumpAndSettle();
  return TestApp(tester, container);
}

/// Loads the bundled Outfit font and Material icons so goldens show real
/// text instead of boxes.
Future<void> loadAppFonts() async {
  final outfit = FontLoader('Outfit');
  for (final w in ['Light', 'Regular', 'Medium', 'SemiBold']) {
    outfit.addFont(_bytes('assets/fonts/Outfit-$w.ttf'));
  }
  await outfit.load();
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final icons = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

Future<ByteData> _bytes(String path) async =>
    ByteData.sublistView(File(path).readAsBytesSync());

Override analyticsProviderOverride(Analytics analytics) =>
    analyticsProvider.overrideWithValue(analytics);
