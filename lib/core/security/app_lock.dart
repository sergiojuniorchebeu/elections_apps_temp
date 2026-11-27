import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/strings.dart';
import '../core_providers.dart';
import '../services/services.dart';
import '../storage/preferences.dart';

/// Optional lock by biometrics / device passcode. Locks at start and
/// when the app comes back after [relockAfter] in the background.
final appLockProvider = NotifierProvider<AppLockController, AppLockState>(
  AppLockController.new,
);

final class AppLockState {
  const AppLockState({required this.enabled, required this.locked});
  final bool enabled;
  final bool locked;
}

class AppLockController extends Notifier<AppLockState> {
  static const relockAfter = Duration(seconds: 30);
  DateTime? _pausedAt;
  DateTime Function() clock = DateTime.now;

  @override
  AppLockState build() {
    final enabled =
        ref.read(preferencesProvider).getBool(PrefKeys.appLockEnabled) ?? false;
    return AppLockState(enabled: enabled, locked: enabled);
  }

  Future<bool> setEnabled(bool enabled) async {
    final auth = ref.read(deviceAuthenticatorProvider);
    if (enabled) {
      if (!await auth.isAvailable()) return false;
      if (!await auth.authenticate(LockStrings.turnOn(auth.label))) {
        return false;
      }
    }
    await ref.read(preferencesProvider).setBool(PrefKeys.appLockEnabled, enabled);
    state = AppLockState(enabled: enabled, locked: false);
    return true;
  }

  Future<bool> unlock() async {
    final auth = ref.read(deviceAuthenticatorProvider);
    final ok = await auth.authenticate(LockStrings.unlockPrompt);
    if (ok) state = AppLockState(enabled: state.enabled, locked: false);
    return ok;
  }

  void paused() => _pausedAt ??= clock();

  void resumed() {
    final at = _pausedAt;
    _pausedAt = null;
    if (state.enabled && at != null && clock().difference(at) >= relockAfter) {
      state = AppLockState(enabled: true, locked: true);
    }
  }

  /// Signed out: the lock belongs to the account.
  void reset() => state = const AppLockState(enabled: false, locked: false);
}
