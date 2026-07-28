import 'networking_card.dart';

enum AttendanceMode { onSite, remote }

extension AttendanceModeX on AttendanceMode {
  String get label => switch (this) {
    AttendanceMode.onSite => 'On-site',
    AttendanceMode.remote => 'Remote',
  };

  static AttendanceMode fromId(String? id) {
    return AttendanceMode.values.firstWhere(
      (mode) => mode.name == id,
      orElse: () => AttendanceMode.onSite,
    );
  }
}

enum AttendeeRole {
  engineer,
  architect,
  engineeringManager,
  productManager,
  consultant,
  executive,
  guest,
}

extension AttendeeRoleX on AttendeeRole {
  String get id => name;

  String get label => switch (this) {
    AttendeeRole.engineer => 'Engineer',
    AttendeeRole.architect => 'Architect',
    AttendeeRole.engineeringManager => 'Engineering Manager',
    AttendeeRole.productManager => 'Product Manager',
    AttendeeRole.consultant => 'Consultant',
    AttendeeRole.executive => 'Executive',
    AttendeeRole.guest => 'Guest',
  };

  static AttendeeRole? fromId(String? id) {
    if (id == null) return null;
    for (final role in AttendeeRole.values) {
      if (role.name == id) return role;
    }
    return null;
  }
}

enum InterestTag {
  genai,
  llmAgents,
  mlops,
  dataMesh,
  responsibleAi,
  cloud,
  kubernetes,
  platformEngineering,
  devex,
  cursor,
  architecture,
  apis,
  cybersecurity,
  ceoVision,
  strategy,
  leadership,
  culture,
  clientDelivery,
  financialServices,
  healthcare,
  automotive,
  telecom,
  manufacturing,
  sustainability,
  innovation,
  hackathon,
  emergingTech,
}

extension InterestTagX on InterestTag {
  String get id => switch (this) {
    InterestTag.llmAgents => 'llm_agents',
    InterestTag.dataMesh => 'data_mesh',
    InterestTag.responsibleAi => 'responsible_ai',
    InterestTag.platformEngineering => 'platform_engineering',
    InterestTag.ceoVision => 'ceo_vision',
    InterestTag.clientDelivery => 'client_delivery',
    InterestTag.financialServices => 'financial_services',
    InterestTag.emergingTech => 'emerging_tech',
    _ => name,
  };

  String get label => switch (this) {
    InterestTag.genai => 'GenAI',
    InterestTag.llmAgents => 'LLM Agents',
    InterestTag.mlops => 'MLOps',
    InterestTag.dataMesh => 'Data Mesh',
    InterestTag.responsibleAi => 'Responsible AI',
    InterestTag.cloud => 'Cloud',
    InterestTag.kubernetes => 'Kubernetes',
    InterestTag.platformEngineering => 'Platform Engineering',
    InterestTag.devex => 'DevEx',
    InterestTag.cursor => 'Cursor',
    InterestTag.architecture => 'Architecture',
    InterestTag.apis => 'APIs',
    InterestTag.cybersecurity => 'Cybersecurity',
    InterestTag.ceoVision => 'CEO Vision',
    InterestTag.strategy => 'Strategy',
    InterestTag.leadership => 'Leadership',
    InterestTag.culture => 'Culture',
    InterestTag.clientDelivery => 'Client Delivery',
    InterestTag.financialServices => 'Financial Services',
    InterestTag.healthcare => 'Healthcare',
    InterestTag.automotive => 'Automotive',
    InterestTag.telecom => 'Telecom',
    InterestTag.manufacturing => 'Manufacturing',
    InterestTag.sustainability => 'Sustainability',
    InterestTag.innovation => 'Innovation',
    InterestTag.hackathon => 'Hackathon',
    InterestTag.emergingTech => 'Emerging Tech',
  };

  static InterestTag? fromId(String id) {
    for (final tag in InterestTag.values) {
      if (tag.id == id) return tag;
    }
    return null;
  }

  static const aiData = [
    InterestTag.genai,
    InterestTag.llmAgents,
    InterestTag.mlops,
    InterestTag.dataMesh,
    InterestTag.responsibleAi,
  ];

  static const engineering = [
    InterestTag.cloud,
    InterestTag.kubernetes,
    InterestTag.platformEngineering,
    InterestTag.devex,
    InterestTag.cursor,
    InterestTag.architecture,
    InterestTag.apis,
    InterestTag.cybersecurity,
  ];

  static const strategy = [
    InterestTag.ceoVision,
    InterestTag.strategy,
    InterestTag.leadership,
    InterestTag.culture,
    InterestTag.clientDelivery,
  ];

  static const domain = [
    InterestTag.financialServices,
    InterestTag.healthcare,
    InterestTag.automotive,
    InterestTag.telecom,
    InterestTag.manufacturing,
    InterestTag.sustainability,
  ];

  static const crossCutting = [
    InterestTag.innovation,
    InterestTag.hackathon,
    InterestTag.emergingTech,
  ];
}

enum RecommendationMode { focused, balanced, adventurous }

extension RecommendationModeX on RecommendationMode {
  static RecommendationMode fromId(String? id) {
    return RecommendationMode.values.firstWhere(
      (mode) => mode.name == id,
      orElse: () => RecommendationMode.balanced,
    );
  }
}

enum EnergyFilter { all, lightKeynotes, deepWorkshops }

class UserProfile {
  const UserProfile({
    required this.role,
    required this.interests,
    this.onboardingComplete = false,
    this.firstName = '',
    this.recommendationMode = RecommendationMode.balanced,
    this.energyFilter = EnergyFilter.all,
    this.followedSpeakerIds = const [],
    this.networkingCard,
    this.attendanceMode = AttendanceMode.onSite,
  });

  final AttendeeRole role;
  final List<String> interests;
  final bool onboardingComplete;
  final String firstName;
  final RecommendationMode recommendationMode;
  final EnergyFilter energyFilter;
  final List<String> followedSpeakerIds;
  final NetworkingCard? networkingCard;
  final AttendanceMode attendanceMode;

  UserProfile copyWith({
    AttendeeRole? role,
    List<String>? interests,
    bool? onboardingComplete,
    String? firstName,
    RecommendationMode? recommendationMode,
    EnergyFilter? energyFilter,
    List<String>? followedSpeakerIds,
    NetworkingCard? networkingCard,
    bool clearNetworkingCard = false,
    AttendanceMode? attendanceMode,
  }) {
    return UserProfile(
      role: role ?? this.role,
      interests: interests ?? this.interests,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      firstName: firstName ?? this.firstName,
      recommendationMode: recommendationMode ?? this.recommendationMode,
      energyFilter: energyFilter ?? this.energyFilter,
      followedSpeakerIds: followedSpeakerIds ?? this.followedSpeakerIds,
      networkingCard: clearNetworkingCard
          ? null
          : (networkingCard ?? this.networkingCard),
      attendanceMode: attendanceMode ?? this.attendanceMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'role': role.name,
    'interests': interests,
    'onboardingComplete': onboardingComplete,
    'firstName': firstName,
    'recommendationMode': recommendationMode.name,
    'energyFilter': energyFilter.name,
    'followedSpeakerIds': followedSpeakerIds,
    'attendanceMode': attendanceMode.name,
    if (networkingCard != null) 'networkingCard': networkingCard!.toJson(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      role: AttendeeRoleX.fromId(json['role'] as String?) ?? AttendeeRole.guest,
      interests: (json['interests'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      firstName: json['firstName'] as String? ?? '',
      recommendationMode: RecommendationModeX.fromId(
        json['recommendationMode'] as String?,
      ),
      energyFilter: EnergyFilter.values.firstWhere(
        (item) => item.name == (json['energyFilter'] as String? ?? ''),
        orElse: () => EnergyFilter.all,
      ),
      followedSpeakerIds: (json['followedSpeakerIds'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      attendanceMode: AttendanceModeX.fromId(json['attendanceMode'] as String?),
      networkingCard: json['networkingCard'] != null
          ? NetworkingCard.fromJson(
              json['networkingCard'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  static const empty = UserProfile(
    role: AttendeeRole.guest,
    interests: [],
    onboardingComplete: false,
  );
}
