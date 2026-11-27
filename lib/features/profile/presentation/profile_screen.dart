import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/routes.dart';
import '../../../core/config/app_config.dart';
import '../../../core/core_providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/security/app_lock.dart';
import '../../../core/services/services.dart';
import '../../../core/storage/settings_providers.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../auth/auth.dart';
import '../../identity/identity.dart';
import '../application/signature_providers.dart';

/// Profile tab: account, preferences, security, support, sign-out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final citizen = ref.watch(citizenIdProvider).value;
    final c = context.colors;
    final t = context.text;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: MaxWidth(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                AppNavBar.bottomInset(context),
              ),
              children: [
                Semantics(
                  header: true,
                  child: Text(ProfileStrings.title, style: t.title),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: switch (user) {
                    AsyncValue(:final value?) => Row(
                      children: [
                        AppAvatar(initials: value.initials),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(value.fullName, style: t.subtitle),
                              Text(
                                value.email,
                                style: t.small.copyWith(color: c.inkSecondary),
                              ),
                              if (citizen != null) ...[
                                const SizedBox(height: AppSpacing.xxs),
                                StatusPill(
                                  dense: true,
                                  background: citizen.status == IdStatus.verified
                                      ? c.successSoft
                                      : c.warningSoft,
                                  foreground: citizen.status == IdStatus.verified
                                      ? c.success
                                      : c.warning,
                                  icon: citizen.status == IdStatus.verified
                                      ? Icons.check_rounded
                                      : Icons.schedule_rounded,
                                  label: citizen.status == IdStatus.verified
                                      ? IdStrings.identityVerified
                                      : IdStrings.identityPending,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    AsyncValue(:final error?) when !user.isLoading => Row(
                      children: [
                        Expanded(child: Text(Failure.from(error).title, style: t.small)),
                        TextLink(
                          label: CommonStrings.retry,
                          onPressed: () => ref.invalidate(currentUserProvider),
                        ),
                      ],
                    ),
                    _ => const Row(
                      children: [
                        Skeleton(width: AppSizes.avatar, height: AppSizes.avatar, radius: AppRadius.pill),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(child: Skeleton(height: AppSpacing.lg)),
                      ],
                    ),
                  },
                ),
                _Section(
                  title: ProfileStrings.account,
                  children: [
                    AppListTile(
                      icon: AppIcons.profile,
                      title: ProfileStrings.personalDetails,
                      trailing: const _Chevron(),
                      onTap: () => context.push(Routes.personalDetails),
                    ),
                    AppListTile(
                      icon: AppIcons.pen,
                      title: SignatureStrings.tile,
                      subtitle: switch (ref.watch(signatureProvider)) {
                        AsyncData(value: _?) => SignatureStrings.savedOn,
                        AsyncData() => SignatureStrings.none,
                        _ => null,
                      },
                      trailing: const _Chevron(),
                      onTap: () => context.push(Routes.signature),
                    ),
                    AppListTile(
                      icon: AppIcons.documents,
                      title: ProfileStrings.documents,
                      trailing: const _Chevron(),
                      onTap: () => context.push(Routes.documents),
                    ),
                    _SwitchTile(
                      icon: AppIcons.notifications,
                      title: ProfileStrings.pushNotifications,
                      subtitle: ProfileStrings.pushNotificationsSub,
                      value: ref.watch(pushEnabledProvider),
                      onChanged: (v) async {
                        if (v) await ref.read(pushServiceProvider).requestPermission();
                        await ref.read(pushEnabledProvider.notifier).set(v);
                      },
                    ),
                  ],
                ),
                _Section(
                  title: ProfileStrings.preferences,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ProfileStrings.appearance, style: t.bodyStrong),
                          const SizedBox(height: AppSpacing.xs),
                          AppSegmented<ThemeMode>(
                            values: ThemeMode.values,
                            selected: ref.watch(themeModeProvider),
                            labelOf: (m) => switch (m) {
                              ThemeMode.system => ProfileStrings.system,
                              ThemeMode.light => ProfileStrings.light,
                              ThemeMode.dark => ProfileStrings.dark,
                            },
                            onChanged: ref.read(themeModeProvider.notifier).set,
                          ),
                        ],
                      ),
                    ),
                    _SwitchTile(
                      icon: Icons.insights_outlined,
                      title: ProfileStrings.analytics,
                      subtitle: ProfileStrings.analyticsSub,
                      value: ref.watch(analyticsEnabledProvider),
                      onChanged: ref.read(analyticsEnabledProvider.notifier).set,
                    ),
                  ],
                ),
                const _Section(title: ProfileStrings.security, children: [_AppLockTile()]),
                _Section(
                  title: ProfileStrings.support,
                  children: [
                    AppListTile(
                      icon: Icons.bug_report_outlined,
                      title: ProfileStrings.report,
                      trailing: const _Chevron(),
                      onTap: () => showAppSheet<void>(
                        context,
                        builder: (_) => const _ReportSheet(),
                      ),
                    ),
                    AppListTile(
                      icon: Icons.info_outline_rounded,
                      title: ProfileStrings.about,
                      subtitle: ProfileStrings.version(AppConfig.version),
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: ref.read(appConfigProvider).appName,
                        applicationVersion: AppConfig.version,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: ProfileStrings.signOut,
                  icon: Icons.logout_rounded,
                  variant: AppButtonVariant.danger,
                  onPressed: () async {
                    final ok = await confirmDialog(
                      context,
                      title: ProfileStrings.signOutConfirm,
                      message: ProfileStrings.signOutBody,
                      confirmLabel: ProfileStrings.signOut,
                      destructive: true,
                    );
                    if (ok) await ref.read(sessionControllerProvider.notifier).signOut();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xxs, bottom: AppSpacing.xs),
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: context.text.label.copyWith(color: context.colors.inkSecondary),
            ),
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
                children[i],
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _Chevron extends StatelessWidget {
  const _Chevron();
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.chevron_right_rounded, color: context.colors.inkTertiary);
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => AppListTile(
    icon: icon,
    title: title,
    subtitle: subtitle,
    onTap: onChanged == null ? null : () => onChanged!(!value),
    trailing: Switch.adaptive(value: value, onChanged: onChanged),
  );
}

final _lockAvailableProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(deviceAuthenticatorProvider).isAvailable(),
);

class _AppLockTile extends ConsumerWidget {
  const _AppLockTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(_lockAvailableProvider).value ?? false;
    final lock = ref.watch(appLockProvider);
    final label = ref.watch(deviceAuthenticatorProvider).label;
    return _SwitchTile(
      icon: Icons.lock_outline_rounded,
      title: ProfileStrings.appLock(label),
      subtitle: available ? ProfileStrings.appLockSub : ProfileStrings.appLockUnavailable,
      value: lock.enabled,
      onChanged: available ? ref.read(appLockProvider.notifier).setEnabled : null,
    );
  }
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet();

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final ok = await ref.read(problemReporterProvider).send(
      ProblemReport(
        description: _text.text.trim(),
        appVersion: AppConfig.version,
        platform: defaultTargetPlatform.name,
      ),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    showInfoSnack(context, ok ? ProfileStrings.reportSent : ProfileStrings.reportFailed);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(ProfileStrings.report, style: context.text.headline),
      const SizedBox(height: AppSpacing.xs),
      Text(
        ProfileStrings.reportBody,
        style: context.text.body.copyWith(color: context.colors.inkSecondary),
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        label: ProfileStrings.reportField,
        controller: _text,
        maxLines: 5,
        onChanged: (_) => setState(() {}),
        textCapitalization: TextCapitalization.sentences,
      ),
      const SizedBox(height: AppSpacing.lg),
      AppButton(
        label: ProfileStrings.reportSend,
        loading: _sending,
        onPressed: _text.text.trim().isEmpty ? null : _send,
      ),
    ],
  );
}
