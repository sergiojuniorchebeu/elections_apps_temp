import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/core_providers.dart';
import '../core/state/session_scope.dart';
import '../design_system/design_system.dart';
import '../l10n/strings.dart';
import '../mock/mock_providers.dart';
import '../mock/scenario.dart';
import 'router/app_router.dart';

/// Demo mode only: a small "DEMO" tab on the screen edge opens the
/// scenario panel. Any screen state is two taps away.
class DevPanelHook extends ConsumerWidget {
  const DevPanelHook({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    if (!config.isDemo || !config.showDevPanel) return child;
    final scenario = ref.watch(mockScenarioProvider);
    final c = context.colors;
    return Stack(
      children: [
        child,
        PositionedDirectional(
          end: 0,
          top: MediaQuery.sizeOf(context).height * 0.38,
          child: Semantics(
            button: true,
            label: DevStrings.title,
            excludeSemantics: true,
            child: Material(
              color: scenario == MockScenario.normal ? c.ink : c.danger,
              borderRadius: const BorderRadiusDirectional.horizontal(
                start: Radius.circular(AppRadius.sm),
              ).resolve(Directionality.of(context)),
              child: InkWell(
                onTap: () => openDevPanel(),
                child: SizedBox(
                  width: AppSpacing.xl,
                  height: AppSizes.touch * 1.4,
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        DevStrings.badge,
                        style: context.text.overline.copyWith(color: c.background),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Opens the scenario panel above everything.
Future<void> openDevPanel() async {
  final context = rootNavigatorKey.currentContext;
  if (context == null) return;
  await showAppSheet<void>(context, builder: (_) => const DevPanel());
}

class DevPanel extends ConsumerWidget {
  const DevPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(mockScenarioProvider);
    final c = context.colors;
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(DevStrings.title, style: t.headline),
        const SizedBox(height: AppSpacing.xxs),
        Text(DevStrings.body, style: t.small.copyWith(color: c.inkSecondary)),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final s in MockScenario.values)
                AppListTile(
                  title: s.label,
                  subtitle: s.description,
                  trailing: Icon(
                    s == current
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: s == current ? c.primary : c.inkTertiary,
                  ),
                  onTap: () {
                    ref.read(mockScenarioProvider.notifier).set(s);
                    // Reload every screen so the new answer shows at once.
                    ref.read(sessionScopeProvider.notifier).bump();
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: AppListTile(
            icon: Icons.key_off_outlined,
            title: DevStrings.expireToken,
            subtitle: DevStrings.expireTokenSub,
            onTap: () {
              ref.read(mockServerProvider).expireAccessToken();
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }
}

/// Demo mode "biometric prompt": approve or fail on demand.
Future<bool> simulatedBiometricPrompt(String reason) async {
  final context = rootNavigatorKey.currentContext;
  if (context == null) return false;
  final result = await showAppSheet<bool>(
    context,
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.fingerprint_rounded, size: AppSizes.iconLg * 2, color: context.colors.primary),
        const SizedBox(height: AppSpacing.sm),
        Text(DevStrings.biometricTitle, textAlign: TextAlign.center, style: context.text.headline),
        const SizedBox(height: AppSpacing.xs),
        Text(reason, textAlign: TextAlign.center, style: context.text.body),
        const SizedBox(height: AppSpacing.lg),
        AppButton(label: DevStrings.approve, onPressed: () => Navigator.pop(context, true)),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          label: DevStrings.fail,
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.pop(context, false),
        ),
      ],
    ),
  );
  return result ?? false;
}
