import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/error/failure.dart';
import '../../../core/security/secure_screen.dart';
import '../../../core/services/services.dart';
import '../../../core/state/action_controller.dart';
import '../../../core/utils/formats.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/failure_view.dart';
import '../application/identity_providers.dart';
import '../domain/citizen_id.dart';

// ------------------------------------------------------------- show code

/// Shows the QR code. When biometric protection is on (and available),
/// the user must authenticate first.
Future<void> showCodeSheet(BuildContext context, WidgetRef ref) async {
  final citizen = ref.read(citizenIdProvider).value;
  final auth = ref.read(deviceAuthenticatorProvider);
  if (citizen?.biometricProtection ?? false) {
    if (await auth.isAvailable()) {
      final ok = await auth.authenticate(IdStrings.unlockToShow);
      if (!ok) return;
    }
  }
  if (!context.mounted) return;
  await showAppSheet<void>(context, builder: (_) => const _CodeSheet());
}

class _CodeSheet extends ConsumerStatefulWidget {
  const _CodeSheet();

  @override
  ConsumerState<_CodeSheet> createState() => _CodeSheetState();
}

class _CodeSheetState extends ConsumerState<_CodeSheet> {
  Timer? _tick;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = ref.watch(presentationCodeProvider);
    final c = context.colors;
    final t = context.text;
    return SecureScreen(
      hidden: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(IdStrings.codeHidden, textAlign: TextAlign.center, style: t.body),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(IdStrings.codeTitle, style: t.headline),
          const SizedBox(height: AppSpacing.xs),
          Text(
            IdStrings.codeBody,
            textAlign: TextAlign.center,
            style: t.body.copyWith(color: c.inkSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          switch (code) {
            AsyncValue(:final value?) => () {
              final left = value.expiresAt.difference(_now).inSeconds;
              final expired = left <= 0;
              return Column(
                children: [
                  Opacity(
                    opacity: expired ? 0.15 : 1,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        // A QR code must stay dark on light to be read.
                        color: AppColors.light.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: c.border),
                      ),
                      child: Semantics(
                        label: IdStrings.codeTitle,
                        image: true,
                        child: QrImageView(
                          data: value.payload,
                          size: AppSizes.mascot * 1.8,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.light.ink,
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.light.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    expired ? IdStrings.codeExpired : IdStrings.codeExpiresIn(left),
                    style: t.number.copyWith(color: c.inkSecondary),
                  ),
                  if (expired) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: IdStrings.newCode,
                      icon: Icons.refresh_rounded,
                      onPressed: () => ref.invalidate(presentationCodeProvider),
                    ),
                  ],
                ],
              );
            }(),
            AsyncValue(:final error?) => FailureView(
              failure: Failure.from(error),
              onRetry: () => ref.invalidate(presentationCodeProvider),
            ),
            _ => const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: CircularProgressIndicator.adaptive(),
            ),
          },
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- share

Future<void> showShareSheet(BuildContext context) =>
    showAppSheet<void>(context, builder: (_) => const _ShareSheet());

class _ShareSheet extends ConsumerStatefulWidget {
  const _ShareSheet();

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  final Set<SharedField> _fields = {SharedField.fullName, SharedField.verificationStatus};

  static String label(SharedField f) => switch (f) {
    SharedField.fullName => IdStrings.shareFullName,
    SharedField.dateOfBirth => IdStrings.shareDob,
    SharedField.verificationStatus => IdStrings.shareStatus,
    SharedField.address => IdStrings.shareAddress,
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shareControllerProvider);
    final c = context.colors;
    final t = context.text;
    if (state case ActionSucceeded(:final value)) {
      return SecureScreen(
        hidden: Text(IdStrings.codeHidden, style: t.body),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.check_circle_rounded, color: c.success, size: AppSizes.iconLg * 1.5),
            const SizedBox(height: AppSpacing.sm),
            Text(IdStrings.linkReady, textAlign: TextAlign.center, style: t.headline),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              color: c.background,
              child: Column(
                children: [
                  SelectableText(value.code, style: t.title.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(value.url, textAlign: TextAlign.center, style: t.small.copyWith(color: c.inkSecondary)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              IdStrings.validUntil('${Formats.date(value.expiresAt)}, ${Formats.time(value.expiresAt)}'),
              textAlign: TextAlign.center,
              style: t.small.copyWith(color: c.inkSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: IdStrings.copyLink,
              icon: Icons.copy_rounded,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: value.url));
                if (context.mounted) showInfoSnack(context, CommonStrings.copied);
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              label: CommonStrings.done,
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(IdStrings.shareTitle, style: t.headline),
        const SizedBox(height: AppSpacing.xs),
        Text(IdStrings.shareBody, style: t.body.copyWith(color: c.inkSecondary)),
        const SizedBox(height: AppSpacing.md),
        for (final f in SharedField.values)
          AppCheckRow(
            value: _fields.contains(f),
            label: label(f),
            onChanged: (v) => setState(() => v ? _fields.add(f) : _fields.remove(f)),
          ),
        if (state case ActionFailed(:final failure)) ...[
          const SizedBox(height: AppSpacing.sm),
          InlineNotice(message: '${failure.title}. ${failure.message}', danger: true),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: IdStrings.createLink,
          loading: state.isRunning,
          onPressed: _fields.isEmpty
              ? null
              : () => ref.read(shareControllerProvider.notifier).submit({..._fields}),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- verify

Future<void> showVerifySheet(BuildContext context) =>
    showAppSheet<void>(context, builder: (_) => const _VerifySheet());

class _VerifySheet extends ConsumerStatefulWidget {
  const _VerifySheet();

  @override
  ConsumerState<_VerifySheet> createState() => _VerifySheetState();
}

class _VerifySheetState extends ConsumerState<_VerifySheet> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() => ref.read(verifyControllerProvider.notifier).submit(_code.text);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verifyControllerProvider);
    final scanner = ref.watch(qrScannerProvider);
    final c = context.colors;
    final t = context.text;
    if (state case ActionSucceeded(:final value)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StateView(
            icon: value.valid ? Icons.verified_rounded : Icons.gpp_bad_outlined,
            tone: value.valid ? StateTone.neutral : StateTone.danger,
            title: value.valid ? IdStrings.verifyValid : IdStrings.verifyInvalid,
            message: value.valid
                ? '${value.fullName ?? ''}\n${IdStrings.verified}'
                : IdStrings.verifyInvalidBody,
          ),
          AppButton(
            label: IdStrings.verifyAnother,
            variant: AppButtonVariant.secondary,
            onPressed: () {
              _code.clear();
              ref.read(verifyControllerProvider.notifier).reset();
            },
          ),
        ],
      );
    }
    final failure = state is ActionFailed<VerificationResult> ? state.failure : null;
    final fieldError = failure is ValidationFailure
        ? failure.errorFor(IdentityFields.code) ?? failure.message
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(IdStrings.verifyTitle, style: t.headline),
        const SizedBox(height: AppSpacing.xs),
        Text(IdStrings.verifyBody, style: t.body.copyWith(color: c.inkSecondary)),
        const SizedBox(height: AppSpacing.md),
        if (scanner.isAvailable) ...[
          SizedBox(
            height: AppSizes.mascot * 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: scanner.build(context, (code) {
                _code.text = code;
                _submit();
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppTextField(
          label: IdStrings.verifyCode,
          hint: IdStrings.verifyHint,
          controller: _code,
          error: fieldError,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.characters,
          onSubmitted: (_) => _submit(),
        ),
        if (failure != null && failure is! ValidationFailure) ...[
          const SizedBox(height: AppSpacing.sm),
          InlineNotice(message: '${failure.title}. ${failure.message}', danger: true),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(label: IdStrings.verify, loading: state.isRunning, onPressed: _submit),
      ],
    );
  }
}

// ------------------------------------------------------------- biometric

Future<void> showBiometricSheet(BuildContext context) =>
    showAppSheet<void>(context, builder: (_) => const _BiometricSheet());

class _BiometricSheet extends ConsumerWidget {
  const _BiometricSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citizen = ref.watch(citizenIdProvider).value;
    final state = ref.watch(biometricProtectionControllerProvider);
    final auth = ref.watch(deviceAuthenticatorProvider);
    final available = ref.watch(_authAvailableProvider).value ?? false;
    final c = context.colors;
    final t = context.text;
    final enabled = citizen?.biometricProtection ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(IdStrings.biometric, style: t.headline),
        const SizedBox(height: AppSpacing.xs),
        Text(IdStrings.biometricBody, style: t.body.copyWith(color: c.inkSecondary)),
        const SizedBox(height: AppSpacing.md),
        if (!available)
          const InlineNotice(message: IdStrings.biometricUnavailable)
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile.adaptive(
              value: enabled,
              title: Text(IdStrings.biometricSwitch(auth.label), style: t.body),
              onChanged: state.isRunning
                  ? null
                  : (v) async {
                      // Turning protection off needs the owner's face too.
                      if (!v && !await auth.authenticate(IdStrings.unlockToShow)) return;
                      await ref.read(biometricProtectionControllerProvider.notifier).submit(v);
                    },
            ),
          ),
        if (state case ActionFailed(:final failure)) ...[
          const SizedBox(height: AppSpacing.sm),
          InlineNotice(message: '${failure.title}. ${failure.message}', danger: true),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: CommonStrings.done,
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

final _authAvailableProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(deviceAuthenticatorProvider).isAvailable(),
);
