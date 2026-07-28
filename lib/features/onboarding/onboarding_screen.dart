import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/analytics/analytics_tracker.dart';
import '../../data/models/user_profile.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/engagement_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/profile_provider.dart';
import '../../shared/widgets/shared_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  AttendeeRole _role = AttendeeRole.engineer;
  AttendanceMode _attendanceMode = AttendanceMode.onSite;
  final Set<String> _interests = {};

  bool get _isEditMode =>
      GoRouterState.of(context).uri.queryParameters['edit'] == '1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isEditMode) {
        final profile = context.read<ProfileState>().profile;
        setState(() {
          _role = profile.role;
          _attendanceMode = profile.attendanceMode;
          _interests
            ..clear()
            ..addAll(profile.interests);
        });
      }
      trackAnalytics(
        'onboarding_step',
        properties: {'step': 'interests', 'edit_mode': _isEditMode},
      );
    });
  }

  bool get _stepValid => _interests.length >= 3 && _interests.length <= 7;

  Future<void> _finishOnboarding() async {
    final profileState = context.read<ProfileState>();
    final engagement = context.read<EngagementState>();
    final appSettings = context.read<AppSettingsState>();
    final router = GoRouter.of(context);

    await profileState.saveProfile(
      role: _role,
      interests: _interests.toList(),
      attendanceMode: _attendanceMode,
    );

    if (!_isEditMode) {
      await engagement.onOnboardingCompleted();
      await appSettings.queueTourStart();
      await trackAnalytics(
        'onboarding_complete',
        properties: {
          'role': _role.name,
          'attendance_mode': _attendanceMode.name,
          'interest_count': _interests.length,
        },
      );
    }

    if (context.mounted) router.go('/discover');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: ResponsiveLayout(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildInterestsStep(context, l10n),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _stepValid ? _finishOnboarding : null,
                    child: Text(
                      _interests.length < 3
                          ? l10n.onboardingSelectMin
                          : l10n.onboardingContinue(_interests.length),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInterestsStep(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GradientTitle(
          _isEditMode ? l10n.onboardingEditTitle : l10n.onboardingWelcomeTitle,
        ),
        const SizedBox(height: 8),
        Text(
          _isEditMode ? l10n.onboardingEditBody : l10n.onboardingWelcomeBody,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.onboardingRoleTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final role in AttendeeRole.values)
              ChoiceChip(
                label: Text(role.label),
                selected: _role == role,
                showCheckmark: true,
                onSelected: (_) => setState(() => _role = role),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          l10n.onboardingAttendanceTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SegmentedButton<AttendanceMode>(
          segments: [
            ButtonSegment(
              value: AttendanceMode.onSite,
              label: Text(l10n.onboardingOnSite),
              icon: const Icon(Icons.location_on_outlined),
            ),
            ButtonSegment(
              value: AttendanceMode.remote,
              label: Text(l10n.onboardingRemote),
              icon: const Icon(Icons.live_tv_outlined),
            ),
          ],
          selected: {_attendanceMode},
          onSelectionChanged: (selected) {
            if (selected.isEmpty) return;
            setState(() => _attendanceMode = selected.first);
          },
        ),
        const SizedBox(height: 24),
        Text(
          l10n.onboardingInterestsTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _interestGroup(
          l10n.onboardingInterestGroupAiData,
          InterestTagX.aiData,
          l10n,
        ),
        _interestGroup(
          l10n.onboardingInterestGroupEngineering,
          InterestTagX.engineering,
          l10n,
        ),
        _interestGroup(
          l10n.onboardingInterestGroupStrategy,
          InterestTagX.strategy,
          l10n,
        ),
        _interestGroup(
          l10n.onboardingInterestGroupDomain,
          InterestTagX.domain,
          l10n,
        ),
        _interestGroup(
          l10n.onboardingInterestGroupCrossCutting,
          InterestTagX.crossCutting,
          l10n,
        ),
      ],
    );
  }

  Widget _interestGroup(
    String title,
    List<InterestTag> tags,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in tags)
                FilterChip(
                  label: Text(tag.label),
                  selected: _interests.contains(tag.id),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        if (_interests.length < 7) _interests.add(tag.id);
                      } else {
                        _interests.remove(tag.id);
                      }
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
