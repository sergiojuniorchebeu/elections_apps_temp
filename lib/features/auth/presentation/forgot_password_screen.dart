import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/error/failure.dart';
import '../../../core/state/action_controller.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../application/session_controller.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_rules.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  String? _local;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _local = AuthRules.email(_email.text));
    if (_local != null) return;
    await ref.read(passwordResetControllerProvider.notifier).submit(_email.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordResetControllerProvider);
    final c = context.colors;
    final t = context.text;
    final failure = state is ActionFailed<void> ? state.failure : null;
    final fieldError = _local ??
        (failure is ValidationFailure ? failure.errorFor(AuthFields.email) : null);
    return PageScaffold(
      title: '',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          0,
          AppSpacing.gutter,
          AppSpacing.xxl,
        ),
        children: [
          if (state is ActionSucceeded<void>)
            StateView(
              icon: Icons.mark_email_read_outlined,
              title: AuthStrings.resetSentTitle,
              message: AuthStrings.resetSentBody,
              actionLabel: AuthStrings.backToSignIn,
              onAction: () => context.pop(),
            )
          else ...[
            Semantics(header: true, child: Text(AuthStrings.resetTitle, style: t.title)),
            const SizedBox(height: AppSpacing.xs),
            Text(AuthStrings.resetBody, style: t.body.copyWith(color: c.inkSecondary)),
            const SizedBox(height: AppSpacing.xl),
            if (failure != null && fieldError == null) ...[
              InlineNotice(message: '${failure.title}. ${failure.message}', danger: true),
              const SizedBox(height: AppSpacing.md),
            ],
            AppTextField(
              label: AuthStrings.email,
              hint: AuthStrings.emailHint,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              error: fieldError,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(label: AuthStrings.resetSend, loading: state.isRunning, onPressed: _submit),
          ],
        ],
      ),
    );
  }
}
