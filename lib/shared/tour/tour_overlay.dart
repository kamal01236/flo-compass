import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_settings_provider.dart';
import '../a11y/motion_policy.dart';
import '../theme/app_theme.dart';
import 'tour_controller.dart';
import 'tour_step.dart';

class TourOverlay extends StatefulWidget {
  const TourOverlay({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  State<TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<TourOverlay> {
  final _cardFocusNode = FocusNode();
  Rect? _highlightRect;
  bool _autoStartQueued = false;

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_onRouteOrTourChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoStart());
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRouteOrTourChanged);
    _cardFocusNode.dispose();
    super.dispose();
  }

  void _onRouteOrTourChanged() {
    if (!mounted) return;
    _scheduleHighlightUpdate();
    _maybeAutoStart();
  }

  void _maybeAutoStart() {
    if (_autoStartQueued || !mounted) return;
    final settings = context.read<AppSettingsState>();
    final tour = context.read<TourController>();
    if (tour.active) return;
    if (!settings.shouldAutoStartTour) return;
    if (widget.router.state.matchedLocation != '/discover') return;

    _autoStartQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _autoStartQueued = false;
      await tour.start();
    });
  }

  void _scheduleHighlightUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tour = context.read<TourController>();
      if (!tour.active) {
        if (_highlightRect != null) {
          setState(() => _highlightRect = null);
        }
        return;
      }
      final rect = _targetRect(tour.currentStep);
      if (rect != _highlightRect) {
        setState(() => _highlightRect = rect);
      }
      _cardFocusNode.requestFocus();
    });
  }

  Rect? _targetRect(TourStep step) {
    final context = step.targetKey.currentContext;
    if (context == null) return null;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  String _resolveLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      'tourNowNextTitle' => l10n.tourNowNextTitle,
      'tourNowNextBody' => l10n.tourNowNextBody,
      'tourDiscoverTitle' => l10n.tourDiscoverTitle,
      'tourDiscoverBody' => l10n.tourDiscoverBody,
      'tourRecoReasonTitle' => l10n.tourRecoReasonTitle,
      'tourRecoReasonBody' => l10n.tourRecoReasonBody,
      'tourSessionTitle' => l10n.tourSessionTitle,
      'tourSessionBody' => l10n.tourSessionBody,
      'tourLogisticsTitle' => l10n.tourLogisticsTitle,
      'tourLogisticsBody' => l10n.tourLogisticsBody,
      'tourVenueMapTitle' => l10n.tourVenueMapTitle,
      'tourVenueMapBody' => l10n.tourVenueMapBody,
      'tourCompanionTitle' => l10n.tourCompanionTitle,
      'tourCompanionBody' => l10n.tourCompanionBody,
      'tourMyPlanTitle' => l10n.tourMyPlanTitle,
      'tourMyPlanBody' => l10n.tourMyPlanBody,
      _ => key,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tour = context.watch<TourController>();
    final settings = context.watch<AppSettingsState>();

    if (tour.active) {
      _scheduleHighlightUpdate();
    }

    if (!tour.active && settings.shouldAutoStartTour) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoStart());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (tour.active)
          Positioned.fill(
            child: Shortcuts(
              shortcuts: {
                LogicalKeySet(LogicalKeyboardKey.escape):
                    const _TourSkipIntent(),
                LogicalKeySet(LogicalKeyboardKey.enter):
                    const _TourNextIntent(),
              },
              child: Actions(
                actions: {
                  _TourSkipIntent: CallbackAction<_TourSkipIntent>(
                    onInvoke: (_) {
                      unawaited(tour.skip());
                      return null;
                    },
                  ),
                  _TourNextIntent: CallbackAction<_TourNextIntent>(
                    onInvoke: (_) {
                      if (tour.currentStep.isFinal) {
                        unawaited(tour.complete());
                      } else {
                        unawaited(tour.next());
                      }
                      return null;
                    },
                  ),
                },
                child: Semantics(
                  liveRegion: true,
                  label: _resolveLabel(
                    AppLocalizations.of(context),
                    tour.currentStep.title,
                  ),
                  child: Focus(
                    autofocus: true,
                    child: CustomPaint(
                      painter: _TourScrimPainter(
                        highlightRect: _highlightRect,
                        animate: shouldAnimate(context),
                      ),
                      child: Stack(
                        children: [
                          if (_highlightRect != null)
                            _TourStepCard(
                              focusNode: _cardFocusNode,
                              highlightRect: _highlightRect!,
                              title: _resolveLabel(
                                AppLocalizations.of(context),
                                tour.currentStep.title,
                              ),
                              body: _resolveLabel(
                                AppLocalizations.of(context),
                                tour.currentStep.body,
                              ),
                              stepLabel: l10nStepOf(
                                AppLocalizations.of(context),
                                tour.stepIndex + 1,
                                tour.stepCount,
                              ),
                              showBack: tour.stepIndex > 0,
                              isFinal: tour.currentStep.isFinal,
                              onBack: () => unawaited(tour.back()),
                              onSkip: () => unawaited(tour.skip()),
                              onNext: () => unawaited(
                                tour.currentStep.isFinal
                                    ? tour.complete()
                                    : tour.next(),
                              ),
                              l10n: AppLocalizations.of(context),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String l10nStepOf(AppLocalizations l10n, int current, int total) {
    return l10n.tourStepOf(current, total);
  }
}

class _TourStepCard extends StatelessWidget {
  const _TourStepCard({
    required this.focusNode,
    required this.highlightRect,
    required this.title,
    required this.body,
    required this.stepLabel,
    required this.showBack,
    required this.isFinal,
    required this.onBack,
    required this.onSkip,
    required this.onNext,
    required this.l10n,
  });

  final FocusNode focusNode;
  final Rect highlightRect;
  final String title;
  final String body;
  final String stepLabel;
  final bool showBack;
  final bool isFinal;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxWidth = media.size.width.clamp(280.0, 400.0);
    final placeBelow =
        highlightRect.bottom + 220 < media.size.height - media.padding.bottom;
    final top = placeBelow
        ? highlightRect.bottom + 16
        : (highlightRect.top - 16 - 200).clamp(
            media.padding.top + 8,
            media.size.height - 220,
          );
    final left = ((highlightRect.center.dx - maxWidth / 2).clamp(
      16.0,
      media.size.width - maxWidth - 16,
    ));

    return Positioned(
      left: left,
      top: top,
      width: maxWidth,
      child: Focus(
        focusNode: focusNode,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: AppChromeColors.of(context).elevatedPanel,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stepLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (showBack)
                      TextButton(onPressed: onBack, child: Text(l10n.tourBack)),
                    TextButton(onPressed: onSkip, child: Text(l10n.tourSkip)),
                    const Spacer(),
                    FilledButton(
                      onPressed: onNext,
                      child: Text(isFinal ? l10n.tourDone : l10n.tourNext),
                    ),
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

class _TourScrimPainter extends CustomPainter {
  _TourScrimPainter({required this.highlightRect, required this.animate});

  final Rect? highlightRect;
  final bool animate;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    RRect? hole;
    if (highlightRect != null) {
      hole = RRect.fromRectAndRadius(
        highlightRect!.inflate(8),
        const Radius.circular(8),
      );
      path.addRRect(hole);
      path.fillType = PathFillType.evenOdd;
    }

    canvas.drawPath(path, scrim);

    if (hole != null) {
      final ring = Paint()
        ..color = AppColors.accentStart
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(hole, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _TourScrimPainter oldDelegate) {
    return oldDelegate.highlightRect != highlightRect ||
        oldDelegate.animate != animate;
  }
}

class _TourSkipIntent extends Intent {
  const _TourSkipIntent();
}

class _TourNextIntent extends Intent {
  const _TourNextIntent();
}
