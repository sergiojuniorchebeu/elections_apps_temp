import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/routes.dart';
import '../../../core/state/connectivity.dart';
import '../../../core/utils/formats.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/detail_parts.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/paged_list.dart';
import '../application/petitions_providers.dart';
import '../domain/petition.dart';
import 'petition_sign_sheet.dart';

String _count(Petition p) => HomeStrings.signatures(
  Formats.number(p.signatures),
  Formats.number(p.goal),
);

class PetitionsScreen extends ConsumerWidget {
  const PetitionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(petitionsProvider);
    final notifier = ref.read(petitionsProvider.notifier);
    return PageScaffold(
      title: CivicStrings.petitions,
      body: PagedList<Petition>(
        state: state,
        onRefresh: notifier.refresh,
        onLoadMore: notifier.loadMore,
        empty: const StateView(
          icon: AppIcons.petitions,
          title: CivicStrings.petitionsEmpty,
          message: CivicStrings.petitionsEmptyBody,
        ),
        itemBuilder: (context, p) => _PetitionTile(petition: p),
      ),
    );
  }
}

class _PetitionTile extends StatelessWidget {
  const _PetitionTile({required this.petition});
  final Petition petition;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final p = petition;
    return AppCard(
      padding: EdgeInsets.zero,
      semanticLabel: '${p.title}, ${_count(p)}${p.signedByMe ? ', ${CivicStrings.signed}' : ''}',
      onTap: () => context.push(Routes.petition(p.id)),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (p.category != null)
                        Flexible(
                          child: Text(
                            p.category!.toUpperCase(),
                            style: t.overline.copyWith(color: c.primary),
                          ),
                        ),
                      const Spacer(),
                      if (p.signedByMe)
                        StatusPill(
                          dense: true,
                          label: CivicStrings.signedShort,
                          icon: Icons.check_rounded,
                          background: c.successSoft,
                          foreground: c.success,
                        )
                      else if (p.status != PetitionStatus.open)
                        StatusPill(
                          dense: true,
                          label: p.status == PetitionStatus.successful
                              ? CivicStrings.petitionSuccessful
                              : CivicStrings.closed,
                          background: c.surfaceMuted,
                          foreground: c.inkSecondary,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(p.title, style: t.subtitle),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(_count(p), style: t.small.copyWith(color: c.inkSecondary)),
                ],
              ),
            ),
            AppProgressBar(value: p.progress),
          ],
        ),
      ),
    );
  }
}

class PetitionScreen extends ConsumerWidget {
  const PetitionScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petition = ref.watch(petitionProvider(id));
    final action = ref.watch(signControllerProvider(id));
    final online = ref.watch(connectivityProvider).online;
    final p = petition.value;
    return PageScaffold(
      title: CivicStrings.petitions,
      bottom: p == null
          ? null
          : p.signedByMe
          ? StatusPill(
              label: CivicStrings.signed,
              icon: Icons.check_circle_outline_rounded,
              background: context.colors.successSoft,
              foreground: context.colors.success,
            )
          : p.status != PetitionStatus.open
          ? StatusPill(
              label: CivicStrings.petitionClosed,
              background: context.colors.surfaceMuted,
              foreground: context.colors.inkSecondary,
            )
          : AppButton(
              label: CivicStrings.sign,
              icon: AppIcons.pen,
              loading: action.isRunning,
              onPressed: !online ? null : () => startPetitionSigning(context, ref, p),
            ),
      body: AsyncView(
        value: petition,
        onRetry: () => ref.invalidate(petitionProvider(id)),
        skeleton: const Padding(
          padding: EdgeInsets.all(AppSpacing.gutter),
          child: SkeletonList(count: 4),
        ),
        data: (p) => _PetitionBody(petition: p),
      ),
    );
  }
}

class _PetitionBody extends ConsumerWidget {
  const _PetitionBody({required this.petition});
  final Petition petition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final p = petition;
    final ended = !p.deadline.isAfter(DateTime.now());
    return RefreshIndicator.adaptive(
      onRefresh: () async {
        final f = await ref.read(petitionProvider(p.id).notifier).refresh();
        if (f != null && context.mounted) showFailureSnack(context, f);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.xs,
          AppSpacing.gutter,
          AppSpacing.xl,
        ),
        children: [
          DetailHeader(overline: p.category?.toUpperCase(), title: p.title),
          const SizedBox(height: AppSpacing.xs),
          Text(CivicStrings.by(p.author), style: t.small.copyWith(color: c.inkSecondary)),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _count(p),
                  style: t.bodyStrong.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppProgressBar(
                  value: p.progress,
                  semanticsValue: '${(p.progress * 100).round()} %',
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  ended
                      ? CivicStrings.endedOn(Formats.date(p.deadline))
                      : CivicStrings.endsOn(Formats.date(p.deadline)),
                  style: t.small.copyWith(color: c.inkSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(p.summary, style: t.body),
        ],
      ),
    );
  }
}
