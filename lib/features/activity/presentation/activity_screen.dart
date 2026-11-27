import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formats.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/paged_list.dart';
import '../application/activity_providers.dart';
import '../domain/activity_entry.dart';

/// Activity tab: everything done with the ID, grouped by day, filterable.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  static String filterLabel(ActivityFilter f) => switch (f) {
    ActivityFilter.all => ActivityStrings.all,
    ActivityFilter.identity => ActivityStrings.identity,
    ActivityFilter.civic => ActivityStrings.civic,
    ActivityFilter.security => ActivityStrings.security,
    ActivityFilter.service => ActivityStrings.service,
  };

  static IconData iconOf(ActivityKind k) => switch (k) {
    ActivityKind.identity => AppIcons.identity,
    ActivityKind.civic => AppIcons.elections,
    ActivityKind.security => Icons.shield_outlined,
    ActivityKind.service => Icons.account_balance_outlined,
    ActivityKind.unknown => Icons.circle_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityProvider);
    final filter = ref.watch(activityFilterProvider);
    final notifier = ref.read(activityProvider.notifier);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: MaxWidth(
            child: PagedList<ActivityEntry>(
              state: state,
              onRefresh: notifier.refresh,
              onLoadMore: notifier.loadMore,
              bottomPadding: AppNavBar.bottomInset(context),
              groupBy: (e) => Formats.dayHeader(e.at),
              header: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.md,
                    AppSpacing.gutter,
                    AppSpacing.xs,
                  ),
                  child: Semantics(
                    header: true,
                    child: Text(ActivityStrings.title, style: context.text.title),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    0,
                    0,
                    AppSpacing.sm,
                  ),
                  child: AppSegmented<ActivityFilter>(
                    values: ActivityFilter.values,
                    selected: filter,
                    labelOf: filterLabel,
                    onChanged: ref.read(activityFilterProvider.notifier).select,
                  ),
                ),
              ],
              empty: const StateView(
                icon: Icons.timeline_rounded,
                title: ActivityStrings.emptyTitle,
                message: ActivityStrings.emptyBody,
              ),
              itemBuilder: (context, e) => _ActivityTile(entry: e),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.entry});
  final ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => showAppSheet<void>(context, builder: (_) => _ActivitySheet(entry: entry)),
      child: AppListTile(
        icon: ActivityScreen.iconOf(entry.kind),
        title: entry.title,
        subtitle: entry.detail,
        trailing: Text(
          Formats.time(entry.at),
          style: context.text.caption.copyWith(color: c.inkTertiary),
        ),
      ),
    );
  }
}

class _ActivitySheet extends StatelessWidget {
  const _ActivitySheet({required this.entry});
  final ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
              child: Icon(ActivityScreen.iconOf(entry.kind), color: c.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(entry.title, style: t.headline)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(entry.detail, style: t.body),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          color: c.background,
          child: Column(
            children: [
              KeyValueRow(
                label: ActivityStrings.when,
                value: '${Formats.date(entry.at)}, ${Formats.time(entry.at)}',
              ),
              if (entry.place != null)
                KeyValueRow(label: ActivityStrings.place, value: entry.place!),
              if (entry.reference != null)
                KeyValueRow(label: ActivityStrings.reference, value: entry.reference!),
            ],
          ),
        ),
        if (entry.kind == ActivityKind.security) ...[
          const SizedBox(height: AppSpacing.md),
          const InlineNotice(message: ActivityStrings.notYou, icon: Icons.shield_outlined),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: CommonStrings.close,
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
