import '../../l10n/strings.dart';

/// Biometrics / device passcode. Default: unavailable (the app lock is
/// then hidden). Plug `local_auth` by implementing this interface.
abstract interface class DeviceAuthenticator {
  Future<bool> isAvailable();

  /// Label shown to the user: "Face ID", "Touch ID", "Fingerprint"...
  String get label;

  /// True when the user proved their identity.
  Future<bool> authenticate(String reason);
}

final class UnavailableAuthenticator implements DeviceAuthenticator {
  const UnavailableAuthenticator();
  @override
  Future<bool> isAvailable() async => false;
  @override
  String get label => LockStrings.deviceLock;
  @override
  Future<bool> authenticate(String reason) async => false;
}

/// Demo mode: behaves like a device with biometrics; the answer is given
/// by [decide] (the simulator shows an "Approve / Fail" sheet).
final class SimulatedAuthenticator implements DeviceAuthenticator {
  SimulatedAuthenticator({required this.label, required this.decide});

  @override
  final String label;
  final Future<bool> Function(String reason) decide;

  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<bool> authenticate(String reason) => decide(reason);
}
