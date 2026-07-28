import 'package:flutter/material.dart';

enum TourStepId {
  nowNextBar,
  discoverSearch,
  recommendationReason,
  sessionAddToPlan,
  logisticsTab,
  venueMapButton,
  companionAsk,
  myPlanSummary,
}

class TourStep {
  const TourStep({
    required this.id,
    required this.route,
    required this.targetKey,
    required this.title,
    required this.body,
    this.primaryLabel,
    this.secondaryLabel,
    this.showBack = true,
    this.isFinal = false,
  });

  final TourStepId id;
  final String route;
  final GlobalKey targetKey;
  final String title;
  final String body;
  final String? primaryLabel;
  final String? secondaryLabel;
  final bool showBack;
  final bool isFinal;
}
