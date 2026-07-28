import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/app_settings_provider.dart';
import '../../providers/profile_provider.dart';
import '../theme/app_theme.dart';
import '../tour/tour_controller.dart';
import '../utils/pwa_install.dart'
    show initPwaInstallCapture, isInstallPromptAvailable, triggerInstallPrompt;

class PwaInstallCoordinator extends StatefulWidget {
  const PwaInstallCoordinator({
    super.key,
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  State<PwaInstallCoordinator> createState() => _PwaInstallCoordinatorState();
}

class _PwaInstallCoordinatorState extends State<PwaInstallCoordinator> {
  bool _bannerVisible = false;

  @override
  void initState() {
    super.initState();
    initPwaInstallCapture();
    widget.router.routerDelegate.addListener(_onRouteChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluatePrompt());
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() => _evaluatePrompt();

  void _evaluatePrompt() {
    if (!mounted || _bannerVisible) return;

    final profile = context.read<ProfileState>();
    final settings = context.read<AppSettingsState>();
    final tour = _maybeReadTour(listen: false);
    final location = widget.router.state.matchedLocation;

    if (!profile.profile.onboardingComplete) return;
    if (location == '/onboarding') return;
    if (tour?.tourActive ?? false) return;
    if (settings.shellTabVisitCount < 2) return;
    if (settings.isPwaInstallDismissed) return;
    if (!isInstallPromptAvailable) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _bannerVisible) return;
      setState(() => _bannerVisible = true);
    });
  }

  Future<void> _install() async {
    final installed = await triggerInstallPrompt();
    if (!mounted) return;
    if (installed) {
      setState(() => _bannerVisible = false);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Install is not available — use your browser menu.'),
      ),
    );
  }

  Future<void> _dismiss() async {
    await context.read<AppSettingsState>().dismissPwaInstallPrompt();
    if (!mounted) return;
    setState(() => _bannerVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppSettingsState>();
    context.watch<ProfileState>();
    _maybeReadTour(listen: true);

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_bannerVisible)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              elevation: 8,
              color: AppChromeColors.of(context).elevatedPanel,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Install Flo Compass',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add to your home screen for quick access during Flo 2026.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton(
                            onPressed: _dismiss,
                            child: const Text('Not now'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: _install,
                            child: const Text('Install'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  TourController? _maybeReadTour({required bool listen}) {
    try {
      return Provider.of<TourController>(context, listen: listen);
    } catch (_) {
      return null;
    }
  }
}
