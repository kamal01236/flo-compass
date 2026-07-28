import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/user_profile.dart';
import '../../providers/profile_provider.dart';

/// Short label for the Personalize button and active-filter chips.
String personalizeSummary(UserProfile profile) {
  final modeLabel = switch (profile.recommendationMode) {
    RecommendationMode.focused => 'Focused',
    RecommendationMode.balanced => 'Balanced',
    RecommendationMode.adventurous => 'Adventurous',
  };
  final energyLabel = switch (profile.energyFilter) {
    EnergyFilter.all => 'All',
    EnergyFilter.lightKeynotes => 'Light keynotes',
    EnergyFilter.deepWorkshops => 'Deep workshops',
  };
  return '$modeLabel · $energyLabel';
}

Future<void> showPersonalizeSheet(BuildContext context) async {
  final profileState = context.read<ProfileState>();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personalize recommendations',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Recommendation mode',
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ListenableBuilder(
                listenable: profileState,
                builder: (context, _) {
                  final profile = profileState.profile;
                  return SegmentedButton<RecommendationMode>(
                    segments: const [
                      ButtonSegment(
                        value: RecommendationMode.focused,
                        label: Text('Focused'),
                      ),
                      ButtonSegment(
                        value: RecommendationMode.balanced,
                        label: Text('Balanced'),
                      ),
                      ButtonSegment(
                        value: RecommendationMode.adventurous,
                        label: Text('Adventurous'),
                      ),
                    ],
                    selected: {profile.recommendationMode},
                    onSelectionChanged: (value) {
                      profileState.updatePreferences(
                        recommendationMode: value.first,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Text('Energy', style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 8),
              ListenableBuilder(
                listenable: profileState,
                builder: (context, _) {
                  final profile = profileState.profile;
                  return Wrap(
                    spacing: 6,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: profile.energyFilter == EnergyFilter.all,
                        onSelected: (_) => profileState.updatePreferences(
                          energyFilter: EnergyFilter.all,
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('Light keynotes'),
                        selected:
                            profile.energyFilter == EnergyFilter.lightKeynotes,
                        onSelected: (_) => profileState.updatePreferences(
                          energyFilter: EnergyFilter.lightKeynotes,
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('Deep workshops'),
                        selected:
                            profile.energyFilter == EnergyFilter.deepWorkshops,
                        onSelected: (_) => profileState.updatePreferences(
                          energyFilter: EnergyFilter.deepWorkshops,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                personalizeSummary(profileState.profile),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => ctx.pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
