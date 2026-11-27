import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/routes.dart';
import '../../../core/utils/formats.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/detail_parts.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../../shared/widgets/paged_list.dart';
import '../application/documents_providers.dart';
import '../domain/civic_document.dart';

IconData _icon(DocumentType t) => switch (t) {
  DocumentType.passport => Icons.menu_book_outlined,
  DocumentType.drivingLicence => Icons.directions_car_outlined,
  DocumentType.birthCertificate => Icons.child_care_outlined,
  DocumentType.residence => Icons.home_outlined,
  DocumentType.taxNotice => Icons.receipt_long_outlined,
  DocumentType.unknown => Icons.description_outlined,
};

/// Status pill: text + icon, never color alone.
class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);
  final DocumentStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (label, icon, fg, bg) = switch (status) {
      DocumentStatus.valid => (DocumentStrings.valid, Icons.check_rounded, c.success, c.successSoft),
      DocumentStatus.expiringSoon => (DocumentStrings.expiringSoon, Icons.schedule_rounded, c.warning, c.warningSoft),
      DocumentStatus.expired => (DocumentStrings.expired, Icons.error_outline_rounded, c.danger, c.dangerSoft),
      DocumentStatus.pending => (DocumentStrings.pending, Icons.hourglass_empty_rounded, c.primary, c.primarySoft),
      DocumentStatus.unknown => (DocumentStrings.unknown, Icons.help_outline_rounded, c.inkSecondary, c.surfaceMuted),
    };
    return StatusPill(label: label, icon: icon, foreground: fg, background: bg, dense: true);
  }
}

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentsProvider);
    final notifier = ref.read(documentsProvider.notifier);
    return PageScaffold(
      title: DocumentStrings.title,
      body: PagedList<CivicDocument>(
        state: state,
        onRefresh: notifier.refresh,
        onLoadMore: notifier.loadMore,
        empty: const StateView(
          icon: Icons.description_outlined,
          title: DocumentStrings.emptyTitle,
          message: DocumentStrings.emptyBody,
        ),
        itemBuilder: (context, d) => AppCard(
          padding: EdgeInsets.zero,
          onTap: () => context.push(Routes.document(d.id)),
          child: AppListTile(
            icon: _icon(d.type),
            title: d.title,
            subtitle: d.issuer,
            footer: _StatusPill(d.status),
            trailing: Icon(Icons.chevron_right_rounded, color: context.colors.inkTertiary),
          ),
        ),
      ),
    );
  }
}

class DocumentScreen extends ConsumerWidget {
  const DocumentScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doc = ref.watch(documentProvider(id));
    return PageScaffold(
      title: DocumentStrings.title,
      body: AsyncView(
        value: doc,
        onRetry: () => ref.invalidate(documentProvider(id)),
        skeleton: const Padding(
          padding: EdgeInsets.all(AppSpacing.gutter),
          child: SkeletonList(count: 3),
        ),
        data: (d) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.xs,
            AppSpacing.gutter,
            AppSpacing.xxl,
          ),
          children: [
            Icon(_icon(d.type), color: context.colors.primary, size: AppSizes.iconLg * 1.4),
            const SizedBox(height: AppSpacing.sm),
            DetailHeader(title: d.title, pill: _StatusPill(d.status)),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                children: [
                  KeyValueRow(label: DocumentStrings.issuer, value: d.issuer),
                  if (d.numberLast4 != null)
                    KeyValueRow(label: DocumentStrings.number, value: Formats.masked(d.numberLast4!)),
                  KeyValueRow(label: DocumentStrings.issued, value: Formats.date(d.issuedAt)),
                  KeyValueRow(
                    label: DocumentStrings.expires,
                    value: d.expiresAt == null ? DocumentStrings.noExpiry : Formats.date(d.expiresAt!),
                  ),
                ],
              ),
            ),
            if (d.status == DocumentStatus.expiringSoon || d.status == DocumentStatus.expired) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: DocumentStrings.renew,
                variant: AppButtonVariant.secondary,
                onPressed: () => context.push(Routes.services),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
