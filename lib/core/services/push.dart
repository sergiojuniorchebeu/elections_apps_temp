/// Push notifications. Default implementation does nothing; plug FCM,
/// APNs or OneSignal by implementing this interface.
abstract interface class PushService {
  /// Asks the OS permission. Returns whether pushes are allowed.
  Future<bool> requestPermission();

  /// Device token to register with the back-end, or null.
  Future<String?> token();

  /// Route opened when the user taps a notification (e.g. `/petitions/p1`).
  Stream<String> get openedRoutes;
}

final class NoopPushService implements PushService {
  const NoopPushService();
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<String?> token() async => null;
  @override
  Stream<String> get openedRoutes => const Stream.empty();
}

/// Home-screen icon shortcuts (quick actions). Default: none. Plug
/// `quick_actions` by implementing this interface.
abstract interface class AppShortcuts {
  /// Route opened from a shortcut (e.g. `/id`).
  Stream<String> get openedRoutes;
}

final class NoAppShortcuts implements AppShortcuts {
  const NoAppShortcuts();
  @override
  Stream<String> get openedRoutes => const Stream.empty();
}
