import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/providers/companion_provider.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ask passes initialSessionId into CompanionContext', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final event = EventState();
    event.loading = false;
    event.sessions = const [
      Session(
        id: 's-001',
        title: 'CEO Keynote',
        abstract: 'a',
        day: 'Day 1',
        startTime: '10:00',
        endTime: '11:00',
        venueId: 'ven-1',
        trackId: 'trk-01',
        speakerIds: [],
        tags: ['genai'],
        format: 'Keynote',
        level: 'beginner',
        featured: true,
        capacity: 100,
        building: 'Nagarro Gurgaon Office',
      ),
    ];
    final plan = PlanState(prefs: prefs);
    await plan.init();
    final companion = CompanionState();

    await companion.ask(
      query: 'Tell me about CEO Keynote',
      event: event,
      plan: plan,
      profile: const UserProfile(
        role: AttendeeRole.engineer,
        interests: ['genai'],
        onboardingComplete: true,
      ),
      initialSessionId: 's-001',
    );

    expect(companion.lastReferencedSessionId, 's-001');
    event.dispose();
  });
}
