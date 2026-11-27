import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/routes.dart';
import '../../../core/state/action_controller.dart';
import '../../../core/utils/formats.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/detail_parts.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/paged_list.dart';
import '../application/elections_providers.dart';
import '../domain/election.dart';

class ElectionsScreen extends ConsumerWidget {
  const ElectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(electionsProvider);
    final notifier = ref.read(electionsProvider.notifier);
    return PageScaffold(
      title: CivicStrings.elections,
      body: PagedList<Election>(
        state: state,
        onRefresh: notifier.refresh,
        onLoadMore: notifier.loadMore,
        groupBy: (e) => e.status == ElectionStatus.closed
            ? CivicStrings.past
            : CivicStrings.upcoming,
        empty: const StateView(
          icon: AppIcons.elections,
          title: CivicStrings.electionsEmpty,
          message: CivicStrings.electionsEmptyBody,
        ),
        itemBuilder: (context, e) => _ElectionTile(election: e),
      ),
    );
  }
}

class _ElectionTile extends StatelessWidget {
  const _ElectionTile({required this.election});
  final Election election;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final closed = election.status == ElectionStatus.closed;
    return AppCard(
      onTap: () => context.push(Routes.election(election.id)),
      semanticLabel: '${election.title}, ${Formats.longDay(election.date)}',
      child: ExcludeSemantics(
        child: Row(
          children: [
            DateTile(
              month: Formats.monthShort(election.date),
              day: Formats.day(election.date),
              muted: closed,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(election.title, style: context.text.subtitle),
                  Text(
                    '${ElectionScreen.levelLabel(election.level)} · ${election.date.year}',
                    style: context.text.small.copyWith(color: c.inkSecondary),
                  ),
                ],
              ),
            ),
            if (election.reminderSet)
              Icon(Icons.notifications_active_outlined, color: c.primary, size: AppSizes.iconSm),
            Icon(Icons.chevron_right_rounded, color: c.inkTertiary),
          ],
        ),
      ),
    );
  }
}

class ElectionScreen extends ConsumerWidget {
  const ElectionScreen({super.key, required this.id});
  final String id;

  static String levelLabel(ElectionLevel l) => switch (l) {
    ElectionLevel.municipal => CivicStrings.municipal,
    ElectionLevel.regional => CivicStrings.regional,
    ElectionLevel.national => CivicStrings.national,
    ElectionLevel.referendum => CivicStrings.referendumLevel,
    ElectionLevel.unknown => CivicStrings.election,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final election = ref.watch(electionProvider(id));
    final title = election.value?.title ?? CivicStrings.elections;
    return PageScaffold(
      title: title,
      body: AsyncView(
        value: election,
        onRetry: () => ref.invalidate(electionProvider(id)),
        skeleton: const Padding(
          padding: EdgeInsets.all(AppSpacing.gutter),
          child: SkeletonList(count: 4),
        ),
        data: (e) => _ElectionBody(election: e),
      ),
    );
  }
}

class _ElectionBody extends ConsumerWidget {
  const _ElectionBody({required this.election});
  final Election election;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final e = election;
    final action = ref.watch(reminderControllerProvider(e.id));
    final closed = e.status == ElectionStatus.closed;
    ref.listen(reminderControllerProvider(e.id), (_, next) {
      switch (next) {
        case ActionFailed(:final failure):
          showFailureSnack(context, failure);
        case ActionSucceeded(:final value):
          showInfoSnack(
            context,
            value.reminderSet ? CivicStrings.reminderOn : CivicStrings.reminderOff,
          );
        default:
      }
    });
    return RefreshIndicator.adaptive(
      onRefresh: () async {
        final f = await ref.read(electionProvider(e.id).notifier).refresh();
        if (f != null && context.mounted) showFailureSnack(context, f);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.xs,
          AppSpacing.gutter,
          AppSpacing.xxl,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DateTile(
                month: Formats.monthShort(e.date),
                day: Formats.day(e.date),
                muted: closed,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DetailHeader(
                  overline: ElectionScreen.levelLabel(e.level).toUpperCase(),
                  title: e.title,
                  pill: closed
                      ? StatusPill(
                          label: CivicStrings.closed,
                          icon: Icons.lock_outline_rounded,
                          foreground: c.inkSecondary,
                          background: c.surfaceMuted,
                        )
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(Formats.longDay(e.date), style: t.bodyStrong),
          const SizedBox(height: AppSpacing.xs),
          Text(e.description, style: t.body.copyWith(color: c.inkSecondary)),
          const SectionLabel(CivicStrings.pollingStation),
          AppCard(
            padding: EdgeInsets.zero,
            child: AppListTile(
              icon: Icons.place_outlined,
              title: e.pollingStation ?? CivicStrings.notRegistered,
            ),
          ),
          SectionLabel(
            e.level == ElectionLevel.referendum
                ? CivicStrings.referendum
                : CivicStrings.candidates,
          ),
          if (e.candidates.isEmpty)
            Text(e.description, style: t.small.copyWith(color: c.inkSecondary))
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < e.candidates.length; i++) ...[
                    if (i > 0) const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
                    AppListTile(
                      icon: Icons.person_outline_rounded,
                      title: e.candidates[i].name,
                      subtitle: e.candidates[i].party ?? CivicStrings.independent,
                    ),
                  ],
                ],
              ),
            ),
          if (!closed) ...[
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile.adaptive(
                value: e.reminderSet,
                title: Text(CivicStrings.reminder, style: t.body),
                onChanged: action.isRunning
                    ? null
                    : ref.read(reminderControllerProvider(e.id).notifier).toggle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
