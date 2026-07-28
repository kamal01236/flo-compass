import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/dtos/session_dto.dart';
import 'package:flo_compass/data/mappers/session_mapper.dart';
import 'package:flo_compass/data/models/user_profile.dart';

void main() {
  test('Session round-trip fromJson via DTO mapper', () {
    final json = {
      'id': 's-001',
      'title': 'Test',
      'abstract': 'Abstract',
      'day': 'Day 1',
      'startTime': '09:00',
      'endTime': '10:00',
      'venueId': 'ven-G01',
      'trackId': 'trk-01',
      'speakerIds': ['spk-001'],
      'tags': ['genai'],
      'format': 'Keynote',
      'level': 'beginner',
      'featured': true,
      'capacity': 500,
      'building': 'Nagarro Gurgaon Office',
    };
    final session = sessionFromDto(SessionDto.fromJson(json));
    expect(session.id, 's-001');
    expect(session.featured, isTrue);
  });

  test('UserProfile toJson/fromJson', () {
    const profile = UserProfile(
      role: AttendeeRole.engineer,
      interests: ['cursor', 'genai'],
      onboardingComplete: true,
    );
    final restored = UserProfile.fromJson(profile.toJson());
    expect(restored.role, AttendeeRole.engineer);
    expect(restored.interests, ['cursor', 'genai']);
  });

  test('InterestTag id mapping', () {
    expect(InterestTag.llmAgents.id, 'llm_agents');
    expect(InterestTagX.fromId('ceo_vision'), InterestTag.ceoVision);
  });
}
