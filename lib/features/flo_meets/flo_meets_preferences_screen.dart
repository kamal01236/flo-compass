import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../data/models/flo_meets_preferences.dart';
import '../../data/models/networking_card.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/flo_meets_provider.dart';
import '../../providers/profile_provider.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'flo_meets_preferences_form.dart';
import 'flo_meets_sign_in_gate.dart';

/// First-open setup and later edits for Flo Meets preferences.
class FloMeetsPreferencesScreen extends StatefulWidget {
  const FloMeetsPreferencesScreen({super.key});

  @override
  State<FloMeetsPreferencesScreen> createState() =>
      _FloMeetsPreferencesScreenState();
}

class _FloMeetsPreferencesScreenState extends State<FloMeetsPreferencesScreen> {
  FloMeetsPreferences _draft = FloMeetsPreferences.defaults();
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final stored = context.read<FloMeetsState>().preferences;
    _draft = stored.isSetupComplete ? stored : FloMeetsPreferences.defaults();
  }

  Future<void> _save() async {
    if (!_draft.isSetupComplete || _saving) return;
    setState(() => _saving = true);
    try {
      await context.read<FloMeetsState>().savePreferences(
        _draft.coercedForSave(),
      );
      if (!mounted) return;
      context.go(AppRoutes.floMeetsRoot);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthState>();
    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.floMeetsTitle)),
        body: const FloMeetsSignInGate(),
      );
    }

    final floMeets = context.watch<FloMeetsState>();
    final isEdit = floMeets.preferences.isSetupComplete;
    final networkingCard =
        context.watch<ProfileState>().profile.networkingCard ??
        NetworkingCard.empty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? l10n.floMeetsEditPreferences : l10n.floMeetsSetupTitle,
        ),
      ),
      body: ResponsiveLayout(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isEdit) ...[
                      Text(
                        l10n.floMeetsSetupBody,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                    ],
                    FloMeetsPreferencesForm(
                      initial: _draft,
                      networkingCard: networkingCard,
                      onChanged: (prefs) => setState(() => _draft = prefs),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _draft.isSetupComplete && !_saving ? _save : null,
                  child: Text(
                    _saving
                        ? l10n.floMeetsSavingPreferences
                        : l10n.floMeetsSavePreferences,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
