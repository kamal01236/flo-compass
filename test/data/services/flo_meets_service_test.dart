import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/flo_meet_partner.dart';
import 'package:flo_compass/data/models/flo_meets_preferences.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/data/services/flo_meets_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = FloMeetsService(weights: FloMeetsMatchWeights.defaults);

  final userPrefs = FloMeetsPreferences(
    optedIn: true,
    nickname: 'Pilot',
    identity: FloMeetIdentity.female,
    openTo: [FloMeetOpenTo.all],
    experienceYears: 8,
    purposes: ['networking'],
    personalInterests: ['photography'],
    personalityTraits: ['curious'],
    enabledSlots: ['Day_1_0900'],
    meetAmenityId: 'am-6-coffee',
  );

  final partner = FloMeetPartner(
    id: 'mp-001',
    nickname: 'Summit',
    identity: FloMeetIdentity.female,
    openTo: [FloMeetOpenTo.all],
    experienceYears: 6,
    purposes: ['networking'],
    personalInterests: ['photography', 'travel'],
    personalityTraits: ['curious'],
    enabledSlots: ['Day_1_0900'],
    meetAmenityId: 'am-6-coffee',
    role: AttendeeRole.architect,
    professionalInterests: ['genai', 'cloud'],
  );

  final farExperience = partner.copyWith(id: 'mp-far', experienceYears: 20);

  group('FloMeetsService hard filters', () {
    test('requires setup complete preferences', () {
      final incomplete = FloMeetsPreferences.empty;
      final result = service.filterCandidates(
        userPrefs: incomplete,
        userRole: AttendeeRole.engineer,
        professionalInterests: ['genai'],
        slotKey: 'Day_1_0900',
        metPartnerIds: {},
        pool: [partner],
        isAuthenticated: true,
      );
      expect(result, isEmpty);
    });

    test('requires authentication', () {
      final result = service.filterCandidates(
        userPrefs: userPrefs,
        userRole: AttendeeRole.engineer,
        professionalInterests: ['genai'],
        slotKey: 'Day_1_0900',
        metPartnerIds: {},
        pool: [partner],
        isAuthenticated: false,
      );
      expect(result, isEmpty);
    });

    test('requires experience within ±3 years', () {
      final result = service.filterCandidates(
        userPrefs: userPrefs,
        userRole: AttendeeRole.engineer,
        professionalInterests: ['genai'],
        slotKey: 'Day_1_0900',
        metPartnerIds: {},
        pool: [farExperience],
        isAuthenticated: true,
      );
      expect(result, isEmpty);
    });

    test('blocks repeat partners', () {
      final result = service.filterCandidates(
        userPrefs: userPrefs,
        userRole: AttendeeRole.engineer,
        professionalInterests: ['genai'],
        slotKey: 'Day_1_0900',
        metPartnerIds: {'mp-001'},
        pool: [partner],
        isAuthenticated: true,
      );
      expect(result, isEmpty);
    });

    test('passes compatible partner', () {
      final result = service.filterCandidates(
        userPrefs: userPrefs,
        userRole: AttendeeRole.engineer,
        professionalInterests: ['genai', 'cloud'],
        slotKey: 'Day_1_0900',
        metPartnerIds: {},
        pool: [partner],
        isAuthenticated: true,
      );
      expect(result, hasLength(1));
    });
  });

  test('scoreCandidate returns higher score for overlapping tags', () {
    final low = service.scoreCandidate(
      userPrefs: userPrefs.copyWith(purposes: ['friendship']),
      userRole: AttendeeRole.engineer,
      professionalInterests: ['healthcare'],
      partner: partner,
      weights: FloMeetsMatchWeights.defaults,
    );
    final high = service.scoreCandidate(
      userPrefs: userPrefs,
      userRole: AttendeeRole.engineer,
      professionalInterests: ['genai', 'cloud'],
      partner: partner,
      weights: FloMeetsMatchWeights.defaults,
    );
    expect(high, greaterThan(low));
  });

  test('matchPercent and rankPartnersInRoom order by percent', () {
    final percent = service.matchPercent(
      userPrefs: userPrefs,
      userRole: AttendeeRole.engineer,
      professionalInterests: ['genai', 'cloud'],
      partner: partner,
      weights: FloMeetsMatchWeights.defaults,
    );
    expect(percent, inInclusiveRange(0, 100));

    final lowPartner = partner.copyWith(
      id: 'mp-low',
      purposes: const ['friendship'],
      professionalInterests: const ['healthcare'],
    );
    final ranked = service.rankPartnersInRoom(
      userPrefs: userPrefs,
      userRole: AttendeeRole.engineer,
      professionalInterests: ['genai', 'cloud'],
      partners: [lowPartner, partner],
      weights: FloMeetsMatchWeights.defaults,
    );
    expect(ranked.first.partner.id, 'mp-001');
    expect(
      ranked.first.matchPercent,
      greaterThanOrEqualTo(ranked.last.matchPercent),
    );
  });
}
