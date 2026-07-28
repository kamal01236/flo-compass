import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';

/// Central route path constants for Flo Compass.
class AppRoutes {
  AppRoutes._();

  static const discover = '/discover';
  static const companion = '/companion';
  static const floMeetsRoot = '/meets';
  static const floMeetsPreferences = '/meets/preferences';
  static const myPlan = '/my-plan';
  static const profile = '/profile';
  static const onboarding = '/onboarding';
  static const map = '/map';
  static const directions = '/directions';
  static const recap = '/recap';
  static const bingo = '/bingo';
  static const leaderboard = '/leaderboard';
  static const qr = '/qr';
  static const connectEdit = '/connect/edit';
  static const connectShare = '/connect/share';
  static const planImport = '/plan/import';
  static const organizer = '/organizer';
  static const organizerAnnouncements = '/organizer/announcements';
  static const organizerAnnouncementCompose =
      '/organizer/announcements/compose';
  static const organizerMeetRooms = '/organizer/meet-rooms';
  static const organizerMeetRoomCompose = '/organizer/meet-rooms/compose';
  static const organizerPrompts = '/organizer/prompts';
  static const organizerQa = '/organizer/qa';
  static const admin = '/admin';
  static const privacy = '/privacy';
  static const consent = '/consent';
  static const authCallback = '/auth/callback';
  static const accessibility = '/accessibility';
  static const returnToQuery = 'returnTo';

  static String floMeetRoom(String roomId) => '/meets/room/$roomId';

  static String floMeetWindow(String roomId, String partnerId) =>
      '/meets/window/$roomId/$partnerId';

  static String floMeetDetail(String id) => '/meets/match/$id';

  static String session(String id) => '/session/$id';
  static String speaker(String id) => '/speaker/$id';
  static String learningPath(String id) => '/learning-path/$id';
  static String connectPublic(String token) => '/connect/$token';

  static String organizerAnnouncementDetail(String id) =>
      '/organizer/announcements/$id';

  static String organizerMeetRoomDetail(String id) =>
      '/organizer/meet-rooms/$id';

  static const shellPaths = <String>[
    discover,
    companion,
    floMeetsRoot,
    myPlan,
    profile,
    onboarding,
    map,
    directions,
  ];

  static const overlayPaths = <String>[
    recap,
    bingo,
    leaderboard,
    qr,
    planImport,
    connectEdit,
    connectShare,
    organizer,
    organizerAnnouncements,
    organizerAnnouncementCompose,
    organizerMeetRooms,
    organizerMeetRoomCompose,
    organizerPrompts,
    organizerQa,
    admin,
  ];

  static String? sanitizeReturnTo(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final decoded = Uri.decodeComponent(raw);
    if (!decoded.startsWith('/') || decoded.startsWith('//')) return null;
    return decoded;
  }

  static bool isSharedPublicPath(String location) {
    if (location.isEmpty || location == '/') return false;
    return _isIdSegmentPublic(location, '/session/') ||
        _isIdSegmentPublic(location, '/speaker/') ||
        _isIdSegmentPublic(location, '/learning-path/') ||
        _isMapOrDirectionsPublic(location) ||
        location == planImport ||
        location == privacy ||
        location == consent ||
        location == authCallback ||
        location == accessibility ||
        _isConnectPublicPath(location);
  }

  static bool _isMapOrDirectionsPublic(String location) {
    if (location == map || location.startsWith('$map?')) return true;
    if (location == directions || location.startsWith('$directions?')) {
      return true;
    }
    return false;
  }

  static bool _isIdSegmentPublic(String location, String prefix) {
    if (!location.startsWith(prefix)) return false;
    var rest = location.substring(prefix.length);
    final queryIndex = rest.indexOf('?');
    if (queryIndex >= 0) {
      rest = rest.substring(0, queryIndex);
    }
    return rest.isNotEmpty && !rest.contains('/');
  }

  /// Public connect card token routes (not owner edit/share).
  static bool _isConnectPublicPath(String location) {
    return location.startsWith('/connect/') &&
        location != connectEdit &&
        location != connectShare;
  }

  /// Visitor landing: check both matched route and browser path (web deep links).
  static bool isVisitorRoute(GoRouterState state) {
    return isVisitorLocation(state.matchedLocation, state.uri.path);
  }

  /// Path-only visitor check (matched route and/or browser URI path).
  static bool isVisitorLocation(String matchedLocation, String uriPath) {
    return isSharedPublicPath(matchedLocation) || isSharedPublicPath(uriPath);
  }

  /// Relative path for consent returnTo (never full URL).
  static String currentPathForReturn(GoRouterState state) {
    final path = state.uri.path;
    if (state.uri.hasQuery) {
      return '$path?${state.uri.query}';
    }
    return path;
  }

  /// Web cold-start deep link; falls back to [discover].
  static String resolveInitialLocation() {
    if (kIsWeb) {
      final path = Uri.base.path;
      if (path.isNotEmpty && path != '/') {
        return Uri.base.hasQuery ? '$path?${Uri.base.query}' : path;
      }
      final fragment = Uri.base.fragment;
      if (fragment.isNotEmpty) {
        return fragment.startsWith('/') ? fragment : '/$fragment';
      }
    }
    return discover;
  }
}
