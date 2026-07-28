import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/event_provider.dart';
import '../utils/page_meta.dart';
import '../utils/page_meta_builder.dart';

class PageMetaCoordinator extends StatefulWidget {
  const PageMetaCoordinator({
    super.key,
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  State<PageMetaCoordinator> createState() => _PageMetaCoordinatorState();
}

class _PageMetaCoordinatorState extends State<PageMetaCoordinator> {
  GoRouter? _router;
  String _lastLocation = '';

  static final _sessionRoute = RegExp(r'^/session/([^/]+)$');

  @override
  void initState() {
    super.initState();
    _router = widget.router;
    _router?.routerDelegate.addListener(_onRouteChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onRouteChanged());
  }

  @override
  void didUpdateWidget(covariant PageMetaCoordinator oldWidget) {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyMetaForLocation(location);
    });
  }

  void _applyMetaForLocation(String location) {
    final origin = resolvePageMetaOrigin();
    final match = _sessionRoute.firstMatch(location);
    if (match == null) {
      applyPageMeta(defaults(origin: origin));
      return;
    }

    final sessionId = match.group(1)!;
    final event = context.read<EventState>();
    final session = event.sessionById(sessionId);
    if (session == null) {
      applyPageMeta(forSessionRoute(sessionId: sessionId, origin: origin));
      return;
    }

    applyPageMeta(
      forSession(
        session: session,
        origin: origin,
        venue: event.venueById(session.venueId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
