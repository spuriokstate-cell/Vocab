import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// True when animations should be skipped (parent setting or device setting).
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Centers content and limits its width on big screens (tablets, Windows).
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 820});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

/// A round speaker button that reads [text] aloud.
class SpeakButton extends StatelessWidget {
  const SpeakButton({
    super.key,
    required this.text,
    this.size = 56,
    this.tooltip = 'Listen',
    this.color = AppColors.purple,
  });

  final String text;
  final double size;
  final String tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => AppScope.read(context).speech.speak(text),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(Icons.volume_up_rounded,
                color: Colors.white, size: size * 0.55,
                semanticLabel: tooltip),
          ),
        ),
      ),
    );
  }
}

/// A big colorful rounded button used across the app.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.emoji,
    this.color = AppColors.purple,
    this.textColor = Colors.white,
    this.fontSize = 20,
  });

  final String label;
  final String? emoji;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      child: Text(emoji == null ? label : '$emoji  $label',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800)),
    );
  }
}

/// Green "well done" or orange "try again" message box.
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({
    super.key,
    required this.good,
    required this.message,
    this.detail,
  });

  final bool good;
  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: good ? const Color(0xFFDDF7EA) : const Color(0xFFFFEBD6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: good ? AppColors.right : AppColors.tryAgain, width: 2),
        ),
        child: Column(
          children: [
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(detail!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 17)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Stars that pop in when the child gets something right.
class StarReward extends StatefulWidget {
  const StarReward({super.key, this.count = 1, this.size = 44});
  final int count;
  final double size;

  @override
  State<StarReward> createState() => _StarRewardState();
}

class _StarRewardState extends State<StarReward>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.value = 1;
    } else if (_c.value == 0 && !_c.isAnimating) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.count} star${widget.count == 1 ? '' : 's'} earned',
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.count; i++)
              Transform.scale(
                scale: Curves.elasticOut.transform(
                    ((_c.value * (widget.count + 1)) - i).clamp(0.0, 1.0)),
                child: Text('⭐', style: TextStyle(fontSize: widget.size)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Colorful pieces of paper falling: a short celebration.
class Confetti extends StatefulWidget {
  const Confetti({super.key, this.pieces = 60});
  final int pieces;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200));
  final _rnd = math.Random();
  late final List<_Piece> _pieces = List.generate(
      widget.pieces,
      (_) => _Piece(
            x: _rnd.nextDouble(),
            delay: _rnd.nextDouble() * 0.35,
            speed: 0.7 + _rnd.nextDouble() * 0.6,
            drift: (_rnd.nextDouble() - 0.5) * 0.25,
            spin: _rnd.nextDouble() * 6,
            color: const [
              AppColors.coral, AppColors.sunny, AppColors.mint, AppColors.sky,
              AppColors.pink, AppColors.purple, AppColors.leaf,
            ][_rnd.nextInt(7)],
          ));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!reduceMotion(context) && _c.value == 0 && !_c.isAnimating) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(_pieces, _c.value),
          ),
        ),
      ),
    );
  }
}

class _Piece {
  _Piece({
    required this.x,
    required this.delay,
    required this.speed,
    required this.drift,
    required this.spin,
    required this.color,
  });
  final double x, delay, speed, drift, spin;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final y = -20 + local * p.speed * (size.height + 40);
      final x = (p.x + p.drift * local) * size.width;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * local * math.pi);
      canvas.drawRect(const Rect.fromLTWH(-5, -3, 10, 6),
          Paint()..color = p.color.withValues(alpha: 1 - local * 0.5));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// A rounded progress bar with a label, used for grades and sessions.
class SoftProgressBar extends StatelessWidget {
  const SoftProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.purple,
    this.background = const Color(0x22000000),
    this.height = 14,
    this.semanticLabel,
  });

  final double value;
  final Color color;
  final Color background;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      value: '${(value * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1).toDouble(),
          minHeight: height,
          color: color,
          backgroundColor: background,
        ),
      ),
    );
  }
}
