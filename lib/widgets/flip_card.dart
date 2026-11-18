import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'common.dart';

/// A card that turns over with a smooth 3D flip.
///
/// Only one side is ever built at a time, so the hidden side's text is never
/// on screen or readable by screen readers. Give each word its own [Key] so a
/// new card always starts face up.
class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.showBack,
    required this.front,
    required this.back,
    this.onTap,
    this.duration = const Duration(milliseconds: 500),
  });

  final bool showBack;
  final Widget front;
  final Widget back;
  final VoidCallback? onTap;
  final Duration duration;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.showBack ? 1 : 0,
  );

  @override
  void didUpdateWidget(FlipCard old) {
    super.didUpdateWidget(old);
    if (widget.showBack != old.showBack) {
      if (reduceMotion(context)) {
        _c.value = widget.showBack ? 1 : 0;
      } else {
        widget.showBack ? _c.forward() : _c.reverse();
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final angle = Curves.easeInOut.transform(_c.value) * math.pi;
          final backVisible = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: backVisible
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: KeyedSubtree(
                        key: const ValueKey('back'), child: widget.back),
                  )
                : KeyedSubtree(key: const ValueKey('front'), child: widget.front),
          );
        },
      ),
    );
  }
}

/// The rounded white card face used by flashcards.
class CardFace extends StatelessWidget {
  const CardFace({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.borderColor,
  });

  final Widget child;
  final Color color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 260),
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(32),
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 4),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: child,
    );
  }
}
