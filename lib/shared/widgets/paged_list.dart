import 'package:material_ui/material_ui.dart';

import '../../core/error/failure.dart';
import '../../core/state/paginated_notifier.dart';
import '../../design_system/design_system.dart';
import '../../l10n/strings.dart';
import 'failure_view.dart';

/// Renders every state of a [PagedState]: skeleton, full error, empty,
/// items, next page loading / failing, pull-to-refresh that keeps the
/// list on failure.
class PagedList<T> extends StatelessWidget {
  const PagedList({
    super.key,
    required this.state,
    required this.itemBuilder,
    required this.onRefresh,
    required this.onLoadMore,
    required this.empty,
    this.header = const [],
    this.bottomPadding = AppSpacing.xl,
    this.groupBy,
    this.separator = AppSpacing.sm,
  });

  final PagedState<T> state;
  final Widget Function(BuildContext, T) itemBuilder;
  final Future<Failure?> Function() onRefresh;
  final VoidCallback onLoadMore;
  final Widget empty;
  final List<Widget> header;
  final double bottomPadding;
  final double separator;

  /// Optional section title per item ("Today"...): shown when it changes.
  final String Function(T)? groupBy;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final slivers = <Widget>[
      for (final h in header) SliverToBoxAdapter(child: h),
      if (s.loadingFirst && s.items.isEmpty)
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          sliver: SliverToBoxAdapter(child: SkeletonList()),
        )
      else if (s.isBlockingError)
        SliverFillRemaining(
          hasScrollBody: false,
          child: FailureView(failure: s.error!, onRetry: onRefresh),
        )
      else if (s.isEmpty)
        SliverFillRemaining(hasScrollBody: false, child: empty)
      else ...[
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          sliver: SliverList.builder(
            itemCount: s.items.length,
            itemBuilder: (context, i) {
              if (i >= s.items.length - 4) {
                WidgetsBinding.instance.addPostFrameCallback((_) => onLoadMore());
              }
              final item = s.items[i];
              final group = groupBy?.call(item);
              final showGroup =
                  group != null && (i == 0 || groupBy!(s.items[i - 1]) != group);
              return Padding(
                padding: EdgeInsets.only(bottom: separator),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showGroup)
                      Padding(
                        padding: EdgeInsets.only(
                          top: i == 0 ? 0 : AppSpacing.sm,
                          bottom: AppSpacing.xs,
                        ),
                        child: Semantics(
                          header: true,
                          child: Text(
                            group,
                            style: context.text.label.copyWith(
                              color: context.colors.inkSecondary,
                            ),
                          ),
                        ),
                      ),
                    itemBuilder(context, item),
                  ],
                ),
              );
            },
          ),
        ),
        SliverToBoxAdapter(child: _Footer(state: s, onLoadMore: onLoadMore)),
      ],
      SliverPadding(padding: EdgeInsets.only(bottom: bottomPadding)),
    ];
    return RefreshIndicator.adaptive(
      onRefresh: () async {
        final f = await onRefresh();
        if (f != null && context.mounted && s.items.isNotEmpty) {
          showFailureSnack(context, f);
        }
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: slivers,
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onLoadMore});

  final PagedState<Object?> state;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    if (state.moreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Column(
          children: [
            Text(
              state.moreError!.title,
              textAlign: TextAlign.center,
              style: context.text.small.copyWith(color: context.colors.inkSecondary),
            ),
            TextLink(label: CommonStrings.loadMore, onPressed: onLoadMore),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
