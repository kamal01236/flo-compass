import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/features/discover/discover_screen.dart';
import 'package:flo_compass/providers/app_settings_provider.dart';
import 'package:flo_compass/providers/engagement_provider.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/providers/profile_provider.dart';
import '../support/test_agenda_alerts_provider.dart';
import '../support/test_localizations.dart';

List<Session> _mockSessions(int count) {
  return List.generate(
    count,
    (i) => Session(
      id: 's-${i.toString().padLeft(3, '0')}',
      title: 'Session $i',
      abstract: 'Abstract $i',
      day: 'Day ${(i % 3) + 1}',
      startTime: '${(9 + (i % 8)).toString().padLeft(2, '0')}:00',
      endTime: '${(10 + (i % 8)).toString().padLeft(2, '0')}:00',
      venueId: 'ven-G01',
      trackId: 'trk-01',
      speakerIds: ['spk-001'],
      tags: ['genai'],
      format: 'Talk',
      level: 'beginner',
      featured: i.isEven,
      capacity: 50,
      building: 'Nagarro Gurgaon Office',
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('scroll to bottom loads more sessions without layout crash', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final event = EventState();
    final profile = ProfileState(prefs: prefs);
    final plan = PlanState(prefs: prefs);
    final engagement = EngagementState(prefs: prefs);
    final appSettings = AppSettingsState(prefs: prefs);

    await profile.init();
    profile.profile = const UserProfile(
      role: AttendeeRole.engineer,
      interests: ['genai'],
      onboardingComplete: true,
    );
    await plan.init();
    await engagement.init();
    await appSettings.init();

    event.loading = false;
    event.sessions = _mockSessions(85);
    event.venues = const [
      Venue(
        id: 'ven-G01',
        name: 'Ground Pod 1',
        floor: 'G',
        zone: 'Pod',
        wing: 'N',
        capacity: 40,
        building: 'Nagarro Gurgaon Office',
      ),
    ];
    event.tracks = const [
      Track(id: 'trk-01', name: 'GenAI', tags: ['genai'], color: '#10B981'),
    ];
    event.speakers = const [
      Speaker(
        id: 'spk-001',
        name: 'Alex Chen',
        title: 'CTO',
        bio: 'Bio',
        photoAsset: 'assets/images/speakers/spk-001.png',
        tier: 1,
      ),
    ];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: event),
          ChangeNotifierProvider.value(value: profile),
          ChangeNotifierProvider.value(value: plan),
          ChangeNotifierProvider.value(value: engagement),
          ChangeNotifierProvider.value(value: appSettings),
          testAgendaAlertsProvider(),
        ],
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            localizationsDelegates: testLocalizationDelegates,
            supportedLocales: testSupportedLocales,
            home: const DiscoverScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.textContaining('sessions'), findsWidgets);

    final scrollable = find.byType(Scrollable);
    expect(scrollable, findsWidgets);

    for (var pass = 0; pass < 24; pass++) {
      await tester.drag(scrollable.last, const Offset(0, -500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);

      final loadMore = find.text('Load more');
      if (loadMore.evaluate().isNotEmpty) {
        await tester.ensureVisible(loadMore);
        await tester.tap(loadMore);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      }
    }

    expect(find.text('Load more'), findsNothing);
    expect(tester.takeException(), isNull);

    event.dispose();
  });
}
