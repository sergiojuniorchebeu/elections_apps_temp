import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/formats.dart';
import '../../../../design_system/design_system.dart';
import '../../../../l10n/strings.dart';

/// The blue citizen card of the home and Digital ID screens. Takes plain
/// values so any screen can show it.
class CitizenCard extends StatelessWidget {
  const CitizenCard({
    super.key,
    required this.fullName,
    required this.last4,
    required this.verified,
    this.onOpen,
  });

  final String fullName;
  final String last4;
  final bool verified;

  /// The round arrow button; hidden when null.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      container: true,
      label:
          '${IdStrings.cardLabel}, $fullName, ${verified ? IdStrings.verified : IdStrings.pending}, '
          'number ending ${last4.split('').join(' ')}',
      child: IdCardSurface(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        IdStrings.cardLabel,
                        style: t.overline.copyWith(color: c.onCardMuted),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: StatusPill(
                        label: verified ? IdStrings.verified : IdStrings.pending,
                        icon: verified ? Icons.check_rounded : Icons.schedule_rounded,
                        background: c.onCard,
                        foreground: verified ? c.cardTo : c.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.cardName.copyWith(color: c.onCard),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'CI   ${Formats.masked(last4)}',
                            style: t.number.copyWith(color: c.onCardMuted),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.fingerprint_rounded,
                      size: AppSizes.iconLg * 1.6,
                      color: c.onCardMuted,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        IdStrings.tagline,
                        style: t.small.copyWith(color: c.onCardMuted),
                      ),
                    ),
                    if (onOpen != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      CircleIconButton(
                        icon: Icons.north_east_rounded,
                        semanticLabel: IdStrings.openId,
                        foreground: c.cardTo,
                        background: c.onCard,
                        size: AppSizes.roundButton + 4,
                        onPressed: onOpen,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
