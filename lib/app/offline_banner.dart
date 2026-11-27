import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/state/connectivity.dart';
import '../design_system/design_system.dart';
import '../l10n/strings.dart';

/// Banner on top of every screen while offline, with the countdown to the
/// next automatic retry and a manual retry. The screens below keep
/// showing their saved data.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityProvider);
    if (status.online) return child;
    final media = MediaQuery.of(context);
    return Column(
      children: [
        Material(
          color: context.colors.ink,
          child: SafeArea(
            bottom: false,
            child: _BannerContent(status: status),
          ),
        ),
        Expanded(
          // The banner already took the status bar area.
          child: MediaQuery(
            data: media.removePadding(removeTop: true),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _BannerContent extends ConsumerStatefulWidget {
  const _BannerContent({required this.status});
  final Connectivity status;

  @override
  ConsumerState<_BannerContent> createState() => _BannerContentState();
}

class _BannerContentState extends ConsumerState<_BannerContent> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final next = widget.status.nextRetryAt;
    final seconds = next == null
        ? 0
        : next.difference(DateTime.now()).inSeconds.clamp(0, 999);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xxs,
          AppSpacing.xs,
          AppSpacing.xxs,
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: c.background, size: AppSizes.iconSm),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(CommonStrings.offlineTitle, style: t.label.copyWith(color: c.background)),
                  Text(
                    widget.status.checking
                        ? CommonStrings.offlineChecking
                        : CommonStrings.offlineRetryIn(seconds),
                    style: t.caption.copyWith(color: c.background),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: widget.status.checking
                  ? null
                  : ref.read(connectivityProvider.notifier).retryNow,
              child: Text(
                CommonStrings.retry,
                style: t.label.copyWith(color: c.background),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
