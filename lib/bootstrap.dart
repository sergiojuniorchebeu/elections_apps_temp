import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'app/dev_panel.dart';
import 'backend.dart';
import 'l10n/strings.dart';
import 'core/config/app_config.dart';
import 'core/core_providers.dart';
import 'core/services/services.dart';
import 'core/state/fresh.dart';
import 'core/storage/preferences.dart';
import 'core/storage/secure_store.dart';

/// Errors nobody caught all end here: plug your crash tool in
/// [CrashReporter].
CrashReporter _crash = const DebugCrashReporter();
void reportError(Object error, StackTrace? stack, {bool fatal = false}) =>
    _crash.report(error, stack, fatal: fatal);

/// Everything the app needs that is not the back-end itself. Shared with
/// `pumpApp` so tests run the real wiring.
List<Override> appOverrides({
  required AppConfig config,
  required Preferences preferences,
  required SecureStore secureStore,
  required FreshnessObserver freshness,
  DeviceAuthenticator? authenticator,
}) => [
  appConfigProvider.overrideWithValue(config),
  preferencesProvider.overrideWithValue(preferences),
  secureStoreProvider.overrideWithValue(secureStore),
  freshnessObserverProvider.overrideWithValue(freshness),
  problemReporterProvider.overrideWithValue(EmailProblemReporter(config.supportEmail)),
  crashReporterProvider.overrideWithValue(_crash),
  ...backendOverrides(config),
  if (authenticator != null)
    deviceAuthenticatorProvider.overrideWithValue(authenticator)
  // Demo mode: a device "with biometrics" that you approve or fail.
  else if (config.isDemo)
    deviceAuthenticatorProvider.overrideWithValue(
      SimulatedAuthenticator(
        label: defaultTargetPlatform == TargetPlatform.iOS
            ? LockStrings.faceId
            : LockStrings.fingerprint,
        decide: simulatedBiometricPrompt,
      ),
    ),
];

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    reportError(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    reportError(error, stack, fatal: true);
    return true;
  };

  final config = AppConfig.fromEnvironment();

  // Texts are French (lib/l10n): formats follow the same locale.
  Intl.defaultLocale = appLocaleTag;
  await initializeDateFormatting(Intl.defaultLocale);

  final preferences = await SharedPrefs.load();
  final secureStore = KeychainStore();

  // iOS keeps the Keychain after uninstall: a fresh install (no marker in
  // preferences) wipes it. An update keeps the marker: no sign-out.
  if (preferences.getString(PrefKeys.installMarker) == null) {
    try {
      await secureStore.deleteAll();
    } on Object catch (e, s) {
      reportError(e, s);
    }
    await preferences.setString(
      PrefKeys.installMarker,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  final freshness = FreshnessObserver();
  final container = ProviderContainer(
    overrides: appOverrides(
      config: config,
      preferences: preferences,
      secureStore: secureStore,
      freshness: freshness,
    ),
    observers: [freshness],
    // The data layer decides about retries, not Riverpod.
    retry: (_, _) => null,
  );
  connectSession(container);
  await container.read(sessionHolderProvider).restore();

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
