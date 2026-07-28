import 'networking_card.dart';

import 'flo_meets_preferences.dart';

enum FloMeetStatus { scheduled, matched, completed, cancelled }

/// A single Flo Meet match for one availability slot.
class FloMeet {
  const FloMeet({
    required this.id,
    required this.slotKey,
    required this.day,
    required this.windowStart,
    required this.windowEnd,
    required this.partnerId,
    required this.partnerNickname,
    required this.meetAmenityId,
    this.status = FloMeetStatus.matched,
    this.contactMedium = FloMeetContactMedium.none,
    this.contactSnapshot,
    this.meetNote = '',
    this.matchedAt,
  });

  final String id;
  final String slotKey;
  final String day;
  final DateTime windowStart;
  final DateTime windowEnd;
  final String partnerId;
  final String partnerNickname;
  final String meetAmenityId;
  final FloMeetStatus status;
  final FloMeetContactMedium contactMedium;
  final ShareField? contactSnapshot;
  final String meetNote;
  final DateTime? matchedAt;

  FloMeet copyWith({
    FloMeetStatus? status,
    ShareField? contactSnapshot,
    String? meetNote,
  }) {
    return FloMeet(
      id: id,
      slotKey: slotKey,
      day: day,
      windowStart: windowStart,
      windowEnd: windowEnd,
      partnerId: partnerId,
      partnerNickname: partnerNickname,
      meetAmenityId: meetAmenityId,
      status: status ?? this.status,
      contactMedium: contactMedium,
      contactSnapshot: contactSnapshot ?? this.contactSnapshot,
      meetNote: meetNote ?? this.meetNote,
      matchedAt: matchedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'slotKey': slotKey,
    'day': day,
    'windowStart': windowStart.toIso8601String(),
    'windowEnd': windowEnd.toIso8601String(),
    'partnerId': partnerId,
    'partnerNickname': partnerNickname,
    'meetAmenityId': meetAmenityId,
    'status': status.name,
    'contactMedium': contactMedium.name,
    if (contactSnapshot != null) 'contactSnapshot': contactSnapshot!.toJson(),
    'meetNote': meetNote,
    if (matchedAt != null) 'matchedAt': matchedAt!.toIso8601String(),
  };

  factory FloMeet.fromJson(Map<String, dynamic> json) {
    return FloMeet(
      id: json['id'] as String,
      slotKey: json['slotKey'] as String,
      day: json['day'] as String,
      windowStart: DateTime.parse(json['windowStart'] as String),
      windowEnd: DateTime.parse(json['windowEnd'] as String),
      partnerId: json['partnerId'] as String,
      partnerNickname: json['partnerNickname'] as String,
      meetAmenityId: json['meetAmenityId'] as String,
      status: FloMeetStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'matched'),
        orElse: () => FloMeetStatus.matched,
      ),
      contactMedium: FloMeetContactMediumX.fromId(
        json['contactMedium'] as String?,
      ),
      contactSnapshot: json['contactSnapshot'] != null
          ? ShareField.fromJson(json['contactSnapshot'] as Map<String, dynamic>)
          : null,
      meetNote: json['meetNote'] as String? ?? '',
      matchedAt: json['matchedAt'] != null
          ? DateTime.tryParse(json['matchedAt'] as String)
          : null,
    );
  }
}
