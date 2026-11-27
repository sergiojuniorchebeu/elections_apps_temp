import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/error/failure.dart';
import '../../../core/state/action_controller.dart';
import '../../../core/state/connectivity.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../application/signature_providers.dart';
import '../domain/signature.dart';
import 'signature_widgets.dart';

/// Profile > My signature: draw, save, redo or delete it.
///
/// Opened from a petition ([returnOnSave]), it closes once saved and
/// hands the signature back, so signing goes on.
class SignatureScreen extends ConsumerStatefulWidget {
  const SignatureScreen({super.key, this.returnOnSave = false});

  final bool returnOnSave;

  @override
  ConsumerState<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends ConsumerState<SignatureScreen> {
  final _pad = SignaturePadController();
  bool _editing = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _pad.addListener(_onDraw);
  }

  void _onDraw() {
    if (_localError != null) setState(() => _localError = null);
    setState(() {}); // Save button follows emptiness.
  }

  @override
  void dispose() {
    _pad.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final signature = _pad.toSignature();
    final error = SignatureRules.validate(signature);
    if (error != null) {
      setState(() => _localError = error);
      return;
    }
    final saved = await ref.read(saveSignatureControllerProvider.notifier).save(signature);
    if (saved == null || !mounted) return;
    showInfoSnack(context, SignatureStrings.saved);
    if (widget.returnOnSave) {
      context.pop(saved);
    } else {
      setState(() => _editing = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: SignatureStrings.deleteConfirmTitle,
      message: SignatureStrings.deleteConfirmBody,
      confirmLabel: SignatureStrings.delete,
      destructive: true,
    );
    if (!ok) return;
    final done = await ref.read(saveSignatureControllerProvider.notifier).delete();
    if (done && mounted) {
      _pad.clear();
      showInfoSnack(context, SignatureStrings.deleted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(signatureProvider);
    final action = ref.watch(saveSignatureControllerProvider);
    final online = ref.watch(connectivityProvider).online;
    final failure = action is ActionFailed<Signature> ? action.failure : null;
    final serverError = failure is ValidationFailure
        ? failure.fieldErrors[SignatureRules.field]
        : null;
    ref.listen(saveSignatureControllerProvider, (_, next) {
      if (next case ActionFailed(:final failure)
          when failure is! ValidationFailure ||
              failure.fieldErrors[SignatureRules.field] == null) {
        showFailureSnack(context, failure);
      }
    });
    final saved = value.value;
    final drawing = _editing || (value.hasValue && saved == null);
    return PageScaffold(
      title: SignatureStrings.title,
      bottom: !value.hasValue
          ? null
          : drawing
          ? AppButton(
              label: SignatureStrings.save,
              icon: AppIcons.pen,
              loading: action.isRunning,
              onPressed: _pad.isEmpty || !online ? null : _save,
            )
          : AppButton(
              label: SignatureStrings.redo,
              variant: AppButtonVariant.secondary,
              onPressed: () => setState(() {
                _pad.clear();
                _editing = true;
              }),
            ),
      body: AsyncView<Signature?>(
        value: value,
        onRetry: () => ref.invalidate(signatureProvider),
        skeleton: const Padding(
          padding: EdgeInsets.all(AppSpacing.gutter),
          child: SkeletonList(count: 2),
        ),
        data: (saved) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.xs,
            AppSpacing.gutter,
            AppSpacing.xl,
          ),
          children: [
            Text(
              SignatureStrings.body,
              style: context.text.body.copyWith(color: context.colors.inkSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (drawing) ...[
              SignaturePad(controller: _pad, error: _localError ?? serverError),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.md,
                children: [
                  TextLink(
                    label: SignatureStrings.undo,
                    onPressed: _pad.isEmpty ? null : _pad.undo,
                  ),
                  TextLink(
                    label: SignatureStrings.clear,
                    onPressed: _pad.isEmpty ? null : _pad.clear,
                  ),
                ],
              ),
            ] else if (saved != null) ...[
              AppCard(
                child: Semantics(
                  label: SignatureStrings.savedOn,
                  child: SignatureView(signature: saved),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextLink(
                  label: SignatureStrings.delete,
                  onPressed: action.isRunning || !online ? null : _delete,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
