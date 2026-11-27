import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/routes.dart';
import '../../../core/core_providers.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/strings.dart';

/// First screen when signed out.
class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final demo = ref.watch(appConfigProvider).isDemo;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: MaxWidth(
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.xxl),
                        const Center(child: CardMascot(size: AppSizes.mascot * 1.6)),
                        const SizedBox(height: AppSpacing.xxl),
                        Semantics(
                          header: true,
                          child: Text(AuthStrings.landingTitle, style: t.display),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          AuthStrings.landingBody,
                          style: t.subtitle.copyWith(color: c.inkSecondary),
                        ),
                        const Spacer(),
                        const SizedBox(height: AppSpacing.xxl),
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
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            '${AuthStrings.demoTitle} · ${AuthStrings.demoBody.split(' (').first}',
                            textAlign: TextAlign.center,
                            style: t.caption.copyWith(color: c.inkTertiary),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
