import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum MascotMood { happy, cheer, thinking, sleepy }

/// Ishi the owl, the app's friendly guide. Drawn entirely in code.
class Mascot extends StatefulWidget {
  const Mascot({
    super.key,
    this.mood = MascotMood.happy,
    this.size = 120,
    this.animate = true,
  });

  final MascotMood mood;
  final double size;
  final bool animate;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400));

  bool get _shouldRun =>
      widget.animate && !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  void _sync() {
    if (_shouldRun && !_c.isAnimating) _c.repeat();
    if (!_shouldRun && _c.isAnimating) _c.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(Mascot old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ishi the owl',
      image: true,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _shouldRun ? _c.value : 0.0;
            final bounce = math.sin(t * 2 * math.pi) *
                (widget.mood == MascotMood.cheer ? 0.06 : 0.025);
            // Blink briefly near the end of each loop.
            final blink = (t > 0.92 && t < 0.97) ? 1.0 : 0.0;
            return Transform.translate(
              offset: Offset(0, -bounce * widget.size),
              child: CustomPaint(
                painter: _OwlPainter(
                  mood: widget.mood,
                  blink: widget.mood == MascotMood.sleepy ? 1 : blink,
                  wing: widget.mood == MascotMood.cheer
                      ? (0.5 + 0.5 * math.sin(t * 4 * math.pi))
                      : 0,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OwlPainter extends CustomPainter {
  _OwlPainter({required this.mood, required this.blink, required this.wing});

  final MascotMood mood;
  final double blink; // 0 open .. 1 closed
  final double wing; // 0 down .. 1 up

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    Paint fill(Color c) => Paint()..color = c;
    const body = AppColors.purple;
    const belly = Color(0xFFD9CCFF);

    // Wings (behind the body).
    for (final side in const [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(s * (0.5 + side * 0.30), s * 0.58);
      canvas.rotate(side * (0.25 + wing * 0.9));
      canvas.drawOval(
          Rect.fromCenter(center: Offset(side * s * 0.05, s * 0.06),
              width: s * 0.2, height: s * 0.36),
          fill(AppColors.deepPurple));
      canvas.restore();
    }

    // Ear tufts.
    for (final side in const [-1.0, 1.0]) {
      final path = Path()
        ..moveTo(s * (0.5 + side * 0.16), s * 0.22)
        ..lineTo(s * (0.5 + side * 0.30), s * 0.06)
        ..lineTo(s * (0.5 + side * 0.32), s * 0.28)
        ..close();
      canvas.drawPath(path, fill(AppColors.deepPurple));
    }

    // Body and belly.
    canvas.drawOval(
        Rect.fromLTWH(s * 0.18, s * 0.14, s * 0.64, s * 0.78), fill(body));
    canvas.drawOval(
        Rect.fromLTWH(s * 0.30, s * 0.48, s * 0.40, s * 0.40), fill(belly));
    // Belly feather marks.
    final mark = Paint()
      ..color = body.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.018
      ..strokeCap = StrokeCap.round;
    for (final o in const [Offset(0.42, 0.62), Offset(0.58, 0.62), Offset(0.5, 0.72)]) {
      canvas.drawArc(
          Rect.fromCenter(center: Offset(s * o.dx, s * o.dy),
              width: s * 0.08, height: s * 0.06),
          0.2, math.pi - 0.4, false, mark);
    }

    // Eyes.
    for (final side in const [-1.0, 1.0]) {
      final c = Offset(s * (0.5 + side * 0.13), s * 0.38);
      canvas.drawCircle(c, s * 0.12, fill(Colors.white));
      if (mood == MascotMood.cheer) {
        // Happy closed eyes: upside-down arcs.
        final p = Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.03
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(Rect.fromCenter(center: c, width: s * 0.12, height: s * 0.1),
            math.pi + 0.3, math.pi - 0.6, false, p);
      } else if (blink > 0.5) {
        canvas.drawLine(
            c.translate(-s * 0.06, 0),
            c.translate(s * 0.06, 0),
            Paint()
              ..color = AppColors.ink
              ..strokeWidth = s * 0.03
              ..strokeCap = StrokeCap.round);
      } else {
        final look = mood == MascotMood.thinking ? Offset(s * 0.025, -s * 0.03) : Offset.zero;
        canvas.drawCircle(c + look, s * 0.065, fill(AppColors.ink));
        canvas.drawCircle(c + look + Offset(-s * 0.02, -s * 0.025), s * 0.022,
            fill(Colors.white));
      }
    }

    // Cheeks.
    for (final side in const [-1.0, 1.0]) {
      canvas.drawCircle(Offset(s * (0.5 + side * 0.24), s * 0.5), s * 0.035,
          fill(AppColors.pink.withValues(alpha: 0.6)));
    }

    // Beak.
    final beak = Path()
      ..moveTo(s * 0.46, s * 0.47)
      ..lineTo(s * 0.54, s * 0.47)
      ..lineTo(s * 0.5, s * 0.55)
      ..close();
    canvas.drawPath(beak, fill(AppColors.sunny));

    // Feet.
    for (final side in const [-1.0, 1.0]) {
      canvas.drawOval(
          Rect.fromCenter(center: Offset(s * (0.5 + side * 0.1), s * 0.92),
              width: s * 0.12, height: s * 0.05),
          fill(AppColors.sunny));
    }
  }

  @override
  bool shouldRepaint(_OwlPainter old) =>
      old.mood != mood || old.blink != blink || old.wing != wing;
}

/// Ishi with a speech bubble.
class MascotSays extends StatelessWidget {
  const MascotSays(this.text,
      {super.key, this.mood = MascotMood.happy, this.size = 90, this.animate = true});

  final String text;
  final MascotMood mood;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Mascot(mood: mood, size: size, animate: animate),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Text(text,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
