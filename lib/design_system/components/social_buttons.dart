import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../tokens/app_dimens.dart';

enum SocialBrand { apple, google }

/// "Continue with Apple / Google" button, drawn the way each provider asks
/// (Apple: black, white in dark mode; Google: white with a border and the
/// four-color G). Provider colors are part of their brand, not of the
/// app theme: they are the only hard-coded colors outside the tokens.
///
/// Before publishing, check the current Apple and Google guidelines and
/// swap [_GoogleMark] for the official asset if required.
class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.brand,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final SocialBrand brand;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  static const _appleInk = Color(0xFF000000);
  static const _white = Color(0xFFFFFFFF);
  static const _googleText = Color(0xFF1F1F1F);
  static const _googleBorder = Color(0xFF747775);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (bg, fg, border) = switch (brand) {
      SocialBrand.apple => dark ? (_white, _appleInk, null) : (_appleInk, _white, null),
      SocialBrand.google => (_white, _googleText, _googleBorder),
    };
    final enabled = onPressed != null && !loading;
    final mark = switch (brand) {
      SocialBrand.apple => Icon(Icons.apple, size: AppSizes.icon, color: fg),
      SocialBrand.google => const _GoogleMark(size: AppSizes.iconSm + 2),
    };
    return Semantics(
      button: true,
      container: true,
      enabled: enabled,
      label: loading ? '$label, in progress' : label,
      excludeSemantics: true,
      child: Opacity(
        opacity: onPressed == null && !loading ? 0.45 : 1,
        child: SizedBox(
          width: double.infinity,
          child: Material(
            color: bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              side: border == null ? BorderSide.none : BorderSide(color: border),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled
                  ? () {
                      HapticFeedback.selectionClick();
                      onPressed!();
                    }
                  : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppSizes.buttonHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: loading ? 0 : 1,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              mark,
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text.label.copyWith(color: fg),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (loading)
                          SizedBox.square(
                            dimension: AppSizes.iconSm,
                            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The four-color "G", drawn (no image or network needed).
class _GoogleMark extends StatelessWidget {
  const _GoogleMark({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _GooglePainter());
}

class _GooglePainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.2;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, s - stroke, s - stroke);
    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    const deg = math.pi / 180;
    // Clockwise from the right: blue (bar side), green, yellow, red.
    canvas.drawArc(rect, -10 * deg, 55 * deg, false, arc(_blue));
    canvas.drawArc(rect, 45 * deg, 95 * deg, false, arc(_green));
    canvas.drawArc(rect, 140 * deg, 80 * deg, false, arc(_yellow));
    canvas.drawArc(rect, 220 * deg, 95 * deg, false, arc(_red));
    // Horizontal bar of the G.
    canvas.drawRect(
      Rect.fromLTWH(s * 0.5, s * 0.5 - stroke / 2, s * 0.5 - stroke * 0.05, stroke),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(_GooglePainter oldDelegate) => false;
}
