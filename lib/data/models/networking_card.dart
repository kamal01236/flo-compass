/// Opt-in digital networking card for 1:1 QR contact exchange.
class ShareField {
  const ShareField({this.value = '', this.visible = false});

  final String value;
  final bool visible;

  ShareField copyWith({String? value, bool? visible}) {
    return ShareField(
      value: value ?? this.value,
      visible: visible ?? this.visible,
    );
  }

  Map<String, dynamic> toJson() => {'value': value, 'visible': visible};

  factory ShareField.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ShareField();
    return ShareField(
      value: json['value'] as String? ?? '',
      visible: json['visible'] as bool? ?? false,
    );
  }
}

class NetworkingCard {
  const NetworkingCard({
    this.enabled = false,
    this.displayName = '',
    this.jobTitle,
    this.company,
    this.email = const ShareField(),
    this.phoneE164 = const ShareField(),
    this.linkedInUrl = const ShareField(),
    this.facebookUrl = const ShareField(),
    this.whatsApp = const ShareField(),
    this.showRole = false,
    this.showTopInterests = false,
  });

  final bool enabled;
  final String displayName;
  final String? jobTitle;
  final String? company;
  final ShareField email;
  final ShareField phoneE164;
  final ShareField linkedInUrl;
  final ShareField facebookUrl;
  final ShareField whatsApp;
  final bool showRole;
  final bool showTopInterests;

  bool get isConfigured =>
      enabled &&
      displayName.trim().isNotEmpty &&
      (email.visible && email.value.isNotEmpty ||
          linkedInUrl.visible && linkedInUrl.value.isNotEmpty);

  NetworkingCard copyWith({
    bool? enabled,
    String? displayName,
    String? jobTitle,
    String? company,
    ShareField? email,
    ShareField? phoneE164,
    ShareField? linkedInUrl,
    ShareField? facebookUrl,
    ShareField? whatsApp,
    bool? showRole,
    bool? showTopInterests,
    bool clearJobTitle = false,
    bool clearCompany = false,
  }) {
    return NetworkingCard(
      enabled: enabled ?? this.enabled,
      displayName: displayName ?? this.displayName,
      jobTitle: clearJobTitle ? null : (jobTitle ?? this.jobTitle),
      company: clearCompany ? null : (company ?? this.company),
      email: email ?? this.email,
      phoneE164: phoneE164 ?? this.phoneE164,
      linkedInUrl: linkedInUrl ?? this.linkedInUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      whatsApp: whatsApp ?? this.whatsApp,
      showRole: showRole ?? this.showRole,
      showTopInterests: showTopInterests ?? this.showTopInterests,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'displayName': displayName,
    if (jobTitle != null) 'jobTitle': jobTitle,
    if (company != null) 'company': company,
    'email': email.toJson(),
    'phoneE164': phoneE164.toJson(),
    'linkedInUrl': linkedInUrl.toJson(),
    'facebookUrl': facebookUrl.toJson(),
    'whatsApp': whatsApp.toJson(),
    'showRole': showRole,
    'showTopInterests': showTopInterests,
  };

  factory NetworkingCard.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NetworkingCard();
    return NetworkingCard(
      enabled: json['enabled'] as bool? ?? false,
      displayName: json['displayName'] as String? ?? '',
      jobTitle: json['jobTitle'] as String?,
      company: json['company'] as String?,
      email: ShareField.fromJson(json['email'] as Map<String, dynamic>?),
      phoneE164: ShareField.fromJson(
        json['phoneE164'] as Map<String, dynamic>?,
      ),
      linkedInUrl: ShareField.fromJson(
        json['linkedInUrl'] as Map<String, dynamic>?,
      ),
      facebookUrl: ShareField.fromJson(
        json['facebookUrl'] as Map<String, dynamic>?,
      ),
      whatsApp: ShareField.fromJson(json['whatsApp'] as Map<String, dynamic>?),
      showRole: json['showRole'] as bool? ?? false,
      showTopInterests: json['showTopInterests'] as bool? ?? false,
    );
  }

  static const empty = NetworkingCard();
}

/// Public payload decoded from a share token (visible fields only).
class NetworkingCardPayload {
  const NetworkingCardPayload({
    required this.displayName,
    this.jobTitle,
    this.company,
    this.email,
    this.linkedInUrl,
  });

  final String displayName;
  final String? jobTitle;
  final String? company;
  final String? email;
  final String? linkedInUrl;

  bool get isEmpty => displayName.trim().isEmpty;
}
