import 'package:flutter/material.dart';

/// Formerly ran T−30 auto-match on [EventState.clockTicker].
/// Flo Meets now uses rooms + symmetric Connect; this widget is an idle passthrough.
class FloMeetsRoundCoordinator extends StatelessWidget {
  const FloMeetsRoundCoordinator({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
