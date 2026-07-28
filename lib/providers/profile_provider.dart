import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/networking_card.dart';
import '../data/models/user_profile.dart';
import '../data/services/audit_log_service.dart';
import 'ops_config_provider.dart';

class ProfileState extends ChangeNotifier {
  ProfileState({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  UserProfile profile = UserProfile.empty;

  static const _key = 'flo_compass_profile';
  Future<void> Function()? onResetHook;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw != null) {
      profile = UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
    notifyListeners();
  }

  Future<void> saveProfile({
    required AttendeeRole role,
    required List<String> interests,
    bool complete = true,
    String? firstName,
    RecommendationMode? recommendationMode,
    EnergyFilter? energyFilter,
    AttendanceMode? attendanceMode,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    profile = UserProfile(
      role: role,
      interests: interests,
      onboardingComplete: complete,
      firstName: firstName ?? profile.firstName,
      recommendationMode: recommendationMode ?? profile.recommendationMode,
      energyFilter: energyFilter ?? profile.energyFilter,
      networkingCard: profile.networkingCard,
      attendanceMode: attendanceMode ?? profile.attendanceMode,
      followedSpeakerIds: profile.followedSpeakerIds,
    );
    await _prefs!.setString(_key, jsonEncode(profile.toJson()));
    notifyListeners();
  }

  Future<void> updatePreferences({
    RecommendationMode? recommendationMode,
    EnergyFilter? energyFilter,
    String? firstName,
    List<String>? followedSpeakerIds,
    AttendanceMode? attendanceMode,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    profile = profile.copyWith(
      recommendationMode: recommendationMode,
      energyFilter: energyFilter,
      firstName: firstName,
      followedSpeakerIds: followedSpeakerIds,
      attendanceMode: attendanceMode,
    );
    await _prefs!.setString(_key, jsonEncode(profile.toJson()));
    notifyListeners();
  }

  Future<void> setAttendanceMode(AttendanceMode mode) async {
    await updatePreferences(attendanceMode: mode);
  }

  Future<void> saveNetworkingCard(NetworkingCard card) async {
    _prefs ??= await SharedPreferences.getInstance();
    profile = profile.copyWith(networkingCard: card);
    await _prefs!.setString(_key, jsonEncode(profile.toJson()));
    notifyListeners();
  }

  Future<void> clearNetworkingCard() async {
    _prefs ??= await SharedPreferences.getInstance();
    profile = profile.copyWith(clearNetworkingCard: true);
    await _prefs!.setString(_key, jsonEncode(profile.toJson()));
    notifyListeners();
  }

  Future<void> toggleFollowSpeaker(String speakerId) async {
    final followed = [...profile.followedSpeakerIds];
    if (followed.contains(speakerId)) {
      followed.remove(speakerId);
    } else {
      followed.add(speakerId);
    }
    await updatePreferences(followedSpeakerIds: followed);
  }

  Future<void> resetOnboarding() async {
    _prefs ??= await SharedPreferences.getInstance();
    profile = UserProfile.empty;
    await _prefs!.remove(_key);
    await onResetHook?.call();
    notifyListeners();
    await recordAudit(action: AuditActions.profileReset, entityType: 'profile');
  }
}
