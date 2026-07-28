import 'user_profile.dart';

/// Mock partner DTO loaded from flo_meets_mock_partners.json.
class FloMeetPartner {
  const FloMeetPartner({
    required this.id,
    required this.nickname,
    required this.identity,
    required this.openTo,
    required this.experienceYears,
    required this.purposes,
    required this.personalInterests,
    required this.personalityTraits,
    required this.enabledSlots,
    required this.meetAmenityId,
    required this.role,
    required this.professionalInterests,
    this.optedIn = true,
    this.meetNote = '',
    this.contactMedium = 'none',
  });

  final String id;
  final String nickname;
  final String identity;
  final List<String> openTo;
  final int experienceYears;
  final List<String> purposes;
  final List<String> personalInterests;
  final List<String> personalityTraits;
  final List<String> enabledSlots;
  final String meetAmenityId;
  final AttendeeRole role;
  final List<String> professionalInterests;
  final bool optedIn;
  final String meetNote;
  final String contactMedium;

  FloMeetPartner copyWith({
    String? id,
    String? nickname,
    String? identity,
    List<String>? openTo,
    int? experienceYears,
    List<String>? purposes,
    List<String>? personalInterests,
    List<String>? personalityTraits,
    List<String>? enabledSlots,
    String? meetAmenityId,
    AttendeeRole? role,
    List<String>? professionalInterests,
    bool? optedIn,
    String? meetNote,
    String? contactMedium,
  }) {
    return FloMeetPartner(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      identity: identity ?? this.identity,
      openTo: openTo ?? this.openTo,
      experienceYears: experienceYears ?? this.experienceYears,
      purposes: purposes ?? this.purposes,
      personalInterests: personalInterests ?? this.personalInterests,
      personalityTraits: personalityTraits ?? this.personalityTraits,
      enabledSlots: enabledSlots ?? this.enabledSlots,
      meetAmenityId: meetAmenityId ?? this.meetAmenityId,
      role: role ?? this.role,
      professionalInterests:
          professionalInterests ?? this.professionalInterests,
      optedIn: optedIn ?? this.optedIn,
      meetNote: meetNote ?? this.meetNote,
      contactMedium: contactMedium ?? this.contactMedium,
    );
  }

  factory FloMeetPartner.fromJson(Map<String, dynamic> json) {
    return FloMeetPartner(
      id: json['id'] as String,
      nickname: json['nickname'] as String? ?? '',
      identity: json['identity'] as String? ?? '',
      openTo: (json['openTo'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      experienceYears: json['experienceYears'] as int? ?? 0,
      purposes: (json['purposes'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      personalInterests: (json['personalInterests'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      personalityTraits: (json['personalityTraits'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      enabledSlots: (json['enabledSlots'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      meetAmenityId: json['meetAmenityId'] as String? ?? '',
      role: AttendeeRoleX.fromId(json['role'] as String?) ?? AttendeeRole.guest,
      professionalInterests:
          (json['professionalInterests'] as List<dynamic>? ?? [])
              .map((e) => e as String)
              .toList(),
      optedIn: json['optedIn'] as bool? ?? true,
      meetNote: json['meetNote'] as String? ?? '',
      contactMedium: json['contactMedium'] as String? ?? 'none',
    );
  }
}
