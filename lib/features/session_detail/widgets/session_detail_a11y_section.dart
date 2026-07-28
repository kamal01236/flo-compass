import 'package:flutter/material.dart';

import '../../../data/services/session_a11y_repository.dart';
import '../../../domain/entities/venue.dart';

export '../../../data/services/session_a11y_repository.dart'
    show SessionA11yInfo;

class SessionDetailA11ySection extends StatefulWidget {
  const SessionDetailA11ySection({
    super.key,
    required this.sessionId,
    this.venue,
  });

  final String sessionId;
  final Venue? venue;

  @override
  State<SessionDetailA11ySection> createState() =>
      _SessionDetailA11ySectionState();
}

class _SessionDetailA11ySectionState extends State<SessionDetailA11ySection> {
  SessionA11yInfo? _info;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await SessionA11yRepository.instance.forSession(
      widget.sessionId,
    );
    if (mounted) {
      setState(() {
        _info = info;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    final venue = widget.venue;
    final info = _info;
    if (info == null && venue?.stepFree != true) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Accessibility', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (venue?.stepFree == true)
              const Chip(
                avatar: Icon(Icons.accessible, size: 16),
                label: Text('Step-free route'),
              ),
            if (info?.captions == true)
              const Chip(
                avatar: Icon(Icons.closed_caption, size: 16),
                label: Text('Captions'),
              ),
            if (info?.hearingLoop == true)
              const Chip(
                avatar: Icon(Icons.hearing, size: 16),
                label: Text('Hearing loop'),
              ),
          ],
        ),
        if (info?.notes != null) ...[
          const SizedBox(height: 6),
          Text(
            info!.notes!,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
