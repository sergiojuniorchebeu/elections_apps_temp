import 'package:flutter/foundation.dart';

/// Where unhandled errors go. `bootstrap.dart` routes every uncaught
/// error through [CrashReporter.report]: plug Sentry, Crashlytics...
abstract interface class CrashReporter {
  void report(Object error, StackTrace? stack, {bool fatal = false});
}

/// Default: printed in debug, dropped in release.
final class DebugCrashReporter implements CrashReporter {
  const DebugCrashReporter();
  @override
  void report(Object error, StackTrace? stack, {bool fatal = false}) {
    if (kDebugMode) {
      debugPrint('[${fatal ? 'FATAL' : 'error'}] $error\n$stack');
    }
  }
}
