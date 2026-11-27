import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../design_system/design_system.dart';
import '../../l10n/strings.dart';

/// Signed-in frame: four tabs that keep their state, content scrolling
/// behind the floating pill bar, snack bars above it.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const items = [
    NavItem(Icons.home_outlined, NavStrings.home),
    NavItem(Icons.badge_outlined, NavStrings.digitalId),
    NavItem(Icons.monitor_heart_outlined, NavStrings.activity),
    NavItem(Icons.person_outline_rounded, NavStrings.profile),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: true,
    backgroundColor: context.colors.background,
    body: shell,
    bottomNavigationBar: AppNavBar(
      items: items,
      currentIndex: shell.currentIndex,
      // Tapping the current tab again goes back to its root.
      onSelect: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
    ),
  );
}
