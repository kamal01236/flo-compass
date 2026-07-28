import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:go_router/go_router.dart';

class RouteAnnouncer extends StatefulWidget {
  const RouteAnnouncer({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  State<RouteAnnouncer> createState() => _RouteAnnouncerState();
}

class _RouteAnnouncerState extends State<RouteAnnouncer> {
  GoRouter? _router;
  String _lastLocation = '';

  @override
  void initState() {
    super.initState();
    _router = widget.router;
    _router?.routerDelegate.addListener(_onRouteChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onRouteChanged());
  }

  @override
  void didUpdateWidget(covariant RouteAnnouncer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router == widget.router) return;
    _router?.routerDelegate.removeListener(_onRouteChanged);
    _router = widget.router;
    _router?.routerDelegate.addListener(_onRouteChanged);
    _onRouteChanged();
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    if (!mounted) return;
    final location =
        _router?.routerDelegate.currentConfiguration.fullPath ?? '';
    if (location.isEmpty || location == _lastLocation) return;
    _lastLocation = location;
    final routeLabel = location
        .replaceAll('/', ' ')
        .replaceAll('-', ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    final message = routeLabel.isEmpty ? 'Now on home' : 'Now on $routeLabel';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        SemanticsService.sendAnnouncement(
          View.of(context),
          message,
          Directionality.of(context),
        );
      } catch (_) {
        // Skip if the view is not laid out yet (web first frame).
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
