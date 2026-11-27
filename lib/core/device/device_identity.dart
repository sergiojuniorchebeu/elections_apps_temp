import 'package:uuid/uuid.dart';

import '../storage/preferences.dart';

/// Random id of this install (never a hardware id). Sent with sign-in so
/// the back-end can list the user's devices.
final class DeviceIdentity {
  DeviceIdentity(this._prefs);
  final Preferences _prefs;

  String get id {
    final existing = _prefs.getString(PrefKeys.deviceId);
    if (existing != null) return existing;
    final created = const Uuid().v4();
    _prefs.setString(PrefKeys.deviceId, created);
    return created;
  }
}
