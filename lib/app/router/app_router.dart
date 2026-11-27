import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/activity/presentation/activity_screen.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/landing_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/documents/presentation/documents_screens.dart';
import '../../features/elections/presentation/elections_screens.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/identity/presentation/digital_id_screen.dart';
import '../../features/identity/presentation/personal_details_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/petitions/presentation/petitions_screens.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/services/presentation/services_screens.dart';
import '../../shared/screens/not_found_screen.dart';
import 'app_shell.dart';
import 'routes.dart';

/// Root navigator: full-screen pages and sheets go above the tab bar.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Where a signed-out user wanted to go (deep link), restored after
/// sign-in.
String? _pendingLocation;

final routerProvider = Provider<GoRouter>((ref) {
  final signedIn = ValueNotifier(ref.read(sessionControllerProvider).signedIn);
  ref.listen(
    sessionControllerProvider,
    (_, next) => signedIn.value = next.signedIn,
  );

  GoRoute detail(String base, Widget Function(String id) screen) => GoRoute(
    path: '$base/:${Routes.idParam}',
    parentNavigatorKey: rootNavigatorKey,
    builder: (_, state) {
      final id = state.pathParameters[Routes.idParam];
      // Ids from links are checked before any call.
      return Routes.isValidId(id)
          ? screen(id!)
          : const NotFoundScreen(homeRoute: Routes.home);
    },
  );

  GoRoute page(String path, Widget screen) => GoRoute(
    path: path,
    parentNavigatorKey: rootNavigatorKey,
    builder: (_, _) => screen,
  );

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.home,
    refreshListenable: signedIn,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isPublic = Routes.public.contains(location);
      if (!signedIn.value) {
        if (isPublic) return null;
        if (location != Routes.home) _pendingLocation = state.uri.toString();
        return Routes.welcome;
      }
      if (isPublic && location != Routes.notFound) {
        final target = _pendingLocation ?? Routes.home;
        _pendingLocation = null;
        return target;
      }
      return null;
    },
    errorBuilder: (_, _) => const NotFoundScreen(homeRoute: Routes.home),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => Routes.home),
      GoRoute(path: Routes.welcome, builder: (_, _) => const LandingScreen()),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(path: Routes.signUp, builder: (_, _) => const SignUpScreen()),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: Routes.notFound,
        builder: (_, _) => const NotFoundScreen(homeRoute: Routes.home),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.digitalId,
                builder: (_, _) => const DigitalIdScreen(),
                routes: [
                  GoRoute(
                    path: 'details',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (_, _) => const PersonalDetailsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.activity,
                builder: (_, _) => const ActivityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      page(Routes.notifications, const NotificationsScreen()),
      page(Routes.search, const SearchScreen()),
      page(Routes.elections, const ElectionsScreen()),
      detail(Routes.elections, (id) => ElectionScreen(id: id)),
      page(Routes.petitions, const PetitionsScreen()),
      detail(Routes.petitions, (id) => PetitionScreen(id: id)),
      page(Routes.documents, const DocumentsScreen()),
      detail(Routes.documents, (id) => DocumentScreen(id: id)),
      page(Routes.services, const ServicesScreen()),
      detail(Routes.services, (id) => ServiceScreen(id: id)),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    signedIn.dispose();
  });
  return router;
});
