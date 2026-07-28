import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../data/models/flo_meet.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/event_provider.dart';
import '../../providers/flo_meets_provider.dart';
import '../../shared/utils/flo_meet_amenity_label.dart';
import '../../shared/widgets/shared_widgets.dart';

class FloMeetsListScreen extends StatelessWidget {
  const FloMeetsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final floMeets = context.watch<FloMeetsState>();
    final event = context.watch<EventState>();
    final day = event.currentDay;
    final todayMeets = floMeets.meetsForDay(day);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.floMeetsTitle)),
      body: ResponsiveLayout(
        child: floMeets.preferences.isSetupComplete
            ? todayMeets.isEmpty
                  ? _EmptyState(l10n: l10n)
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: todayMeets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final meet = todayMeets[index];
                        return _MeetCard(
                          meet: meet,
                          amenityLabel: _amenityLabel(
                            event,
                            meet.meetAmenityId,
                          ),
                          l10n: l10n,
                          onTap: () =>
                              context.push(AppRoutes.floMeetDetail(meet.id)),
                        );
                      },
                    )
            : _NeedsSetup(l10n: l10n),
      ),
    );
  }

  static String _amenityLabel(EventState event, String amenityId) {
    final amenity = event.amenityById(amenityId);
    if (amenity == null) return amenityId;
    return formatFloMeetAmenityLabel(amenity);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(l10n.floMeetsEmptyTitle, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              l10n.floMeetsEmptyBody,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NeedsSetup extends StatelessWidget {
  const _NeedsSetup({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.floMeetsSetupTitle, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              l10n.floMeetsSetupBody,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(AppRoutes.floMeetsPreferences),
              child: Text(l10n.floMeetsSetupCta),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeetCard extends StatelessWidget {
  const _MeetCard({
    required this.meet,
    required this.amenityLabel,
    required this.l10n,
    required this.onTap,
  });

  final FloMeet meet;
  final String amenityLabel;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final timeLabel = '${_fmt(meet.windowStart)} – ${_fmt(meet.windowEnd)}';
    final contact = meet.contactSnapshot?.value;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(timeLabel, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(
                meet.partnerNickname,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 16),
                  const SizedBox(width: 4),
                  Expanded(child: Text(amenityLabel)),
                ],
              ),
              if (contact != null && contact.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(l10n.floMeetsContactLine(contact)),
              ],
              if (meet.meetNote.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  meet.meetNote,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
