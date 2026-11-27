import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/core_providers.dart';
import '../core/storage/settings_providers.dart';
import '../design_system/design_system.dart';
import '../l10n/strings.dart';
import 'dev_panel.dart';
import 'lifecycle_hooks.dart';
import 'lock_hooks.dart';
import 'navigation_hooks.dart';
import 'offline_banner.dart';
import 'router/app_router.dart';

/// Root widget. Global behaviours are widgets without UI of their own,
/// stacked in `builder` in this order (outermost first):
///
/// 1. text scale clamp (200 % max);
/// 2. [LifecycleHook]: refresh after 30 s in background, re-lock, flush;
/// 3. [OpenRouteHook]: tapped notification / icon shortcut -> route;
/// 4. [AnalyticsHook]: screen views by route pattern;
/// 5. [OfflineBanner]: banner + automatic retries;
/// 6. [LockHook]: covers the app while locked;
/// 7. [DevPanelHook]: scenario panel (demo mode only).
///
/// Session expiry needs no hook: the router redirects on
/// `sessionControllerProvider` and the sign-in screen explains why.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final config = ref.watch(appConfigProvider);
    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: appLocale,
      supportedLocales: const [appLocale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(maxScaleFactor: 2),
          ),
          child: LifecycleHook(
            child: OpenRouteHook(
              child: AnalyticsHook(
                child: OfflineBanner(
                  child: LockHook(
                    child: DevPanelHook(child: _PrecacheIcons(child: child!)),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Decodes the PNG icons once at start-up: tabs and buttons never show an
/// empty square while an image loads.
class _PrecacheIcons extends StatefulWidget {
  const _PrecacheIcons({required this.child});
  final Widget child;

  @override
  State<_PrecacheIcons> createState() => _PrecacheIconsState();
}

class _PrecacheIconsState extends State<_PrecacheIcons> {
  bool _done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_done) return;
    _done = true;
    for (final image in AppIcons.all) {
      precacheImage(image, context, onError: (_, _) {});
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
