import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/routes.dart';
import '../../../core/error/failure.dart';
import '../../../core/state/action_controller.dart';
import '../../../core/state/connectivity.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/detail_parts.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/paged_list.dart';
import '../application/services_providers.dart';
import '../domain/public_service.dart';

IconData _icon(ServiceCategory c) => switch (c) {
  ServiceCategory.identity => AppIcons.identity,
  ServiceCategory.family => Icons.family_restroom_outlined,
  ServiceCategory.housing => Icons.home_outlined,
  ServiceCategory.transport => Icons.directions_bus_outlined,
  ServiceCategory.tax => Icons.receipt_long_outlined,
  ServiceCategory.other => Icons.account_balance_outlined,
};

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(servicesProvider);
    final notifier = ref.read(servicesProvider.notifier);
    return PageScaffold(
      title: ServiceStrings.title,
      body: PagedList<PublicService>(
        state: state,
        onRefresh: notifier.refresh,
        onLoadMore: notifier.loadMore,
        empty: const StateView(
          icon: AppIcons.services,
          title: ServiceStrings.emptyTitle,
          message: ServiceStrings.emptyBody,
        ),
        itemBuilder: (context, s) => AppCard(
          padding: EdgeInsets.zero,
          onTap: () => context.push(Routes.service(s.id)),
          child: AppListTile(
            icon: _icon(s.category),
            title: s.title,
            subtitle:
                '${s.online ? ServiceStrings.online : ServiceStrings.inPerson} · ${ServiceStrings.processing(s.processingDays)}',
            trailing: Icon(Icons.chevron_right_rounded, color: context.colors.inkTertiary),
          ),
        ),
      ),
    );
  }
}

class ServiceScreen extends ConsumerWidget {
  const ServiceScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(serviceProvider(id));
    return PageScaffold(
      title: ServiceStrings.title,
      body: AsyncView(
        value: service,
        onRetry: () => ref.invalidate(serviceProvider(id)),
        skeleton: const Padding(
          padding: EdgeInsets.all(AppSpacing.gutter),
          child: SkeletonList(count: 3),
        ),
        data: (s) => _ServiceBody(service: s),
      ),
    );
  }
}

class _ServiceBody extends ConsumerStatefulWidget {
  const _ServiceBody({required this.service});
  final PublicService service;

  @override
  ConsumerState<_ServiceBody> createState() => _ServiceBodyState();
}

class _ServiceBodyState extends ConsumerState<_ServiceBody> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final c = context.colors;
    final t = context.text;
    final state = ref.watch(requestControllerProvider(s.id));
    final online = ref.watch(connectivityProvider).online;
    final failure = state is ActionFailed<ServiceRequest> ? state.failure : null;
    final noteError = failure is ValidationFailure ? failure.errorFor(ServiceFields.note) : null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xs,
        AppSpacing.gutter,
        AppSpacing.xxl,
      ),
      children: [
        AppIcon(_icon(s.category), color: c.primary, size: AppSizes.iconLg * 1.4),
        const SizedBox(height: AppSpacing.sm),
        DetailHeader(
          title: s.title,
          pill: StatusPill(
            dense: true,
            label: s.online ? ServiceStrings.online : ServiceStrings.inPerson,
            icon: s.online ? Icons.phone_iphone_rounded : Icons.storefront_outlined,
            background: c.primarySoft,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(s.description, style: t.body),
        const SizedBox(height: AppSpacing.xs),
        Text(
          ServiceStrings.processing(s.processingDays),
          style: t.small.copyWith(color: c.inkSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (state case ActionSucceeded(:final value))
          StateView(
            icon: Icons.check_circle_outline_rounded,
            title: ServiceStrings.requestSent,
            message: ServiceStrings.requestReference(value.reference),
            actionLabel: CommonStrings.done,
            onAction: () => context.pop(),
          )
        else if (!s.online)
          const InlineNotice(message: ServiceStrings.inPersonBody, icon: Icons.storefront_outlined)
        else ...[
          AppTextField(
            label: ServiceStrings.note,
            hint: ServiceStrings.noteHint,
            controller: _note,
            maxLines: 4,
            error: noteError,
            textCapitalization: TextCapitalization.sentences,
          ),
          if (failure != null && noteError == null) ...[
            const SizedBox(height: AppSpacing.md),
            InlineNotice(message: '${failure.title}. ${failure.message}', danger: true),
          ],
          if (!online) ...[
            const SizedBox(height: AppSpacing.md),
            const InlineNotice(message: CommonStrings.offlineWritesDisabled, icon: Icons.wifi_off_rounded),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: ServiceStrings.request,
            loading: state.isRunning,
            onPressed: online
                ? () => ref.read(requestControllerProvider(s.id).notifier).submit(_note.text)
                : null,
          ),
        ],
      ],
    );
  }
}
