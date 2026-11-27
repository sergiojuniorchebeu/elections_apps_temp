import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/routes.dart';
import '../../../core/services/services.dart';
import '../../../core/state/fresh.dart';
import '../../../core/utils/formats.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../notifications/notifications.dart';
import '../application/identity_providers.dart';
import '../domain/citizen_id.dart';
import 'identity_sheets.dart';
import 'widgets/citizen_card.dart';

/// Digital ID tab: the card, a dark band with Show code / Check / Share,
/// and the personal details sheet.
class DigitalIdScreen extends ConsumerWidget {
  const DigitalIdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watchFresh(citizenIdProvider);
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.surface,
      body: RefreshIndicator.adaptive(
        onRefresh: () async {
          final f = await ref.read(citizenIdProvider.notifier).refresh();
          if (f != null && context.mounted) showFailureSnack(context, f);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AsyncView(
                value: id,
                onRetry: () => ref.invalidate(citizenIdProvider),
                skeleton: const _IdSkeleton(),
                data: (citizen) => _IdContent(citizen: citizen),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: SizedBox(height: AppNavBar.bottomInset(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdContent extends ConsumerWidget {
  const _IdContent({required this.citizen});
  final CitizenId citizen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final top = MediaQuery.paddingOf(context).top;
    final (statusLabel, statusIcon, statusColor) = switch (citizen.status) {
      IdStatus.verified => (IdStrings.identityVerified, Icons.check_rounded, c.primary),
      IdStatus.suspended => (IdStrings.identitySuspended, Icons.block_rounded, c.danger),
      _ => (IdStrings.identityPending, Icons.schedule_rounded, c.warning),
    };
    return ColoredBox(
      color: c.band,
      child: Column(
        children: [
          // Light top block with the card, rounded at the bottom.
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppRadius.xl),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  top + AppSpacing.md,
                  AppSpacing.gutter,
                  AppSpacing.xl,
                ),
                child: MaxWidth(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(IdStrings.title, style: t.title),
                            ),
                          ),
                          CircleIconButton(
                            icon: Icons.search_rounded,
                            semanticLabel: CommonStrings.search,
                            onPressed: () => context.push(Routes.search),
                          ),
                          const NotificationBell(),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CitizenCard(
                        fullName: citizen.fullName,
                        last4: citizen.numberLast4,
                        verified: citizen.isVerified,
                        onOpen: () => showCodeSheet(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: -AppSpacing.md,
                child: StatusPill(
                  label: statusLabel,
                  icon: statusIcon,
                  foreground: statusColor,
                ),
              ),
            ],
          ),
          // Dark band: actions.
          MaxWidth(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.xxl,
                AppSpacing.gutter,
                AppSpacing.xl,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _BandButton(
                      label: IdStrings.showCode,
                      icon: Icons.qr_code_2_rounded,
                      onTap: () => showCodeSheet(context, ref),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  CircleIconButton(
                    icon: Icons.qr_code_scanner_rounded,
                    semanticLabel: IdStrings.verifyId,
                    background: c.surface,
                    foreground: c.primary,
                    onPressed: () => showVerifySheet(context),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _BandButton(
                      label: IdStrings.shareId,
                      icon: Icons.ios_share_rounded,
                      onTap: () => showShareSheet(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // White sheet with a small notch.
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: AppSizes.handleWidth + AppSpacing.md,
                  height: AppSpacing.sm,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.band,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppRadius.sm),
                    ),
                  ),
                  child: Container(
                    width: AppSpacing.md,
                    height: AppSizes.handleHeight / 2,
                    color: c.inkTertiary,
                  ),
                ),
                MaxWidth(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.sm,
                      AppSpacing.gutter,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                header: true,
                                child: Text(
                                  IdStrings.personalDetails,
                                  style: t.subtitle,
                                ),
                              ),
                            ),
                            PillButton(
                              label: IdStrings.manage,
                              filled: false,
                              onPressed: () => context.push(Routes.personalDetails),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppCard(
                          color: c.background,
                          child: Column(
                            children: [
                              KeyValueRow(
                                label: IdStrings.fullName,
                                value: citizen.fullName,
                              ),
                              KeyValueRow(
                                label: IdStrings.dateOfBirth,
                                value: Formats.date(citizen.dateOfBirth),
                              ),
                              KeyValueRow(
                                label: IdStrings.citizenNumber,
                                value: '•••• ${Formats.masked(citizen.numberLast4)}',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _BiometricRow(enabled: citizen.biometricProtection),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BiometricRow extends ConsumerWidget {
  const _BiometricRow({required this.enabled});
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final label = ref.watch(deviceAuthenticatorProvider).label;
    return AppCard(
      color: c.surfaceMuted,
      padding: EdgeInsets.zero,
      onTap: () => showBiometricSheet(context),
      child: AppListTile(
        icon: Icons.verified_user_outlined,
        iconBackground: c.surface,
        title: IdStrings.biometric,
        subtitle: enabled ? IdStrings.biometricOn(label) : IdStrings.biometricOff,
        trailing: Icon(Icons.north_east_rounded, color: c.primary, size: AppSizes.icon),
      ),
    );
  }
}

class _BandButton extends StatelessWidget {
  const _BandButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      container: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: c.bandButton,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.buttonHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.label.copyWith(color: c.onBand),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(icon, size: AppSizes.iconSm, color: c.onBand),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IdSkeleton extends StatelessWidget {
  const _IdSkeleton();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      AppSpacing.gutter,
      MediaQuery.paddingOf(context).top + AppSpacing.md,
      AppSpacing.gutter,
      0,
    ),
    child: const MaxWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FractionallySizedBox(widthFactor: .45, child: Skeleton(height: AppSpacing.xxl)),
          SizedBox(height: AppSpacing.md),
          AspectRatio(aspectRatio: AppSizes.cardAspect, child: Skeleton(radius: AppRadius.xl)),
          SizedBox(height: AppSpacing.xl),
          Skeleton(height: AppSizes.buttonHeight, radius: AppRadius.md),
          SizedBox(height: AppSpacing.xl),
          SkeletonList(count: 3),
        ],
      ),
    ),
  );
}
