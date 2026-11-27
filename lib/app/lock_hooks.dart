import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/security/app_lock.dart';
import '../core/services/services.dart';
import '../design_system/design_system.dart';
import '../features/auth/auth.dart';
import '../l10n/strings.dart';

/// Covers the app while it is locked (biometrics / passcode). Keeps the
/// navigation stack underneath intact.
class LockHook extends ConsumerWidget {
  const LockHook({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = ref.watch(appLockProvider.select((s) => s.locked));
    final signedIn = ref.watch(sessionControllerProvider.select((s) => s.signedIn));
    return Stack(
      children: [
        // Hidden from screen readers and touches while locked.
        ExcludeSemantics(
          excluding: locked && signedIn,
          child: IgnorePointer(ignoring: locked && signedIn, child: child),
        ),
        if (locked && signedIn) const Positioned.fill(child: _LockScreen()),
      ],
    );
  }
}

class _LockScreen extends ConsumerStatefulWidget {
  const _LockScreen();

  @override
  ConsumerState<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<_LockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() => ref.read(appLockProvider.notifier).unlock();

  @override
  Widget build(BuildContext context) {
    final label = ref.watch(deviceAuthenticatorProvider).label;
    return Material(
      color: context.colors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            children: [
              const Spacer(),
              const CardMascot(),
              const SizedBox(height: AppSpacing.xl),
              Text(LockStrings.title, style: context.text.title),
              const Spacer(),
              MaxWidth(
                child: AppButton(
                  label: LockStrings.unlockWith(label),
                  icon: Icons.lock_open_rounded,
                  onPressed: _unlock,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
