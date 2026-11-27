import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/error/failure.dart';
import '../../../core/state/action_controller.dart';
import '../../../core/state/connectivity.dart';
import '../../../core/utils/formats.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../application/identity_providers.dart';
import '../domain/citizen_id.dart';
import '../domain/identity_rules.dart';

/// "Manage": registry data (read-only) and contact details (editable).
class PersonalDetailsScreen extends ConsumerWidget {
  const PersonalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(citizenIdProvider);
    return PageScaffold(
      title: IdStrings.detailsTitle,
      body: AsyncView(
        value: id,
        onRetry: () => ref.invalidate(citizenIdProvider),
        skeleton: const Padding(
          padding: EdgeInsets.all(AppSpacing.gutter),
          child: SkeletonList(),
        ),
        data: (c) => _DetailsForm(citizen: c),
      ),
    );
  }
}

class _DetailsForm extends ConsumerStatefulWidget {
  const _DetailsForm({required this.citizen});
  final CitizenId citizen;

  @override
  ConsumerState<_DetailsForm> createState() => _DetailsFormState();
}

class _DetailsFormState extends ConsumerState<_DetailsForm> {
  late final _phone = TextEditingController(text: widget.citizen.phone ?? '');
  late final _address = TextEditingController(text: widget.citizen.address ?? '');
  Map<String, String> _local = const {};

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final update = ContactUpdate(phone: _phone.text, address: _address.text);
    setState(() => _local = IdentityRules.contact(update));
    if (_local.isNotEmpty) return;
    final saved = await ref.read(contactControllerProvider.notifier).submit(update);
    if (saved != null && mounted) {
      showInfoSnack(context, IdStrings.detailsSaved);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactControllerProvider);
    final online = ref.watch(connectivityProvider).online;
    final failure = state is ActionFailed<CitizenId> ? state.failure : null;
    final server = failure is ValidationFailure ? failure.fieldErrors : const <String, String>{};
    String? error(String f) => _local[f] ?? server[f];
    final c = widget.citizen;
    final t = context.text;
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xs,
        AppSpacing.gutter,
        AppSpacing.xxl,
      ),
      children: [
        Text(IdStrings.detailsIdentity, style: t.label.copyWith(color: colors.inkSecondary)),
        const SizedBox(height: AppSpacing.xs),
        AppCard(
          child: Column(
            children: [
              KeyValueRow(label: IdStrings.fullName, value: c.fullName),
              KeyValueRow(label: IdStrings.dateOfBirth, value: Formats.date(c.dateOfBirth)),
              KeyValueRow(label: IdStrings.citizenNumber, value: '•••• ${Formats.masked(c.numberLast4)}'),
              KeyValueRow(label: IdStrings.email, value: c.email),
              KeyValueRow(label: IdStrings.issued, value: Formats.date(c.issuedAt)),
              KeyValueRow(label: IdStrings.expires, value: Formats.date(c.expiresAt)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(IdStrings.detailsIdentityNote, style: t.small.copyWith(color: colors.inkSecondary)),
        const SizedBox(height: AppSpacing.xl),
        Text(IdStrings.detailsContact, style: t.label.copyWith(color: colors.inkSecondary)),
        const SizedBox(height: AppSpacing.xs),
        AppTextField(
          label: IdStrings.phone,
          controller: _phone,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          textInputAction: TextInputAction.next,
          error: error(IdentityFields.phone),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: IdStrings.address,
          controller: _address,
          maxLines: 3,
          keyboardType: TextInputType.streetAddress,
          autofillHints: const [AutofillHints.fullStreetAddress],
          error: error(IdentityFields.address),
        ),
        if (failure != null && failure is! ValidationFailure ||
            failure is ValidationFailure && failure.fieldErrors.isEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          InlineNotice(message: '${failure!.title}. ${failure.message}', danger: true),
        ],
        if (!online) ...[
          const SizedBox(height: AppSpacing.md),
          const InlineNotice(message: CommonStrings.offlineWritesDisabled, icon: Icons.wifi_off_rounded),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: CommonStrings.save,
          loading: state.isRunning,
          onPressed: online ? _save : null,
        ),
      ],
    );
  }
}
