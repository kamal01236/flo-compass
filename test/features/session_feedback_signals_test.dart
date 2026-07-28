import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/data/services/behavior_signal_service.dart';
import 'package:flo_compass/data/services/recommendation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const genaiSession = Session(
    id: 's-genai',
    title: 'GenAI Deep Dive',
    abstract: 'a',
    day: 'Day 1',
    startTime: '11:00',
    endTime: '12:00',
    venueId: 'ven-1',
    trackId: 'trk-01',
    speakerIds: [],
    tags: ['genai'],
    format: 'Talk',
    level: 'beginner',
    featured: false,
    capacity: 50,
    building: 'Nagarro Gurgaon Office',
  );

  const otherSession = Session(
    id: 's-cloud',
    title: 'Cloud Native',
    abstract: 'b',
    day: 'Day 1',
    startTime: '11:00',
    endTime: '12:00',
    venueId: 'ven-2',
    trackId: 'trk-02',
    speakerIds: [],
    tags: ['cloud'],
    format: 'Talk',
    level: 'beginner',
    featured: false,
    capacity: 50,
    building: 'Nagarro Gurgaon Office',
  );

  const profile = UserProfile(
    role: AttendeeRole.engineer,
    interests: ['genai', 'cloud'],
    onboardingComplete: true,
  );

  test('positive feedback boosts ranking for matching tags', () async {
    SharedPreferences.setMockInitialValues({});
    final service = BehaviorSignalService();
    await service.recordPositiveFeedback(
      tags: const ['genai'],
      trackId: 'trk-01',
    );
    await service.recordPositiveFeedback(
      tags: const ['genai'],
      trackId: 'trk-01',
    );
    final snapshot = await service.load();

    final recommendation = RecommendationService();
    final ranked = recommendation.rankSessions(
      sessions: [otherSession, genaiSession],
      speakers: const [],
      tracks: const [],
      profile: profile,
      behaviorSnapshot: snapshot,
    );

    expect(ranked.first.session.id, 's-genai');
    expect(
      ranked.first.matchReasons.any((r) => r.contains('liked similar')),
      isTrue,
    );
  });
}
