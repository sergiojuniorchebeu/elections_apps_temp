import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../tokens/app_dimens.dart';

/// Gradient surface of the citizen card: concentric arcs and a
/// fingerprint watermark. Content is given by the caller.
class IdCardSurface extends StatelessWidget {
  const IdCardSurface({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: c.cardTo.withValues(alpha: 0.22),
            blurRadius: 28,
            spreadRadius: -6,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.cardFrom, c.cardTo],
              ),
            ),
            child: InkWell(
              onTap: onTap,
              child: CustomPaint(
                painter: _ArcsPainter(c.cardLine),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcsPainter extends CustomPainter {
  _ArcsPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    final center = Offset(size.width * 0.88, size.height * 0.36);
    for (var r = 24.0; r < size.width * 0.7; r += 16) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_ArcsPainter old) => old.color != color;
}

/// Friendly ID-card character of the home screen, drawn in code so it
/// follows the theme colors. Purely decorative.
class CardMascot extends StatelessWidget {
  const CardMascot({super.key, this.size = AppSizes.mascot});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size,
      height: size * 0.85,
      child: CustomPaint(painter: _MascotPainter()),
    ),
  );
}

/// Illustration colors are part of the artwork (same in light and dark).
class _MascotPainter extends CustomPainter {

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ink = Paint()
      ..color = const Color(0xFF111833)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = const Color(0xFF111833);

    // Legs and arms behind the card.
    canvas.drawLine(Offset(w * .38, h * .7), Offset(w * .33, h * .95), ink);
    canvas.drawLine(Offset(w * .6, h * .68), Offset(w * .62, h * .95), ink);
    canvas.drawLine(Offset(w * .27, h * .95), Offset(w * .37, h * .95), ink);
    canvas.drawLine(Offset(w * .58, h * .95), Offset(w * .7, h * .95), ink);
    canvas.drawLine(Offset(w * .12, h * .5), Offset(w * .02, h * .62), ink);
    canvas.drawLine(Offset(w * .86, h * .36), Offset(w * .97, h * .48), ink);
    canvas.drawCircle(Offset(w * .02, h * .64), w * .035, fill);
    canvas.drawCircle(Offset(w * .97, h * .5), w * .035, fill);

    // Tilted card body.
    canvas.save();
    canvas.translate(w * .5, h * .45);
    canvas.rotate(-math.pi / 14);
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w * .74, height: h * .52),
      Radius.circular(w * .08),
    );
    canvas.drawRRect(
      body.shift(Offset(w * .025, h * .03)),
      Paint()..color = const Color(0xFF1B2A9E),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF4A63F0), Color(0xFF2F45D6)],
        ).createShader(body.outerRect),
    );
    final light = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..strokeWidth = w * .03
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-w * .27, -h * .14), Offset(-w * .17, -h * .14), light);
    canvas.drawLine(Offset(-w * .27, -h * .06), Offset(-w * .1, -h * .06), light);
    // Face: eyes and smile.
    final face = Paint()
      ..color = const Color(0xFF111833)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .025
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(-w * .02, h * .04), radius: w * .03),
      math.pi,
      math.pi,
      false,
      face,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * .12, h * .02), radius: w * .03),
      math.pi,
      math.pi,
      false,
      face,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * .05, h * .1), radius: w * .06),
      0.2,
      math.pi - 0.4,
      false,
      face,
    );
    canvas.restore();

    // Check badge.
    final badge = Offset(w * .8, h * .14);
    canvas.drawCircle(badge, w * .085, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(badge, w * .065, Paint()..color = const Color(0xFF2BB673));
    final check = Path()
      ..moveTo(badge.dx - w * .03, badge.dy)
      ..lineTo(badge.dx - w * .005, badge.dy + w * .025)
      ..lineTo(badge.dx + w * .035, badge.dy - w * .02);
    canvas.drawPath(
      check,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .022
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_MascotPainter old) => false;
}
