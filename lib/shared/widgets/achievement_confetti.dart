import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../a11y/motion_policy.dart';

/// Brief confetti burst when an achievement unlocks. Skipped when reduced motion is on.
void showAchievementConfetti(BuildContext context) {
  if (!shouldAnimate(context)) return;
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _AchievementConfettiOverlay(onDone: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _AchievementConfettiOverlay extends StatefulWidget {
  const _AchievementConfettiOverlay({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_AchievementConfettiOverlay> createState() =>
      _AchievementConfettiOverlayState();
}

class _AchievementConfettiOverlayState
    extends State<_AchievementConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _particles = <_Particle>[];
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 24; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          speed: 0.4 + _random.nextDouble() * 0.6,
          hue: _random.nextDouble(),
        ),
      );
    }
    _controller =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1200),
          )
          ..forward()
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) widget.onDone();
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(
              progress: _controller.value,
              particles: _particles,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _Particle {
  _Particle({required this.x, required this.speed, required this.hue});

  final double x;
  final double speed;
  final double hue;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.particles});

  final double progress;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = HSLColor.fromAHSL(
          1 - progress,
          particle.hue,
          0.75,
          0.55,
        ).toColor();
      final dx = particle.x * size.width;
      final dy = progress * size.height * particle.speed;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(dx, dy), width: 6, height: 10),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
