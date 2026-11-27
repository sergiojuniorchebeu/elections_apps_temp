import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/failure.dart';
import 'app_resume.dart';
import 'connectivity.dart';
import 'session_scope.dart';

/// Main screens (home, Digital ID): open instantly on the offline copy,
/// then reload in the background. A failed reload keeps what is shown.
/// Reloads when the app comes back (30 s+) and when the network returns.
abstract class OfflineFirstNotifier<T> extends AsyncNotifier<T> {
  /// Offline copy or null. Must not throw.
  Future<T?> peek();

  /// Fresh value. Throws a [Failure].
  Future<T> fetch();

  /// True while the screen shows the offline copy and no fresh answer
  /// arrived yet.
  bool showingCopy = false;

  @override
  Future<T> build() async {
    ref.watch(sessionScopeProvider);
    ref.listen(appResumeProvider, (_, _) => refresh());
    ref.listen(connectivityProvider, (prev, next) {
      if (prev != null && !prev.online && next.online) refresh();
    });
    final copy = await peek();
    if (copy != null) {
      showingCopy = true;
      Future.microtask(refresh);
      return copy;
    }
    showingCopy = false;
    return guard(ref, fetch);
  }

  /// Pull-to-refresh / Retry. Returns the failure, if any, for a snack bar.
  Future<Failure?> refresh() async {
    try {
      final value = await guard(ref, fetch);
      if (!ref.mounted) return null;
      showingCopy = false;
      state = AsyncData(value);
      return null;
    } on Failure catch (f) {
      if (!ref.mounted) return f;
      if (!state.hasValue) state = AsyncError(f, StackTrace.current);
      return f;
    }
  }

  /// After a write that returned the new value.
  void set(T value) => state = AsyncData(value);
}

/// Detail screens: loaded by id, kept a few minutes after the screen
/// closes (see `cacheFor`), updated in place after an action.
abstract class DetailNotifier<T> extends AsyncNotifier<T> {
  DetailNotifier(this.id);
  final String id;

  Future<T> fetch(String id);

  @override
  Future<T> build() {
    ref.watch(sessionScopeProvider);
    return guard(ref, () => fetch(id));
  }

  Future<Failure?> refresh() async {
    try {
      final v = await guard(ref, () => fetch(id));
      if (ref.mounted) state = AsyncData(v);
      return null;
    } on Failure catch (f) {
      if (ref.mounted && !state.hasValue) state = AsyncError(f, StackTrace.current);
      return f;
    }
  }

  void set(T value) => state = AsyncData(value);
}
