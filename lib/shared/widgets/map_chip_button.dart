import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Compact map affordance for session rows (≥44dp touch target).
class MapChipButton extends StatelessWidget {
  const MapChipButton({super.key, required this.venueId, this.venueName});

  final String venueId;
  final String? venueName;

  @override
  Widget build(BuildContext context) {
    final label = venueName == null ? 'Open map' : 'Map for $venueName';
    return Semantics(
      label: label,
      button: true,
      child: IconButton(
        tooltip: 'Open map',
        icon: const Icon(Icons.map_outlined),
        iconSize: 22,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        onPressed: () => context.push('/map?room=$venueId'),
      ),
    );
  }
}
