// Retained regression test: guarantees `kTourCompanionSampleQuery` returns
// a semantically grounded companion pack against the real Flo 2026 mock
// dataset. During the tour polish plan we compared "Fix my 11am clash" vs
// "Where can I park my car?"; the parking query is grounded in explicit
// amenity data whereas the clash query only yields featured-session
// padding, so the tour prefill ships with the parking query.
@Tags(['tour-companion-query'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/data/repositories/mock_event_repository.dart';
import 'package:flo_compass/data/services/companion_knowledge_retriever.dart';
import 'package:flo_compass/shared/tour/tour_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final retriever = CompanionKnowledgeRetriever();
  final repo = MockEventRepository(strictIntegrity: false);

  late CompanionContext Function(String query) ctxFor;

  setUpAll(() async {
    final sessions = await repo.loadSessions();
    final venues = await repo.loadVenues();
    final amenities = await repo.loadAmenities();
    final speakers = await repo.loadSpeakers();
    final navHints = await repo.loadNavigationHints();

    ctxFor = (String query) => CompanionContext(
      query: query,
      sessions: sessions,
      speakers: speakers,
      venues: venues,
      tracks: const [],
      amenities: amenities,
      navigationHints: navHints,
      profile: UserProfile(
        role: AttendeeRole.engineer,
        interests: const ['cursor', 'genai', 'leadership'],
        onboardingComplete: true,
      ),
      plannedSessions: const [],
      currentDay: 'Day 1',
      minutesUntil: (_) => 30,
    );
  });

  test('parking prefill returns parking amenities directly', () {
    final pack = retriever.retrieve(ctxFor('Where can I park my car?'));
    expect(pack.amenities, isNotEmpty);
    expect(
      pack.amenities.any((a) => a.type == 'parking_car'),
      isTrue,
      reason: 'expected at least one parking_car amenity in the pack',
    );
  });

  test('kTourCompanionSampleQuery is grounded in mock data', () {
    final pack = retriever.retrieve(ctxFor(kTourCompanionSampleQuery));
    final grounded =
        pack.amenities.isNotEmpty ||
        pack.venues.isNotEmpty ||
        pack.speakers.isNotEmpty ||
        pack.floorStories.isNotEmpty ||
        pack.navigationHints.isNotEmpty;
    expect(
      grounded,
      isTrue,
      reason:
          'kTourCompanionSampleQuery ($kTourCompanionSampleQuery) should '
          'return at least one non-session match from the Flo 2026 mock '
          'dataset (featured sessions alone are the noise floor).',
    );
  });
}
