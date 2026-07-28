import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/data/models/flo_meet_partner.dart';
import 'package:flo_compass/data/models/flo_meets_preferences.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/data/services/flo_meets_service.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/flo_meets_provider.dart';

/// Bounded pumps + dispose helper for Flo Meets widget tests.
class TestFloMeetsHarness {
  TestFloMeetsHarness._();

  static Future<FloMeetsState> createState() async {
    SharedPreferences.setMockInitialValues({});
    final state = FloMeetsState(
      service: FloMeetsService(weights: FloMeetsMatchWeights.defaults),
    );
    await state.init();
    return state;
  }

  static EventState createEvent() {
    final event = EventState();
    event.loading = false;
    return event;
  }

  static const samplePrefs = FloMeetsPreferences(
    optedIn: true,
    nickname: 'Pilot',
    identity: 'female',
    openTo: ['all'],
    experienceYears: 8,
    purposes: ['networking'],
    personalInterests: ['photography'],
    personalityTraits: ['curious'],
    enabledSlots: ['Day_1_0900'],
    meetAmenityId: 'am-6-coffee',
  );

  static final samplePartner = FloMeetPartner(
    id: 'mp-test',
    nickname: 'Summit',
    identity: 'male',
    openTo: ['all'],
    experienceYears: 7,
    purposes: ['networking'],
    personalInterests: ['photography'],
    personalityTraits: ['curious'],
    enabledSlots: ['Day_1_0900'],
    meetAmenityId: 'am-6-coffee',
    role: AttendeeRole.engineer,
    professionalInterests: ['genai'],
  );

  static Future<void> disposeEvent(EventState event) async {
    event.dispose();
  }
}

void main() {
  test('harness creates isolated FloMeetsState', () async {
    final state = await TestFloMeetsHarness.createState();
    expect(state.preferences.isSetupComplete, isFalse);
  });
}
