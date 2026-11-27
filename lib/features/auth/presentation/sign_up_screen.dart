import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/routes.dart';
import '../../../core/error/failure.dart';
import '../../../core/state/action_controller.dart';
import '../../../core/utils/formats.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../application/session_controller.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_rules.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _dobText = TextEditingController();
  DateTime? _dob;
  bool _terms = false;
  Map<String, String> _local = const {};

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _password, _dobText]) {
      c.dispose();
    }
    super.dispose();
  }

  SignUpRequest get _request => SignUpRequest(
    firstName: _first.text,
    lastName: _last.text,
    email: _email.text,
    password: _password.text,
    dateOfBirth: _dob,
    acceptedTerms: _terms,
  );

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked == null) return;
    setState(() {
      _dob = picked;
      _dobText.text = Formats.date(picked);
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final errors = AuthRules.signUp(_request, DateTime.now());
    setState(() => _local = errors);
    if (errors.isNotEmpty) return;
    await ref.read(signUpControllerProvider.notifier).submit(_request);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signUpControllerProvider);
    final failure = state is ActionFailed<AuthResult> ? state.failure : null;
    final server = failure is ValidationFailure ? failure.fieldErrors : const <String, String>{};
    String? error(String f) => _local[f] ?? server[f];
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
            Semantics(header: true, child: Text(AuthStrings.signUpTitle, style: t.title)),
            const SizedBox(height: AppSpacing.xs),
            Text(AuthStrings.signUpBody, style: t.body.copyWith(color: c.inkSecondary)),
            const SizedBox(height: AppSpacing.xl),
            if (failure != null && server.isEmpty) ...[
              InlineNotice(message: '${failure.title}. ${failure.message}', danger: true),
              const SizedBox(height: AppSpacing.md),
            ],
            AppTextField(
              label: AuthStrings.firstName,
              controller: _first,
              autofillHints: const [AutofillHints.givenName],
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              error: error(AuthFields.firstName),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: AuthStrings.lastName,
              controller: _last,
              autofillHints: const [AutofillHints.familyName],
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              error: error(AuthFields.lastName),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: AuthStrings.dateOfBirth,
              hint: AuthStrings.dateOfBirthHint,
              controller: _dobText,
              readOnly: true,
              onTap: _pickDate,
              suffixIcon: Icons.calendar_today_outlined,
              error: error(AuthFields.dateOfBirth),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: AuthStrings.email,
              hint: AuthStrings.emailHint,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              error: error(AuthFields.email),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: AuthStrings.password,
              controller: _password,
              obscure: true,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              error: error(AuthFields.password),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCheckRow(
              value: _terms,
              label: AuthStrings.terms,
              error: error(AuthFields.acceptedTerms),
              onChanged: (v) => setState(() => _terms = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: AuthStrings.signUp, loading: state.isRunning, onPressed: _submit),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(AuthStrings.haveAccountLink, style: t.small.copyWith(color: c.inkSecondary)),
                TextLink(
                  label: AuthStrings.signIn,
                  onPressed: () => context.pushReplacement(Routes.signIn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
