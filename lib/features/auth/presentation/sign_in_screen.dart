import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/routes.dart';
import '../../../core/config/demo_info.dart';
import '../../../core/error/failure.dart';
import '../../../core/state/action_controller.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../application/session_controller.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_rules.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  Map<String, String> _local = const {};

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    ref.read(sessionControllerProvider.notifier).dismissNotice();
    setState(() {
      _local = {
        AuthFields.email: ?AuthRules.email(_email.text),
        if (_password.text.isEmpty) AuthFields.password: 'Saisissez votre mot de passe.',
      };
    });
    if (_local.isNotEmpty) return;
    // On success the router leaves this screen by itself.
    await ref.read(signInControllerProvider.notifier).submit(_email.text, _password.text);
  }

  void _fill(String email, String password) {
    _email.text = email;
    _password.text = password;
    setState(() => _local = const {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInControllerProvider);
    final notice = ref.watch(sessionControllerProvider).endedNotice;
    final demo = ref.watch(demoInfoProvider);
    final failure = state is ActionFailed<AuthResult> ? state.failure : null;
    final server = failure is ValidationFailure ? failure.fieldErrors : const <String, String>{};
    String? error(String f) => _local[f] ?? server[f];
    final banner = failure != null && (failure is! ValidationFailure || server.isEmpty)
        ? failure
        : notice;
    final c = context.colors;
    final t = context.text;
    return PageScaffold(
      title: '',
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            0,
            AppSpacing.gutter,
            AppSpacing.xxl,
          ),
          children: [
            Semantics(header: true, child: Text(AuthStrings.signInTitle, style: t.title)),
            const SizedBox(height: AppSpacing.xs),
            Text(AuthStrings.signInBody, style: t.body.copyWith(color: c.inkSecondary)),
            const SizedBox(height: AppSpacing.xl),
            if (banner != null) ...[
              InlineNotice(message: '${banner.title}. ${banner.message}', danger: true),
              const SizedBox(height: AppSpacing.md),
            ],
            AppTextField(
              label: AuthStrings.email,
              hint: AuthStrings.emailHint,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email, AutofillHints.username],
              textInputAction: TextInputAction.next,
              error: error(AuthFields.email),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: AuthStrings.password,
              controller: _password,
              obscure: true,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              error: error(AuthFields.password),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextLink(
                label: AuthStrings.forgotPassword,
                onPressed: () => context.push(Routes.forgotPassword),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: AuthStrings.signIn, loading: state.isRunning, onPressed: _submit),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(AuthStrings.noAccount, style: t.small.copyWith(color: c.inkSecondary)),
                TextLink(
                  label: AuthStrings.signUpLink,
                  onPressed: () => context.pushReplacement(Routes.signUp),
                ),
              ],
            ),
            if (demo != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                color: c.primarySoft,
                bordered: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AuthStrings.demoTitle, style: t.bodyStrong),
                    Text(AuthStrings.demoBody, style: t.small.copyWith(color: c.inkSecondary)),
                    const SizedBox(height: AppSpacing.xs),
                    for (final email in demo.accounts)
                      AppListTile(
                        icon: Icons.person_outline_rounded,
                        iconBackground: c.surface,
                        title: email,
                        subtitle: '${AuthStrings.password}: ${demo.password}',
                        onTap: () => _fill(email, demo.password),
                      ),
                    for (final hint in demo.hints)
                      Text(hint, style: t.caption.copyWith(color: c.inkSecondary)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
