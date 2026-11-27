import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics.dart';
import 'crash_reporter.dart';
import 'device_auth.dart';
import 'problem_report.dart';
import 'push.dart';
import 'qr_scanner.dart';

export 'analytics.dart';
export 'crash_reporter.dart';
export 'device_auth.dart';
export 'problem_report.dart';
export 'push.dart';
export 'qr_scanner.dart';

/// External services, all behind interfaces with an empty default.
/// `bootstrap.dart` overrides them; tests pass fakes to `pumpApp`.
final analyticsProvider = Provider<Analytics>((_) => const NoopAnalytics());
final crashReporterProvider = Provider<CrashReporter>(
  (_) => const DebugCrashReporter(),
);
final pushServiceProvider = Provider<PushService>(
  (_) => const NoopPushService(),
);
final deviceAuthenticatorProvider = Provider<DeviceAuthenticator>(
  (_) => const UnavailableAuthenticator(),
);
final problemReporterProvider = Provider<ProblemReporter>(
  (_) => const EmailProblemReporter('support@example.org'),
);
final qrScannerProvider = Provider<QrScanner>((_) => const NoQrScanner());
final appShortcutsProvider = Provider<AppShortcuts>(
  (_) => const NoAppShortcuts(),
);
