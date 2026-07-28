import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Collapsible per-floor intro copy with landmark deep links.
class FloorStoryPanel extends StatefulWidget {
  const FloorStoryPanel({
    super.key,
    required this.floor,
    required this.blurb,
    this.floors = const ['G', '6', '7', '8', '9', '10', '11', '12', '13'],
    this.showFloorPicker = false,
    this.onFloorChanged,
  });

  final String floor;
  final String blurb;
  final List<String> floors;
  final bool showFloorPicker;
  final ValueChanged<String>? onFloorChanged;

  @override
  State<FloorStoryPanel> createState() => _FloorStoryPanelState();
}

class _FloorStoryPanelState extends State<FloorStoryPanel> {
  bool _expanded = true;

  String _floorLabel(String floor) => floor == 'G' ? 'Ground' : 'Floor $floor';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Material(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'About this floor',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      semanticLabel: _expanded
                          ? 'Collapse floor story'
                          : 'Expand floor story',
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.showFloorPicker) ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final floor in widget.floors)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: FilterChip(
                                  label: Text(_floorLabel(floor)),
                                  selected: floor == widget.floor,
                                  onSelected: (_) =>
                                      widget.onFloorChanged?.call(floor),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(widget.blurb, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 0,
                      children: [
                        TextButton(
                          onPressed: () => context.go('/map?room=ven-C601'),
                          child: const Text('Go to Cafeteria'),
                        ),
                        TextButton(
                          onPressed: () => context.go('/map?room=ven-G01'),
                          child: const Text('Reception'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
