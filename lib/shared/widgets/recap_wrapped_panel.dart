import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../a11y/motion_policy.dart';
import '../theme/app_theme.dart';

class RecapWrappedPanel extends StatelessWidget {
  const RecapWrappedPanel({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final panel = AppChromeColors.of(context).elevatedPanel;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.accentStart.withValues(alpha: 0.13),
            panel,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Recap carousel with optional auto-advance when motion is allowed.
class RecapAutoAdvancePageView extends StatefulWidget {
  const RecapAutoAdvancePageView({
    super.key,
    required this.children,
    this.autoAdvanceInterval = const Duration(seconds: 8),
  });

  final List<Widget> children;
  final Duration autoAdvanceInterval;

  @override
  State<RecapAutoAdvancePageView> createState() =>
      _RecapAutoAdvancePageViewState();
}

class _RecapAutoAdvancePageViewState extends State<RecapAutoAdvancePageView> {
  late final PageController _controller;
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restartAutoAdvance();
  }

  @override
  void didUpdateWidget(covariant RecapAutoAdvancePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoAdvanceInterval != widget.autoAdvanceInterval ||
        oldWidget.children.length != widget.children.length) {
      _restartAutoAdvance();
    }
  }

  void _restartAutoAdvance() {
    _timer?.cancel();
    if (!shouldAnimate(context) || widget.children.length <= 1) return;
    _timer = Timer.periodic(widget.autoAdvanceInterval, (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_page + 1) % widget.children.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      onPageChanged: (index) => _page = index,
      children: widget.children,
    );
  }
}

class RingGauge extends StatelessWidget {
  const RingGauge({super.key, required this.progress, required this.label});
  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 150,
      height: 150,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0, 1),
          baseColor: scheme.outlineVariant,
          activeColor: AppColors.accentStart,
        ),
        child: Center(child: Text(label, textAlign: TextAlign.center)),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.baseColor,
    required this.activeColor,
  });
  final double progress;
  final Color baseColor;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 10;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = baseColor;
    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12
      ..color = activeColor;
    canvas.drawCircle(center, radius, base);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
