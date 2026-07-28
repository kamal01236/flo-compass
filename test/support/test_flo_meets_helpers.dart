import 'package:flo_compass/data/models/flo_meet.dart';
import 'package:flo_compass/data/models/flo_meet_partner.dart';
import 'package:flo_compass/data/models/flo_meets_preferences.dart';
import 'package:flo_compass/data/models/networking_card.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/data/services/flo_meets_service.dart';
import 'package:flo_compass/data/services/flo_meets_slot_catalog.dart';

import 'package:flo_compass/providers/flo_meets_provider.dart';

Future<void> initFloMeetsForTests(
  FloMeetsState state, {
  String subject = 'test-subject',
}) async {
  await state.init();
  await state.bindAuthSubject(subject);
}

FloMeetsPreferences buildValidFloMeetsPreferences({
  required List<String> enabledSlots,
}) {
  return FloMeetsPreferences(
    optedIn: true,
    nickname: 'Avery',
    identity: FloMeetIdentity.nonBinary,
    openTo: const [FloMeetOpenTo.all],
    experienceYears: 5,
    purposes: const ['networking'],
    personalInterests: const ['hiking'],
    personalityTraits: const ['curious'],
    enabledSlots: enabledSlots,
    meetAmenityId: 'amenity-1',
    contactMedium: FloMeetContactMedium.email,
    meetNote: 'Say hello',
  );
}

class TestFloMeetsService extends FloMeetsService {
  TestFloMeetsService({this.partnerId = 'partner-001'});

  final String partnerId;

  @override
  Future<FloMeet?> runRound({
    required FloMeetsPreferences userPrefs,
    required AttendeeRole userRole,
    required List<String> professionalInterests,
    required String slotKey,
    required String eventDay,
    required Set<String> metPartnerIds,
    required Set<String> slotPartnerIdsToday,
    required bool isAuthenticated,
    required NetworkingCard? networkingCard,
    required DateTime matchedAt,
    List<FloMeetPartner>? partners,
  }) async {
    if (!isAuthenticated || !userPrefs.isSetupComplete) return null;
    if (metPartnerIds.contains(partnerId)) return null;
    final slot = FloMeetsSlotCatalog.slotByKey(slotKey);
    if (slot == null) return null;

    return FloMeet(
      id: 'meet-$slotKey-${matchedAt.millisecondsSinceEpoch}',
      slotKey: slotKey,
      day: eventDay,
      windowStart: FloMeetsSlotCatalog.windowStart(slot, eventDay),
      windowEnd: FloMeetsSlotCatalog.windowEnd(slot, eventDay),
      partnerId: partnerId,
      partnerNickname: 'Avery',
      meetAmenityId: userPrefs.meetAmenityId,
      contactMedium: userPrefs.contactMedium,
      meetNote: userPrefs.meetNote,
      matchedAt: matchedAt,
    );
  }
}
