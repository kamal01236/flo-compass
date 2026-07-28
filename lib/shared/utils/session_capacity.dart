import 'package:flutter/material.dart';

class StreamNudge {
  const StreamNudge({required this.label});

  final String label;
}

(Color capacityColor, String capacityLabel) capacityPresentation(
  int occupancy,
) {
  if (occupancy > 90) return (Colors.redAccent, 'Nearly full');
  if (occupancy >= 70) return (Colors.amber, 'Filling fast');
  return (Colors.greenAccent, 'Seats available');
}

StreamNudge? streamNudgeFor({
  required int occupancyPercent,
  required bool isStreamable,
}) {
  if (occupancyPercent >= 90 && isStreamable) {
    return const StreamNudge(label: 'Nearly full — join stream instead');
  }
  return null;
}
