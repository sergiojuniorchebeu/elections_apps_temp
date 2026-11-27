import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/routes.dart';
import '../../../core/error/failure.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../application/search_providers.dart';
import '../domain/search_result.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  static IconData _icon(SearchKind k) => switch (k) {
    SearchKind.election => AppIcons.elections,
    SearchKind.petition => AppIcons.petitions,
    SearchKind.document => AppIcons.documents,
    SearchKind.service => Icons.account_balance_outlined,
    SearchKind.unknown => AppIcons.search,
  };

  static String? _route(SearchResult r) {
    if (!Routes.isValidId(r.id)) return null;
    return switch (r.kind) {
      SearchKind.election => Routes.election(r.id),
      SearchKind.petition => Routes.petition(r.id),
      SearchKind.document => Routes.document(r.id),
      SearchKind.service => Routes.service(r.id),
      SearchKind.unknown => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    final q = ref.watch(searchQueryProvider).trim();
    return PageScaffold(
      title: CommonStrings.search,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              0,
              AppSpacing.gutter,
              AppSpacing.sm,
            ),
            child: AppTextField(
              label: CommonStrings.search,
              hint: SearchStrings.hint,
              controller: _query,
              textInputAction: TextInputAction.search,
              suffixIcon: AppIcons.search,
              onChanged: ref.read(searchQueryProvider.notifier).set,
            ),
          ),
          Expanded(
            child: q.isEmpty
                ? const SingleChildScrollView(
                    child: StateView(
                      icon: AppIcons.search,
                      title: SearchStrings.startTitle,
                      message: SearchStrings.startBody,
                    ),
                  )
                : switch (results) {
                    AsyncValue(:final value?) when value.isEmpty && !results.isLoading =>
                      SingleChildScrollView(
                        child: StateView(
                          icon: Icons.search_off_rounded,
                          title: SearchStrings.noResultTitle,
                          message: SearchStrings.noResultBody(q),
                        ),
                      ),
                    AsyncValue(:final value?) => ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        0,
                        AppSpacing.gutter,
                        AppSpacing.xl,
                      ),
                      itemCount: value.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, i) {
                        final r = value[i];
                        final route = _route(r);
                        return AppCard(
                          padding: EdgeInsets.zero,
                          onTap: route == null ? null : () => context.push(route),
                          child: AppListTile(
                            icon: _icon(r.kind),
                            title: r.title,
                            subtitle: r.subtitle,
                          ),
                        );
                      },
                    ),
                    AsyncValue(:final error?) => SingleChildScrollView(
                      child: FailureView(
                        failure: Failure.from(error),
                        onRetry: () => ref.invalidate(searchResultsProvider),
                      ),
                    ),
                    _ => const Padding(
                      padding: EdgeInsets.all(AppSpacing.gutter),
                      child: SkeletonList(count: 4),
                    ),
                  },
          ),
        ],
      ),
    );
  }
}
