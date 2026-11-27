import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/routes.dart';
import '../../../core/core_providers.dart';
import '../../../core/state/fresh.dart';
import '../../../core/utils/formats.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../identity/identity.dart';
import '../../notifications/notifications.dart';
import '../application/home_providers.dart';
import '../domain/home_feed.dart';

/// "Your Day, Your Country": greeting, citizen card, shortcuts and the
/// community (next election, featured petition).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static String greeting(DateTime now) => now.hour < 12
      ? HomeStrings.morning
      : now.hour < 18
      ? HomeStrings.afternoon
      : HomeStrings.evening;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watchFresh(homeFeedProvider);
    Future<void> refresh() async {
      final f = await ref.read(homeFeedProvider.notifier).refresh();
      if (f != null && context.mounted) showFailureSnack(context, f);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator.adaptive(
            onRefresh: refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: MaxWidth(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        AppSpacing.md,
                        AppSpacing.gutter,
                        AppNavBar.bottomInset(context),
                      ),
                      child: AsyncView(
                        value: feed,
                        onRetry: () => ref.invalidate(homeFeedProvider),
                        skeleton: const _HomeSkeleton(),
                        data: (f) => _HomeContent(feed: f),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.feed});
  final HomeFeed feed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AppAvatar(initials: feed.initials),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      HomeScreen.greeting(ref.watch(clockProvider)()),
                      style: t.small.copyWith(color: c.inkSecondary),
                    ),
                    Text(
                      feed.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.subtitle,
                    ),
                  ],
                ),
              ),
            ),
            CircleIconButton(
              icon: Icons.search_rounded,
              semanticLabel: CommonStrings.search,
              onPressed: () => context.push(Routes.search),
            ),
            const NotificationBell(),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(HomeStrings.title, style: t.display),
              ),
            ),
            const CardMascot(),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        CitizenCard(
          fullName: feed.fullName,
          last4: feed.idLast4,
          verified: feed.idVerified,
          onOpen: () => context.go(Routes.digitalId),
        ),
        const SizedBox(height: AppSpacing.md),
        const _Shortcuts(),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(
          title: HomeStrings.community,
          action: PillButton(
            label: CommonStrings.viewAll,
            onPressed: () => context.push(Routes.elections),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (feed.nextElection == null && feed.featuredPetition == null)
          AppCard(
            child: StateView(
              icon: Icons.groups_2_outlined,
              title: HomeStrings.nothingNew,
              message: HomeStrings.nothingNewBody,
            ),
          ),
        if (feed.nextElection case final e?) ...[
          _ElectionCard(election: e),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (feed.featuredPetition case final p?) _PetitionCard(petition: p),
      ],
    );
  }
}

class _Shortcuts extends StatelessWidget {
  const _Shortcuts();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.description_outlined, HomeStrings.documents, Routes.documents),
      (Icons.grid_view_outlined, HomeStrings.services, Routes.services),
      (Icons.how_to_vote_outlined, HomeStrings.elections, Routes.elections),
      (Icons.article_outlined, HomeStrings.petitions, Routes.petitions),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        // Four in a row when they fit, else two by two.
        final perRow = constraints.maxWidth / 4 < 84 ? 2 : 4;
        final width =
            (constraints.maxWidth - AppSpacing.xs * (perRow - 1)) / perRow;
        return Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final (icon, label, route) in items)
              SizedBox(
                width: width,
                child: AppCard(
                  semanticLabel: label,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                    horizontal: AppSpacing.xxs,
                  ),
                  onTap: () => context.push(route),
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        Icon(icon, color: context.colors.primary, size: AppSizes.iconLg),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.small,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ElectionCard extends StatelessWidget {
  const _ElectionCard({required this.election});
  final ElectionTeaser election;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return AppCard(
      semanticLabel:
          '${HomeStrings.upcomingElection}, ${election.title}, ${Formats.longDay(election.date)}',
      onTap: () => context.push(Routes.election(election.id)),
      child: ExcludeSemantics(
        child: Row(
          children: [
            DateTile(
              month: Formats.monthShort(election.date),
              day: Formats.day(election.date),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    HomeStrings.upcomingElection,
                    style: t.overline.copyWith(color: c.primary),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(election.title, style: t.headline),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.inkSecondary),
          ],
        ),
      ),
    );
  }
}

class _PetitionCard extends StatelessWidget {
  const _PetitionCard({required this.petition});
  final PetitionTeaser petition;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final count = HomeStrings.signatures(
      Formats.number(petition.signatures),
      Formats.number(petition.goal),
    );
    return AppCard(
      color: c.surfaceMuted,
      padding: EdgeInsets.zero,
      semanticLabel: '${petition.title}, $count',
      onTap: () => context.push(Routes.petition(petition.id)),
      child: ExcludeSemantics(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(Icons.article_outlined, color: c.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(petition.title, style: t.subtitle),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          count,
                          style: t.small.copyWith(
                            color: c.inkSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.north_east_rounded, color: c.primary),
                ],
              ),
            ),
            AppProgressBar(value: petition.progress),
          ],
        ),
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) => Semantics(
    label: CommonStrings.loading,
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Skeleton(width: AppSizes.avatar, height: AppSizes.avatar, radius: AppRadius.pill),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Skeleton(height: 18)),
          ],
        ),
        SizedBox(height: AppSpacing.xl),
        FractionallySizedBox(widthFactor: .6, child: Skeleton(height: AppSpacing.xxl)),
        SizedBox(height: AppSpacing.xs),
        FractionallySizedBox(widthFactor: .7, child: Skeleton(height: AppSpacing.xxl)),
        SizedBox(height: AppSpacing.lg),
        AspectRatio(aspectRatio: AppSizes.cardAspect, child: Skeleton(radius: AppRadius.xl)),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: AppSpacing.xxxl * 2, radius: AppRadius.lg),
        SizedBox(height: AppSpacing.xl),
        Skeleton(height: AppSpacing.xxxl * 2, radius: AppRadius.lg),
      ],
    ),
  );
}
