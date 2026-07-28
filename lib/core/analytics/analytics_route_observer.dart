import 'dart:async';

import 'package:flutter/material.dart';

import 'analytics_service.dart';

/// Emits [screen_view] events on navigation changes.
class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver(this._analytics);

  final AnalyticsService _analytics;
  String? _previousRoute;
  String? _lastLocation;

  @visibleForTesting
  String? get previousRoute => _previousRoute;

  /// GoRouter matched-location hook with consecutive deduplication.
  void didChangeRoute(String location) {
    if (_lastLocation == location) return;
    final previous = _lastLocation;
    _lastLocation = location;
    _previousRoute = location;
    unawaited(
      _analytics.track(
        'screen_view',
        route: location,
        properties: {'route': location, 'previous_route': ?previous},
      ),
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _emitForRoute(route, previousRoute?.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final route = newRoute;
    if (route != null) _emitForRoute(route, oldRoute?.settings.name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final next = previousRoute;
    if (next != null) _emitForRoute(next, route.settings.name);
  }

  void _emitForRoute(Route<dynamic> route, String? previousName) {
    final routeName = route.settings.name;
    if (routeName == null || routeName.isEmpty) return;

    final previous = previousName ?? _previousRoute;
    _previousRoute = routeName;

    unawaited(
      _analytics.track(
        'screen_view',
        route: routeName,
        properties: {'route': routeName, 'previous_route': ?previous},
      ),
    );
  }
}
