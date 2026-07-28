import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/routing/app_routes.dart';
import '../../../data/models/flo_meets_preferences.dart';
import '../../../data/models/networking_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/flo_meets_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../shared/theme/app_theme.dart';

class FloMeetsProfileCard extends StatelessWidget {
  const FloMeetsProfileCard({super.key, required this.networkingCard});

  final NetworkingCard networkingCard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final floMeets = context.watch<FloMeetsState>();
    final prefs = floMeets.preferences;
    final setupComplete = prefs.isSetupComplete;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_outline, color: AppColors.accentStart),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.floMeetsTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              setupComplete
                  ? l10n.floMeetsProfileDescription
                  : l10n.floMeetsProfileSetupNeeded,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            if (setupComplete) ...[
              const SizedBox(height: 4),
              Text(
                l10n.floMeetsProfileSlotsReady(prefs.enabledSlots.length),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
            if (setupComplete &&
                prefs.contactMedium != FloMeetContactMedium.none &&
                !_hasContact(networkingCard, prefs.contactMedium)) ...[
              const SizedBox(height: 8),
              Text(
                l10n.floMeetsContactEmptyWarning,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => context.go(AppRoutes.floMeetsPreferences),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(
                    setupComplete
                        ? l10n.floMeetsEditPreferences
                        : l10n.floMeetsSetupCta,
                  ),
                ),
                if (setupComplete)
                  OutlinedButton(
                    onPressed: () => context.go(AppRoutes.floMeetsRoot),
                    child: Text(l10n.floMeetsViewMeets),
                  ),
                if (kDebugMode && setupComplete)
                  TextButton(
                    onPressed: () => _previewDemoMatch(context),
                    child: Text(l10n.floMeetsPreviewDemoMatch),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _previewDemoMatch(BuildContext context) async {
    final floMeets = context.read<FloMeetsState>();
    final profile = context.read<ProfileState>();
    final room = await floMeets.joinFirstOpenRoom();
    if (room == null || !context.mounted) return;
    final members = await floMeets.membersForRoom(
      roomId: room.id,
      userRole: profile.profile.role,
      professionalInterests: profile.profile.interests,
    );
    if (!context.mounted) return;
    if (members.isEmpty) {
      context.go(AppRoutes.floMeetRoom(room.id));
      return;
    }
    context.go(AppRoutes.floMeetWindow(room.id, members.first.partner.id));
  }

  static bool _hasContact(NetworkingCard card, FloMeetContactMedium medium) {
    final field = switch (medium) {
      FloMeetContactMedium.email => card.email,
      FloMeetContactMedium.phone => card.phoneE164,
      FloMeetContactMedium.linkedin => card.linkedInUrl,
      FloMeetContactMedium.none => null,
    };
    return field != null && field.visible && field.value.trim().isNotEmpty;
  }
}
