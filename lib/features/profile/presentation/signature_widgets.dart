import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/strings.dart';
import '../domain/signature.dart';

/// Strokes being drawn on a [SignaturePad].
class SignaturePadController extends ChangeNotifier {
  SignaturePadController([Signature? initial])
    : _strokes = [
        for (final s in initial?.strokes ?? const <List<SignaturePoint>>[]) [...s],
      ];

  final List<List<SignaturePoint>> _strokes;

  List<List<SignaturePoint>> get strokes => _strokes;
  bool get isEmpty => _strokes.every((s) => s.isEmpty);

  Signature toSignature() => Signature(
    strokes: [
      for (final s in _strokes)
        if (s.isNotEmpty) List.unmodifiable(s),
    ],
  );

  void clear() {
    _strokes.clear();
    notifyListeners();
  }

  void undo() {
    if (_strokes.isEmpty) return;
    _strokes.removeLast();
    notifyListeners();
  }

  void _start(SignaturePoint p) {
    _strokes.add([p]);
    notifyListeners();
  }

  void _extend(SignaturePoint p) {
    if (_strokes.isEmpty) return;
    _strokes.last.add(p);
    notifyListeners();
  }
}

/// The box where the member signs with a finger. Fixed proportions
/// ([Signature.aspect]) so a signature looks the same on every screen.
///
/// Takes the finger at once: a stroke never turns into a scroll or a
/// sheet drag.
class SignaturePad extends StatelessWidget {
  const SignaturePad({super.key, required this.controller, this.error});

  final SignaturePadController controller;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: SignatureStrings.padLabel,
          hint: SignatureStrings.padHint,
          child: AspectRatio(
            aspectRatio: Signature.aspect,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: error == null ? c.border : c.danger),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: LayoutBuilder(
                  builder: (context, box) {
                    final size = box.biggest;
                    SignaturePoint norm(Offset o) => SignaturePoint(
                      (o.dx / size.width).clamp(0.0, 1.0),
                      (o.dy / size.height).clamp(0.0, 1.0),
                    );
                    return RawGestureDetector(
                      behavior: HitTestBehavior.opaque,
                      gestures: {
                        _DrawRecognizer: GestureRecognizerFactoryWithHandlers<_DrawRecognizer>(
                          _DrawRecognizer.new,
                          (r) => r
                            ..onStart = (o) {
                              HapticFeedback.selectionClick();
                              controller._start(norm(o));
                            }
                            ..onUpdate = (o) => controller._extend(norm(o)),
                        ),
                      },
                      child: ListenableBuilder(
                        listenable: controller,
                        builder: (context, _) => Stack(
                          fit: StackFit.expand,
                          children: [
                            const _Baseline(),
                            if (controller.isEmpty)
                              Center(
                                child: Text(
                                  SignatureStrings.padHint,
                                  style: context.text.body.copyWith(color: c.inkTertiary),
                                ),
                              ),
                            CustomPaint(
                              painter: SignaturePainter(
                                strokes: controller.strokes,
                                color: c.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(error!, style: context.text.small.copyWith(color: c.danger)),
        ],
      ],
    );
  }
}

/// The dotted line a signature sits on.
class _Baseline extends StatelessWidget {
  const _Baseline();

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _BaselinePainter(context.colors.border),
  );
}

class _BaselinePainter extends CustomPainter {
  _BaselinePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * 0.78;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const dash = 6.0;
    for (var x = size.width * 0.06; x < size.width * 0.94; x += dash * 2) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + dash, size.width * 0.94), y), paint);
    }
  }

  @override
  bool shouldRepaint(_BaselinePainter old) => old.color != color;
}

/// Accepts the pointer as soon as it touches the pad.
class _DrawRecognizer extends OneSequenceGestureRecognizer {
  _DrawRecognizer() : super();

  ValueChanged<Offset>? onStart;
  ValueChanged<Offset>? onUpdate;
  int? _pointer;
  Offset? _last;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_pointer != null) return; // one finger draws
    _pointer = event.pointer;
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted);
    _last = event.localPosition;
    onStart?.call(event.localPosition);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _pointer) return;
    if (event is PointerMoveEvent) {
      // Skips sub-pixel jitter: lighter strokes, same look.
      if ((event.localPosition - _last!).distance >= 1.5) {
        _last = event.localPosition;
        onUpdate?.call(event.localPosition);
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _pointer = null;
    _last = null;
  }

  @override
  String get debugDescription => 'signature draw';
}

/// Paints strokes, fully or up to [progress] (0..1, by length) for the
/// drawing animation.
class SignaturePainter extends CustomPainter {
  SignaturePainter({
    required this.strokes,
    required this.color,
    this.progress = 1,
  });

  final List<List<SignaturePoint>> strokes;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(2, size.height * 0.022);
    final geometry = SignatureGeometry(strokes, size);
    var budget = geometry.length * progress.clamp(0.0, 1.0);
    for (final stroke in geometry.strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        if (budget <= 0 && progress < 1) return;
        canvas.drawCircle(stroke.first, paint.strokeWidth / 2, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        final a = stroke[i - 1];
        final b = stroke[i];
        final d = (b - a).distance;
        if (budget < d && progress < 1) {
          final t = d == 0 ? 0.0 : budget / d;
          final end = Offset.lerp(a, b, t)!;
          path.lineTo(end.dx, end.dy);
          canvas.drawPath(path, paint);
          return;
        }
        budget -= d;
        path.lineTo(b.dx, b.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(SignaturePainter old) => true;
}

/// Strokes in pixels, their total length, and where the pen is at a
/// given progress.
final class SignatureGeometry {
  SignatureGeometry(List<List<SignaturePoint>> normalized, Size size)
    : strokes = [
        for (final s in normalized)
          [for (final p in s) Offset(p.x * size.width, p.y * size.height)],
      ] {
    var total = 0.0;
    for (final s in strokes) {
      for (var i = 1; i < s.length; i++) {
        total += (s[i] - s[i - 1]).distance;
      }
    }
    length = total;
  }

  final List<List<Offset>> strokes;
  late final double length;

  Offset? tipAt(double progress) {
    var budget = length * progress.clamp(0.0, 1.0);
    Offset? last;
    for (final s in strokes) {
      if (s.isEmpty) continue;
      last = s.first;
      for (var i = 1; i < s.length; i++) {
        final d = (s[i] - s[i - 1]).distance;
        if (budget <= d) {
          return Offset.lerp(s[i - 1], s[i], d == 0 ? 0 : budget / d);
        }
        budget -= d;
        last = s[i];
      }
    }
    return last;
  }
}

/// A saved signature, still or written live: the pen image follows the
/// line while it is drawn ([animate] -> true starts it, [onDone] when the
/// last stroke is finished). With "reduce motion", it shows at once.
class SignatureView extends StatefulWidget {
  const SignatureView({
    super.key,
    required this.signature,
    this.animate = false,
    this.hidden = false,
    this.onDone,
    this.color,
  });

  final Signature signature;

  /// Plays the writing animation once when it turns true.
  final bool animate;

  /// Nothing drawn yet (before signing).
  final bool hidden;
  final VoidCallback? onDone;
  final Color? color;

  @override
  State<SignatureView> createState() => _SignatureViewState();
}

class _SignatureViewState extends State<SignatureView> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone?.call();
    });

  @override
  void initState() {
    super.initState();
    if (widget.animate) _schedulePlay();
  }

  @override
  void didUpdateWidget(SignatureView old) {
    super.didUpdateWidget(old);
    if (widget.animate && !old.animate) _schedulePlay();
    if (!widget.animate && old.animate) _anim.reset();
  }

  /// After the frame: [SignatureView.onDone] may rebuild the parent.
  void _schedulePlay() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());

  void _play() {
    if (!mounted || !widget.animate) return;
    if (context.reduceMotion) {
      _anim.value = 1; // completed: onDone through the status listener
      return;
    }
    _anim.forward(from: 0);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.colors.ink;
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: Signature.aspect,
        child: LayoutBuilder(
          builder: (context, box) => AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              final drawing = _anim.isAnimating;
              final progress = widget.animate
                  ? _anim.value
                  : (widget.hidden ? 0.0 : 1.0);
              final tip = drawing
                  ? SignatureGeometry(widget.signature.strokes, box.biggest).tipAt(progress)
                  : null;
              const pen = AppSizes.iconLg + 6;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: SignaturePainter(
                        strokes: widget.signature.strokes,
                        color: color,
                        progress: progress,
                      ),
                    ),
                  ),
                  // The nib of the pen drawing is at its bottom-left corner.
                  if (tip != null)
                    Positioned(
                      left: tip.dx - pen * 0.12,
                      top: tip.dy - pen * 0.88,
                      child: AppIcon(AppIcons.pen, size: pen, color: context.colors.primary),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
