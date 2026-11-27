import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/routes.dart';
import '../../../core/core_providers.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/strings.dart';

/// First screen when signed out.
///
/// Usual onboarding layout: the presentation scrolls at the top, the two
/// actions stay pinned at the bottom, within thumb reach, whatever the
/// screen height or text size.
class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  static const _features = [
    (AppIcons.identity, AuthStrings.featureId, AuthStrings.featureIdSub),
    (AppIcons.elections, AuthStrings.featureElections, AuthStrings.featureElectionsSub),
    (AppIcons.petitions, AuthStrings.featurePetitions, AuthStrings.featurePetitionsSub),
    (AppIcons.services, AuthStrings.featureServices, AuthStrings.featureServicesSub),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final demo = ref.watch(appConfigProvider).isDemo;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: MaxWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.xl,
                      AppSpacing.gutter,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: CardMascot(size: AppSizes.mascot * 1.3)),
                        const SizedBox(height: AppSpacing.xl),
                        Semantics(
                          header: true,
                          child: Text(AuthStrings.landingTitle, style: t.display),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          AuthStrings.landingBody,
                          style: t.subtitle.copyWith(color: c.inkSecondary),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        for (final (icon, title, subtitle) in _features)
                          _Feature(icon: icon, title: title, subtitle: subtitle),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.sm,
                    AppSpacing.gutter,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppButton(
                        label: AuthStrings.createAccount,
                        onPressed: () => context.push(Routes.signUp),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: AuthStrings.haveAccount,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => context.push(Routes.signIn),
                      ),
                      if (demo) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          AuthStrings.demoTitle,
                          textAlign: TextAlign.center,
                          style: t.caption.copyWith(color: c.inkTertiary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: MergeSemantics(
        child: Row(
          children: [
            Container(
              width: AppSizes.touch,
              height: AppSizes.touch,
              decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: AppIcon(icon, size: AppSizes.icon, color: c.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.bodyStrong),
                  Text(subtitle, style: t.small.copyWith(color: c.inkSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
