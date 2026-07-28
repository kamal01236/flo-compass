import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/runtime_config.dart';
import '../../core/routing/app_routes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../shared/auth/mock_user_picker.dart';

/// In-Meets sign-in gate for unauthenticated users (no Profile redirect).
class FloMeetsSignInGate extends StatelessWidget {
  const FloMeetsSignInGate({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthState>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.floMeetsSignInTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.floMeetsSignInBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              if (RuntimeConfig.mockLoginEnabled)
                FilledButton.icon(
                  onPressed: () => showMockUserPicker(context),
                  icon: const Icon(Icons.login),
                  label: Text(l10n.profileLogin),
                )
              else if (auth.isEnabled)
                FilledButton.icon(
                  onPressed: () =>
                      auth.beginLogin(returnUrl: AppRoutes.floMeetsRoot),
                  icon: const Icon(Icons.login),
                  label: Text(l10n.profileLogin),
                )
              else
                Text(
                  l10n.floMeetsSignInUnavailable,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
