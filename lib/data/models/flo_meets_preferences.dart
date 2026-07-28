/// Flo Meets matching preferences (collected on first Meets open / editable later).
class FloMeetsPreferences {
  const FloMeetsPreferences({
    this.optedIn = false,
    this.nickname = '',
    this.identity = '',
    this.openTo = const [],
    this.experienceYears,
    this.purposes = const [],
    this.personalInterests = const [],
    this.personalityTraits = const [],
    this.enabledSlots = const [],
    this.meetAmenityId = '',
    this.contactMedium = FloMeetContactMedium.none,
    this.meetNote = '',
  });

  /// Legacy storage flag — product gating uses [isSetupComplete] only.
  /// Successful saves force `true` for backward-compatible JSON.
  final bool optedIn;
  final String nickname;
  final String identity;
  final List<String> openTo;
  final int? experienceYears;
  final List<String> purposes;
  final List<String> personalInterests;
  final List<String> personalityTraits;
  final List<String> enabledSlots;
  final String meetAmenityId;
  final FloMeetContactMedium contactMedium;
  final String meetNote;

  /// True when required matching fields are complete (unlocks hub).
  bool get isSetupComplete {
    if (nickname.trim().length < 3 || nickname.trim().length > 20) return false;
    if (identity.isEmpty) return false;
    if (openTo.isEmpty) return false;
    if (experienceYears == null) return false;
    if (purposes.isEmpty) return false;
    if (personalInterests.isEmpty) return false;
    if (personalityTraits.isEmpty) return false;
    if (enabledSlots.isEmpty) return false;
    if (meetAmenityId.isEmpty) return false;
    return true;
  }

  /// Legacy alias for [isSetupComplete].
  bool get isValidWhenOptedIn => isSetupComplete;

  FloMeetsPreferences copyWith({
    bool? optedIn,
    String? nickname,
    String? identity,
    List<String>? openTo,
    int? experienceYears,
    bool clearExperienceYears = false,
    List<String>? purposes,
    List<String>? personalInterests,
    List<String>? personalityTraits,
    List<String>? enabledSlots,
    String? meetAmenityId,
    FloMeetContactMedium? contactMedium,
    String? meetNote,
  }) {
    return FloMeetsPreferences(
      optedIn: optedIn ?? this.optedIn,
      nickname: nickname ?? this.nickname,
      identity: identity ?? this.identity,
      openTo: openTo ?? this.openTo,
      experienceYears: clearExperienceYears
          ? null
          : (experienceYears ?? this.experienceYears),
      purposes: purposes ?? this.purposes,
      personalInterests: personalInterests ?? this.personalInterests,
      personalityTraits: personalityTraits ?? this.personalityTraits,
      enabledSlots: enabledSlots ?? this.enabledSlots,
      meetAmenityId: meetAmenityId ?? this.meetAmenityId,
      contactMedium: contactMedium ?? this.contactMedium,
      meetNote: meetNote ?? this.meetNote,
    );
  }

  Map<String, dynamic> toJson() => {
    'optedIn': optedIn,
    'nickname': nickname,
    'identity': identity,
    'openTo': openTo,
    if (experienceYears != null) 'experienceYears': experienceYears,
    'purposes': purposes,
    'personalInterests': personalInterests,
    'personalityTraits': personalityTraits,
    'enabledSlots': enabledSlots,
    'meetAmenityId': meetAmenityId,
    'contactMedium': contactMedium.name,
    'meetNote': meetNote,
  };

  factory FloMeetsPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FloMeetsPreferences();
    return FloMeetsPreferences(
      optedIn: json['optedIn'] as bool? ?? false,
      nickname: json['nickname'] as String? ?? '',
      identity: json['identity'] as String? ?? '',
      openTo: (json['openTo'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      experienceYears: json['experienceYears'] as int?,
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
      contactMedium: FloMeetContactMediumX.fromId(
        json['contactMedium'] as String?,
      ),
      meetNote: json['meetNote'] as String? ?? '',
    );
  }

  static const empty = FloMeetsPreferences();

  /// Draft defaults for the preferences form (experience pre-filled).
  static FloMeetsPreferences defaults() => const FloMeetsPreferences(
    experienceYears: defaultExperienceYears,
    openTo: [FloMeetOpenTo.all],
  );

  static const defaultExperienceYears = 5;

  /// Coerces unset experience and forces [optedIn] for storage compat.
  FloMeetsPreferences coercedForSave() {
    final withExp = experienceYears == null
        ? copyWith(experienceYears: defaultExperienceYears)
        : this;
    return withExp.copyWith(optedIn: true);
  }
}

enum FloMeetContactMedium { none, email, phone, linkedin }

extension FloMeetContactMediumX on FloMeetContactMedium {
  String get id => name;

  static FloMeetContactMedium fromId(String? id) {
    return FloMeetContactMedium.values.firstWhere(
      (m) => m.name == id,
      orElse: () => FloMeetContactMedium.none,
    );
  }
}

/// Identity options for Flo Meets matching.
class FloMeetIdentity {
  FloMeetIdentity._();

  static const male = 'male';
  static const female = 'female';
  static const nonBinary = 'non_binary';
  static const preferNotToSay = 'prefer_not_to_say';

  static const all = [male, female, nonBinary, preferNotToSay];

  static String labelFor(String id) => switch (id) {
    male => 'Male',
    female => 'Female',
    nonBinary => 'Non-binary',
    preferNotToSay => 'Prefer not to say',
    _ => id,
  };
}

class FloMeetOpenTo {
  FloMeetOpenTo._();

  static const male = 'male';
  static const female = 'female';
  static const nonBinary = 'non_binary';
  static const all = 'all';

  static const options = [male, female, nonBinary, all];

  static String labelFor(String id) => switch (id) {
    male => 'Male',
    female => 'Female',
    nonBinary => 'Non-binary',
    all => 'All',
    _ => id,
  };
}
