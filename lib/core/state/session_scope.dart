import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Changes on every sign-in, sign-out or account switch. Every data
/// provider watches it, so nothing of the previous account survives.
final sessionScopeProvider = NotifierProvider<SessionScope, int>(
  SessionScope.new,
);

class SessionScope extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}
