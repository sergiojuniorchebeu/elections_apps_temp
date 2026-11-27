import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/routes.dart';
import '../../../core/error/failure.dart';
import '../../../core/state/action_controller.dart';
import '../../../core/utils/formats.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../auth/auth.dart';
import '../../profile/profile.dart';
import '../application/petitions_providers.dart';
import '../domain/petition.dart';

/// Signing a petition: the member's saved signature is written on the
/// petition sheet, pen in hand, while the request runs. No saved
/// signature yet: they draw one first (Profile > My signature), then
/// signing goes on.
Future<void> startPetitionSigning(BuildContext context, WidgetRef ref, Petition petition) async {
  Signature? signature;
  try {
    signature = await ref.read(signatureProvider.future);
  } on Object catch (e) {
    if (context.mounted) showFailureSnack(context, Failure.from(e));
    return;
  }
  if (!context.mounted) return;
  if (signature == null) {
    final create = await showAppSheet<bool>(context, builder: (_) => const _NeedSignature());
    if (create != true || !context.mounted) return;
    signature = await context.push<Signature>(Routes.signatureThenBack);
    if (signature == null || !context.mounted) return;
  }
  ref.read(signControllerProvider(petition.id).notifier).reset();
  await showAppSheet<void>(
    context,
    dismissible: false,
    builder: (_) => PetitionSignSheet(petition: petition, signature: signature!),
  );
}

class _NeedSignature extends StatelessWidget {
  const _NeedSignature();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _PenBadge(),
      const SizedBox(height: AppSpacing.md),
      Text(
        PetitionSignStrings.needSignature,
        textAlign: TextAlign.center,
        style: context.text.headline,
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        PetitionSignStrings.needSignatureBody,
        textAlign: TextAlign.center,
        style: context.text.body.copyWith(color: context.colors.inkSecondary),
      ),
      const SizedBox(height: AppSpacing.lg),
      AppButton(
        label: PetitionSignStrings.createSignature,
        icon: AppIcons.pen,
        onPressed: () => Navigator.pop(context, true),
      ),
      const SizedBox(height: AppSpacing.xs),
      AppButton(
        label: CommonStrings.cancel,
        variant: AppButtonVariant.secondary,
        onPressed: () => Navigator.pop(context, false),
      ),
    ],
  );
}

/// The pen drawing in a soft circle.
class _PenBadge extends StatelessWidget {
  const _PenBadge();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: AppSizes.touch * 1.5,
      height: AppSizes.touch * 1.5,
      decoration: BoxDecoration(color: context.colors.primarySoft, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: AppIcon(AppIcons.pen, size: AppSizes.iconLg, color: context.colors.primary),
    ),
  );
}

class PetitionSignSheet extends ConsumerStatefulWidget {
  const PetitionSignSheet({super.key, required this.petition, required this.signature});

  final Petition petition;
  final Signature signature;

  @override
  ConsumerState<PetitionSignSheet> createState() => _PetitionSignSheetState();
}

class _PetitionSignSheetState extends ConsumerState<PetitionSignSheet> {
  /// The pen is moving.
  bool _writing = false;
  bool _written = false;
  Failure? _failure;
  bool _signed = false;

  Future<void> _sign() async {
    setState(() {
      _writing = true;
      _written = false;
      _failure = null;
    });
    final result = await ref.read(signControllerProvider(widget.petition.id).notifier).sign();
    if (!mounted) return;
    if (result == null) {
      final state = ref.read(signControllerProvider(widget.petition.id));
      HapticFeedback.heavyImpact();
      setState(() {
        _writing = false;
        _failure = state is ActionFailed<Petition> ? state.failure : const UnknownFailure();
      });
      return;
    }
    setState(() => _signed = true);
    _maybeDone();
  }

  void _onWritten() {
    _written = true;
    _maybeDone();
  }

  /// Shown as done only when both the pen and the server have finished.
  void _maybeDone() {
    if (!_signed || !_written || !mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _writing = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final done = _signed && _written;
    final running = _writing && !done;
    final name = ref.watch(currentUserProvider).value?.fullName;
    return PopScope(
      canPop: !running,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            done ? PetitionSignStrings.done : PetitionSignStrings.title,
            style: t.headline,
          ),
          const SizedBox(height: AppSpacing.md),
          // The petition sheet the signature is written on.
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AppIcon(AppIcons.petitions, size: AppSizes.iconSm, color: c.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        (widget.petition.category ?? CivicStrings.petitions).toUpperCase(),
                        style: t.overline.copyWith(color: c.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(widget.petition.title, style: t.subtitle),
                const SizedBox(height: AppSpacing.md),
                Text(PetitionSignStrings.signHere, style: t.caption.copyWith(color: c.inkSecondary)),
                const SizedBox(height: AppSpacing.xxs),
                Stack(
                  children: [
                    Positioned.fill(
                      child: Align(
                        alignment: const Alignment(0, 0.56),
                        child: Divider(color: c.border, height: 1),
                      ),
                    ),
                    Semantics(
                      label: done && name != null ? PetitionSignStrings.by(name) : null,
                      child: SignatureView(
                        signature: widget.signature,
                        hidden: true,
                        animate: _writing || done,
                        onDone: _onWritten,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.small.copyWith(color: c.inkSecondary),
                      ),
                    ),
                    Text(
                      Formats.date(DateTime.now()),
                      style: t.small.copyWith(color: c.inkSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (done)
            InlineNotice(message: PetitionSignStrings.doneBody, icon: Icons.check_circle_outline_rounded)
          else if (_failure != null)
            InlineNotice(message: '${_failure!.title}. ${_failure!.message}', danger: true)
          else
            Text(
              running ? PetitionSignStrings.signing : PetitionSignStrings.warning,
              textAlign: TextAlign.center,
              style: t.small.copyWith(color: c.inkSecondary),
            ),
          const SizedBox(height: AppSpacing.lg),
          if (done)
            AppButton(
              label: PetitionSignStrings.close,
              onPressed: () => Navigator.pop(context),
            )
          else ...[
            AppButton(
              label: PetitionSignStrings.sign,
              icon: AppIcons.pen,
              loading: running,
              onPressed: _sign,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              label: CommonStrings.cancel,
              variant: AppButtonVariant.ghost,
              onPressed: running ? null : () => Navigator.pop(context),
            ),
          ],
        ],
      ),
    );
  }
}
