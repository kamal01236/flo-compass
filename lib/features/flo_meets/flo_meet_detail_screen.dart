import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/event_provider.dart';
import '../../providers/flo_meets_provider.dart';
import '../../shared/utils/flo_meet_amenity_label.dart';
import '../../shared/widgets/shared_widgets.dart';

class FloMeetDetailScreen extends StatelessWidget {
  const FloMeetDetailScreen({super.key, required this.meetId});

  final String meetId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final floMeets = context.watch<FloMeetsState>();
    final event = context.watch<EventState>();
    final meet = floMeets.meetById(meetId);

    if (meet == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.floMeetsTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.floMeetsNotFound),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go(AppRoutes.floMeetsRoot),
                child: Text(l10n.floMeetsBackToList),
              ),
            ],
          ),
        ),
      );
    }

    final amenity = event.amenityById(meet.meetAmenityId);
    final venue = amenity?.venueId != null
        ? event.venueById(amenity!.venueId!)
        : null;
    final locationLabel = amenity != null
        ? formatFloMeetAmenityLabel(amenity)
        : meet.meetAmenityId;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.floMeetsDetailTitle)),
      body: ResponsiveLayout(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_fmt(meet.windowStart)} – ${_fmt(meet.windowEnd)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: l10n.floMeetsPartnerNickname,
                value: meet.partnerNickname,
              ),
              _DetailRow(
                label: l10n.floMeetsMeetLocation,
                value: locationLabel,
              ),
              if (venue != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    venue.name,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              if (amenity?.venueId != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/map?room=${amenity!.venueId}'),
                    icon: const Icon(Icons.map_outlined),
                    label: Text(l10n.floMeetsOpenOnCampusMap),
                  ),
                ),
              if (meet.contactSnapshot != null &&
                  meet.contactSnapshot!.value.isNotEmpty)
                _DetailRow(
                  label: l10n.floMeetsContactField,
                  value: meet.contactSnapshot!.value,
                ),
              if (meet.meetNote.isNotEmpty)
                _DetailRow(label: l10n.floMeetsMeetNote, value: meet.meetNote),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.connectShare),
                icon: const Icon(Icons.qr_code_2_outlined),
                label: Text(l10n.floMeetsOpenConnectShare),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
