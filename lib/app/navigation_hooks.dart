import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/services/services.dart';
import '../core/storage/settings_providers.dart';
import 'router/app_router.dart';
import 'router/routes.dart';

/// Opens the route of a tapped push notification or icon shortcut, after
/// checking it is a known, well-formed path. No UI of its own.
class OpenRouteHook extends ConsumerStatefulWidget {
  const OpenRouteHook({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<OpenRouteHook> createState() => _OpenRouteHookState();
}

class _OpenRouteHookState extends ConsumerState<OpenRouteHook> {
  final _subs = <StreamSubscription<String>>[];

  @override
  void initState() {
    super.initState();
    _subs
      ..add(ref.read(pushServiceProvider).openedRoutes.listen(_open))
      ..add(ref.read(appShortcutsProvider).openedRoutes.listen(_open));
  }

  void _open(String route) {
    final uri = Uri.tryParse(route);
    final ok = uri != null &&
        route.startsWith('/') &&
        uri.pathSegments.every(Routes.isValidId);
    ref.read(routerProvider).push(ok ? route : Routes.notFound);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Screen views, named by route pattern (`/petitions/:id`), never by id.
/// Respects the user's opt-out. No UI of its own.
class AnalyticsHook extends ConsumerStatefulWidget {
  const AnalyticsHook({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AnalyticsHook> createState() => _AnalyticsHookState();
}

class _AnalyticsHookState extends ConsumerState<AnalyticsHook> {
  String? _last;
  late final GoRouter _router = ref.read(routerProvider);

  @override
  void initState() {
    super.initState();
    _router.routerDelegate.addListener(_onRoute);
  }

  void _onRoute() {
    if (!mounted || !ref.read(analyticsEnabledProvider)) return;
    final pattern = _router.routerDelegate.currentConfiguration.fullPath;
    if (pattern == _last || pattern.isEmpty) return;
    _last = pattern;
    ref.read(analyticsProvider).track('screen_view', {'screen': pattern});
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_onRoute);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
