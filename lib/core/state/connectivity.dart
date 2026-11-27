import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core_providers.dart';
import '../error/failure.dart';

/// Online / offline, learned from real calls (no extra plugin): a
/// [NetworkFailure] switches offline, then the back-end is probed after
/// 3, 6, 12 then every 30 s until it answers.
final connectivityProvider =
    NotifierProvider<ConnectivityController, Connectivity>(
      ConnectivityController.new,
    );

final class Connectivity {
  const Connectivity({this.online = true, this.nextRetryAt, this.checking = false});

  final bool online;
  final DateTime? nextRetryAt;
  final bool checking;
}

class ConnectivityController extends Notifier<Connectivity> {
  static const schedule = [
    Duration(seconds: 3),
    Duration(seconds: 6),
    Duration(seconds: 12),
    Duration(seconds: 30),
  ];

  Timer? _timer;
  int _attempt = 0;

  @override
  Connectivity build() {
    ref.onDispose(() => _timer?.cancel());
    return const Connectivity();
  }

  /// Every repository call ends here (see `guard`).
  void report(Object? error) {
    if (error == null) return markOnline();
    if (error is NetworkFailure) markOffline();
  }

  void markOnline() {
    _timer?.cancel();
    _attempt = 0;
    if (!state.online || state.checking) state = const Connectivity();
  }

  void markOffline() {
    if (!state.online && _timer != null) return;
    _scheduleProbe();
  }

  /// "Retry" in the banner.
  Future<void> retryNow() => _probe();

  void _scheduleProbe() {
    _timer?.cancel();
    final delay = schedule[_attempt.clamp(0, schedule.length - 1)];
    _attempt++;
    state = Connectivity(online: false, nextRetryAt: DateTime.now().add(delay));
    _timer = Timer(delay, _probe);
  }

  Future<void> _probe() async {
    _timer?.cancel();
    _timer = null;
    state = Connectivity(online: false, checking: true);
    bool ok;
    try {
      ok = await ref.read(reachabilityProvider).check();
    } on Object {
      ok = false;
    }
    if (!ref.mounted) return;
    ok ? markOnline() : _scheduleProbe();
  }
}

/// Runs a repository call and feeds the outcome to [connectivityProvider].
/// Anything thrown comes out as a [Failure].
Future<T> guard<T>(Ref ref, Future<T> Function() call) async {
  try {
    final value = await call();
    if (ref.mounted) ref.read(connectivityProvider.notifier).report(null);
    return value;
  } on Object catch (e) {
    final failure = Failure.from(e);
    if (ref.mounted) ref.read(connectivityProvider.notifier).report(failure);
    throw failure;
  }
}
