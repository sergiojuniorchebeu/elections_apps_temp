import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/security/app_lock.dart';
import '../core/services/services.dart';
import '../core/state/app_resume.dart';

/// Background / foreground: refresh after 30 s+, re-lock, flush
/// analytics. No UI of its own.
class LifecycleHook extends ConsumerStatefulWidget {
  const LifecycleHook({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<LifecycleHook> createState() => _LifecycleHookState();
}

class _LifecycleHookState extends ConsumerState<LifecycleHook> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onHide: () {
        ref.read(appResumeProvider.notifier).paused();
        ref.read(appLockProvider.notifier).paused();
        unawaited(ref.read(analyticsProvider).flush());
      },
      onShow: () {
        ref.read(appResumeProvider.notifier).resumed();
        ref.read(appLockProvider.notifier).resumed();
      },
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
