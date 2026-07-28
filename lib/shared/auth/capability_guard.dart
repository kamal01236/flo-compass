import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/app_capability.dart';
import '../../providers/auth_provider.dart';

/// Shows a snackbar when a capability requires authentication.
bool requireAuth(
  BuildContext context,
  AppCapability capability, {
  VoidCallback? onDenied,
}) {
  final auth = context.read<AuthState>();
  if (!auth.isEnabled || auth.hasCapability(capability)) return true;
  onDenied?.call();
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(capability.denialMessage)));
  return false;
}

/// Gates organizer/admin screens when the active role lacks a capability.
class CapabilityGuard extends StatelessWidget {
  const CapabilityGuard({
    super.key,
    required this.capability,
    required this.authState,
    required this.child,
    this.denied,
  });

  final AppCapability capability;
  final AuthState authState;
  final Widget child;
  final Widget? denied;

  @override
  Widget build(BuildContext context) {
    if (authState.hasCapability(capability)) return child;
    return denied ??
        Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                capability.denialMessage,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
  }
}
