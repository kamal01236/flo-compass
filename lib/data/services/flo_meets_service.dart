import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/flo_meet.dart';
import '../models/flo_meet_partner.dart';
import '../models/flo_meets_preferences.dart';
import '../models/networking_card.dart';
import '../models/user_profile.dart';
import 'flo_meets_slot_catalog.dart';

class FloMeetsMatchWeights {
  const FloMeetsMatchWeights({
    required this.professionalInterests,
    required this.connectionPurpose,
    required this.personalInterests,
    required this.personalityTraits,
    required this.roleIndustryFit,
    required this.freshness,
  });

  final double professionalInterests;
  final double connectionPurpose;
  final double personalInterests;
  final double personalityTraits;
  final double roleIndustryFit;
  final double freshness;

  factory FloMeetsMatchWeights.fromJson(Map<String, dynamic> json) {
    return FloMeetsMatchWeights(
      professionalInterests:
          (json['professionalInterests'] as num?)?.toDouble() ?? 0.35,
      connectionPurpose:
          (json['connectionPurpose'] as num?)?.toDouble() ?? 0.25,
      personalInterests:
          (json['personalInterests'] as num?)?.toDouble() ?? 0.15,
      personalityTraits:
          (json['personalityTraits'] as num?)?.toDouble() ?? 0.10,
      roleIndustryFit: (json['roleIndustryFit'] as num?)?.toDouble() ?? 0.10,
      freshness: (json['freshness'] as num?)?.toDouble() ?? 0.05,
    );
  }

  static const defaults = FloMeetsMatchWeights(
    professionalInterests: 0.35,
    connectionPurpose: 0.25,
    personalInterests: 0.15,
    personalityTraits: 0.10,
    roleIndustryFit: 0.10,
    freshness: 0.05,
  );
}

class FloMeetsService {
  FloMeetsService({FloMeetsMatchWeights? weights}) : _weights = weights;

  FloMeetsMatchWeights? _weights;
  List<FloMeetPartner>? _mockPartners;

  Future<FloMeetsMatchWeights> loadWeights() async {
    if (_weights != null) return _weights!;
    final raw = await rootBundle.loadString(
      'assets/data/flo_meets_match_weights.json',
    );
    _weights = FloMeetsMatchWeights.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    return _weights!;
  }

  Future<List<FloMeetPartner>> loadMockPartners() async {
    if (_mockPartners != null) return _mockPartners!;
    final raw = await rootBundle.loadString(
      'assets/data/flo_meets_mock_partners.json',
    );
    final list = jsonDecode(raw) as List<dynamic>;
    _mockPartners = list
        .map((e) => FloMeetPartner.fromJson(e as Map<String, dynamic>))
        .toList();
    return _mockPartners!;
  }

  List<FloMeetPartner> filterCandidates({
    required FloMeetsPreferences userPrefs,
    required AttendeeRole userRole,
    required List<String> professionalInterests,
    required String slotKey,
    required Set<String> metPartnerIds,
    required List<FloMeetPartner> pool,
    required bool isAuthenticated,
  }) {
    if (!isAuthenticated || !userPrefs.isSetupComplete) return [];
    if (!userPrefs.enabledSlots.contains(slotKey)) return [];
    if (userPrefs.experienceYears == null) return [];

    return pool.where((partner) {
      if (!partner.enabledSlots.contains(slotKey)) return false;
      if (metPartnerIds.contains(partner.id)) return false;
      if (!_experienceCompatible(
        userPrefs.experienceYears!,
        partner.experienceYears,
      )) {
        return false;
      }
      if (!_mutualIdentity(userPrefs, partner)) return false;
      return true;
    }).toList();
  }

  double scoreCandidate({
    required FloMeetsPreferences userPrefs,
    required AttendeeRole userRole,
    required List<String> professionalInterests,
    required FloMeetPartner partner,
    required FloMeetsMatchWeights weights,
  }) {
    final profScore = _jaccard(
      professionalInterests.toSet(),
      partner.professionalInterests.toSet(),
    );
    final purposeScore = _jaccard(
      userPrefs.purposes.toSet(),
      partner.purposes.toSet(),
    );
    final personalScore = _jaccard(
      userPrefs.personalInterests.toSet(),
      partner.personalInterests.toSet(),
    );
    final personalityScore = _jaccard(
      userPrefs.personalityTraits.toSet(),
      partner.personalityTraits.toSet(),
    );
    final roleScore = _roleFit(userRole, partner.role, professionalInterests);
    const freshnessScore = 1.0;

    return weights.professionalInterests * profScore +
        weights.connectionPurpose * purposeScore +
        weights.personalInterests * personalScore +
        weights.personalityTraits * personalityScore +
        weights.roleIndustryFit * roleScore +
        weights.freshness * freshnessScore;
  }

  int matchPercent({
    required FloMeetsPreferences userPrefs,
    required AttendeeRole userRole,
    required List<String> professionalInterests,
    required FloMeetPartner partner,
    required FloMeetsMatchWeights weights,
  }) {
    final score = scoreCandidate(
      userPrefs: userPrefs,
      userRole: userRole,
      professionalInterests: professionalInterests,
      partner: partner,
      weights: weights,
    );
    return (score * 100).round().clamp(0, 100);
  }

  List<String> overlapTags({
    required FloMeetsPreferences userPrefs,
    required List<String> professionalInterests,
    required FloMeetPartner partner,
  }) {
    final tags = <String>{
      ...professionalInterests.toSet().intersection(
        partner.professionalInterests.toSet(),
      ),
      ...userPrefs.purposes.toSet().intersection(partner.purposes.toSet()),
      ...userPrefs.personalInterests.toSet().intersection(
        partner.personalInterests.toSet(),
      ),
      ...userPrefs.personalityTraits.toSet().intersection(
        partner.personalityTraits.toSet(),
      ),
    };
    return tags.toList()..sort();
  }

  /// Ranks room partners by match % (desc), then partner id for stability.
  List<RankedRoomMember> rankPartnersInRoom({
    required FloMeetsPreferences userPrefs,
    required AttendeeRole userRole,
    required List<String> professionalInterests,
    required List<FloMeetPartner> partners,
    required FloMeetsMatchWeights weights,
  }) {
    final ranked = partners.map((partner) {
      final percent = matchPercent(
        userPrefs: userPrefs,
        userRole: userRole,
        professionalInterests: professionalInterests,
        partner: partner,
        weights: weights,
      );
      return RankedRoomMember(
        partner: partner,
        matchPercent: percent,
        overlapTags: overlapTags(
          userPrefs: userPrefs,
          professionalInterests: professionalInterests,
          partner: partner,
        ),
      );
    }).toList();
    ranked.sort((a, b) {
      final cmp = b.matchPercent.compareTo(a.matchPercent);
      if (cmp != 0) return cmp;
      return a.partner.id.compareTo(b.partner.id);
    });
    return ranked;
  }

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
    if (slotPartnerIdsToday.isNotEmpty) return null;
    final pool = partners ?? await loadMockPartners();
    final weights = await loadWeights();
    final candidates = filterCandidates(
      userPrefs: userPrefs,
      userRole: userRole,
      professionalInterests: professionalInterests,
      slotKey: slotKey,
      metPartnerIds: metPartnerIds,
      pool: pool,
      isAuthenticated: isAuthenticated,
    );
    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final scoreA = scoreCandidate(
        userPrefs: userPrefs,
        userRole: userRole,
        professionalInterests: professionalInterests,
        partner: a,
        weights: weights,
      );
      final scoreB = scoreCandidate(
        userPrefs: userPrefs,
        userRole: userRole,
        professionalInterests: professionalInterests,
        partner: b,
        weights: weights,
      );
      final cmp = scoreB.compareTo(scoreA);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });

    final partner = candidates.first;
    final slot = FloMeetsSlotCatalog.slotByKey(slotKey);
    if (slot == null) return null;

    final contact = _contactSnapshot(networkingCard, userPrefs.contactMedium);

    return FloMeet(
      id: 'meet-$slotKey-${matchedAt.millisecondsSinceEpoch}',
      slotKey: slotKey,
      day: eventDay,
      windowStart: FloMeetsSlotCatalog.windowStart(slot, eventDay),
      windowEnd: FloMeetsSlotCatalog.windowEnd(slot, eventDay),
      partnerId: partner.id,
      partnerNickname: partner.nickname,
      meetAmenityId: userPrefs.meetAmenityId,
      contactMedium: userPrefs.contactMedium,
      contactSnapshot: contact,
      meetNote: userPrefs.meetNote,
      matchedAt: matchedAt,
    );
  }

  static bool _experienceCompatible(int a, int b) => (a - b).abs() <= 3;

  static bool _mutualIdentity(
    FloMeetsPreferences user,
    FloMeetPartner partner,
  ) {
    return _openToAccepts(user.openTo, partner.identity) &&
        _openToAccepts(partner.openTo, user.identity);
  }

  static bool _openToAccepts(List<String> openTo, String identity) {
    if (openTo.contains(FloMeetOpenTo.all)) return true;
    return openTo.contains(identity);
  }

  static double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty && b.isEmpty) return 0;
    final intersection = a.intersection(b).length;
    final union = a.union(b).length;
    if (union == 0) return 0;
    return intersection / union;
  }

  static double _roleFit(
    AttendeeRole userRole,
    AttendeeRole partnerRole,
    List<String> interests,
  ) {
    if (userRole == partnerRole) return 1.0;
    final complementary = {
      AttendeeRole.engineer: AttendeeRole.architect,
      AttendeeRole.productManager: AttendeeRole.engineer,
      AttendeeRole.consultant: AttendeeRole.executive,
    };
    if (complementary[userRole] == partnerRole ||
        complementary[partnerRole] == userRole) {
      return 0.8;
    }
    if (interests.isNotEmpty) return 0.5;
    return 0.3;
  }

  static ShareField? _contactSnapshot(
    NetworkingCard? card,
    FloMeetContactMedium medium,
  ) {
    if (card == null || medium == FloMeetContactMedium.none) return null;
    final field = switch (medium) {
      FloMeetContactMedium.email => card.email,
      FloMeetContactMedium.phone => card.phoneE164,
      FloMeetContactMedium.linkedin => card.linkedInUrl,
      FloMeetContactMedium.none => null,
    };
    if (field == null || !field.visible || field.value.trim().isEmpty) {
      return null;
    }
    return field;
  }
}

/// Amenity types eligible as Flo Meets meeting points.
const floMeetAmenityTypes = {'help_desk', 'coffee', 'garden', 'quiet_zone'};

/// Partner ranked for display inside a match room.
class RankedRoomMember {
  const RankedRoomMember({
    required this.partner,
    required this.matchPercent,
    this.overlapTags = const [],
  });

  final FloMeetPartner partner;
  final int matchPercent;
  final List<String> overlapTags;
}
