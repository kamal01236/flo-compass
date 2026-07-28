import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/consent_provider.dart';
import '../../shared/theme/app_theme.dart';

/// First-launch privacy consent for all users (anonymous and authenticated).
class PrivacyConsentScreen extends StatelessWidget {
  const PrivacyConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final consent = context.read<ConsentState>();
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.privacy_tip_outlined,
                    size: 48,
                    color: AppColors.accentStart,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.consentTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.consentBody,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.consentFloMeetsBody,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(
                          child: Text(
                            l10n.consentFloMeetsBullet,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.push('/privacy'),
                    child: Text(l10n.consentReadPolicy),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () async {
                      await consent.acceptPrivacy();
                      if (!context.mounted) return;
                      final router = GoRouter.maybeOf(context);
                      if (router != null) {
                        final returnTo = AppRoutes.sanitizeReturnTo(
                          GoRouterState.of(
                            context,
                          ).uri.queryParameters[AppRoutes.returnToQuery],
                        );
                        context.go(returnTo ?? AppRoutes.discover);
                      }
                    },
                    child: Text(l10n.consentAccept),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      await consent.declinePrivacy();
                      if (!context.mounted) return;
                      await showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(l10n.consentRequiredTitle),
                          content: Text(l10n.consentRequiredBody),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(l10n.consentOk),
                            ),
                          ],
                        ),
                      );
                      if (context.mounted) {
                        context.go(AppRoutes.privacy);
                      }
                    },
                    child: Text(l10n.consentDecline),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
