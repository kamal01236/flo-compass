import 'networking_card.dart';

/// Symmetric Connect state between the user and a partner in a room.
///
/// A match exists only when both sides have Connected (`iConnected && theyConnected`).
/// There is no request / accept / decline status.
class FloMeetConnection {
  const FloMeetConnection({
    required this.id,
    required this.roomId,
    required this.partnerId,
    required this.partnerNickname,
    required this.matchPercent,
    this.overlapTags = const [],
    this.iConnected = false,
    this.theyConnected = false,
    this.contactSnapshot,
    this.meetAmenityId = '',
    this.meetId,
    this.createdAt,
    this.matchedAt,
  });

  final String id;
  final String roomId;
  final String partnerId;
  final String partnerNickname;
  final int matchPercent;
  final List<String> overlapTags;
  final bool iConnected;
  final bool theyConnected;
  final ShareField? contactSnapshot;
  final String meetAmenityId;
  final String? meetId;
  final DateTime? createdAt;
  final DateTime? matchedAt;

  bool get isMatch => iConnected && theyConnected;

  bool get isWaiting => iConnected && !theyConnected;

  FloMeetConnection copyWith({
    String? id,
    String? roomId,
    String? partnerId,
    String? partnerNickname,
    int? matchPercent,
    List<String>? overlapTags,
    bool? iConnected,
    bool? theyConnected,
    ShareField? contactSnapshot,
    bool clearContactSnapshot = false,
    String? meetAmenityId,
    String? meetId,
    DateTime? createdAt,
    DateTime? matchedAt,
  }) {
    return FloMeetConnection(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      partnerId: partnerId ?? this.partnerId,
      partnerNickname: partnerNickname ?? this.partnerNickname,
      matchPercent: matchPercent ?? this.matchPercent,
      overlapTags: overlapTags ?? this.overlapTags,
      iConnected: iConnected ?? this.iConnected,
      theyConnected: theyConnected ?? this.theyConnected,
      contactSnapshot: clearContactSnapshot
          ? null
          : (contactSnapshot ?? this.contactSnapshot),
      meetAmenityId: meetAmenityId ?? this.meetAmenityId,
      meetId: meetId ?? this.meetId,
      createdAt: createdAt ?? this.createdAt,
      matchedAt: matchedAt ?? this.matchedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'roomId': roomId,
    'partnerId': partnerId,
    'partnerNickname': partnerNickname,
    'matchPercent': matchPercent,
    'overlapTags': overlapTags,
    'iConnected': iConnected,
    'theyConnected': theyConnected,
    if (contactSnapshot != null) 'contactSnapshot': contactSnapshot!.toJson(),
    'meetAmenityId': meetAmenityId,
    if (meetId != null) 'meetId': meetId,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (matchedAt != null) 'matchedAt': matchedAt!.toIso8601String(),
  };

  factory FloMeetConnection.fromJson(Map<String, dynamic> json) {
    return FloMeetConnection(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      partnerId: json['partnerId'] as String,
      partnerNickname: json['partnerNickname'] as String? ?? '',
      matchPercent: json['matchPercent'] as int? ?? 0,
      overlapTags: (json['overlapTags'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      iConnected: json['iConnected'] as bool? ?? false,
      theyConnected: json['theyConnected'] as bool? ?? false,
      contactSnapshot: json['contactSnapshot'] != null
          ? ShareField.fromJson(json['contactSnapshot'] as Map<String, dynamic>)
          : null,
      meetAmenityId: json['meetAmenityId'] as String? ?? '',
      meetId: json['meetId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      matchedAt: json['matchedAt'] != null
          ? DateTime.tryParse(json['matchedAt'] as String)
          : null,
    );
  }
}
