import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../error/failure.dart';
import 'connectivity.dart';

/// Explicit state of a user action (send, save, sign...).
sealed class ActionState<T> {
  const ActionState();
  bool get isRunning => this is ActionRunning<T>;
}

final class ActionIdle<T> extends ActionState<T> {
  const ActionIdle();
}

final class ActionRunning<T> extends ActionState<T> {
  const ActionRunning();
}

final class ActionSucceeded<T> extends ActionState<T> {
  const ActionSucceeded(this.value);
  final T value;
}

final class ActionFailed<T> extends ActionState<T> {
  const ActionFailed(this.failure);
  final Failure failure;
}

/// Base for every action controller: refuses a second call while the
/// first runs, refuses writes offline, and keeps one idempotency key per
/// attempt — reused as-is when the same action is sent again after a
/// failure, renewed after a success or [reset].
abstract class ActionController<T> extends Notifier<ActionState<T>> {
  String? _idempotencyKey;

  @override
  ActionState<T> build() => ActionIdle<T>();

  /// Key to send with the write. Same value across retries.
  String get idempotencyKey => _idempotencyKey ??= const Uuid().v4();

  /// Runs [action]. Returns the value, or null when it failed or was
  /// refused (the state tells why).
  Future<T?> run(Future<T> Function(String idempotencyKey) action) async {
    if (state.isRunning) return null;
    if (!ref.read(connectivityProvider).online) {
      state = ActionFailed<T>(const NetworkFailure());
      return null;
    }
    state = ActionRunning<T>();
    try {
      final value = await guard(ref, () => action(idempotencyKey));
      if (!ref.mounted) return value;
      _idempotencyKey = null;
      state = ActionSucceeded<T>(value);
      return value;
    } on Failure catch (f) {
      // Validation means the request was refused as a whole: a corrected
      // request is a new one.
      if (f is ValidationFailure) _idempotencyKey = null;
      if (ref.mounted) state = ActionFailed<T>(f);
      return null;
    }
  }

  void reset() {
    _idempotencyKey = null;
    state = ActionIdle<T>();
  }
}
