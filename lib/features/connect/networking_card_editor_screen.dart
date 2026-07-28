import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/routing/app_routes.dart';
import '../../data/models/networking_card.dart';
import '../../providers/profile_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/linkedin_url.dart';
import '../../shared/widgets/shared_widgets.dart';

class NetworkingCardEditorScreen extends StatefulWidget {
  const NetworkingCardEditorScreen({super.key});

  @override
  State<NetworkingCardEditorScreen> createState() =>
      _NetworkingCardEditorScreenState();
}

class _NetworkingCardEditorScreenState
    extends State<NetworkingCardEditorScreen> {
  static const _demoWarningKey = 'flo_connect_demo_warning_shown';

  final _displayNameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _linkedInController = TextEditingController();

  bool _enabled = false;
  bool _emailVisible = false;
  bool _linkedInVisible = false;
  bool _initialized = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _jobTitleController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _linkedInController.dispose();
    super.dispose();
  }

  void _loadFromProfile(ProfileState profileState) {
    if (_initialized) return;
    final card = profileState.profile.networkingCard ?? NetworkingCard.empty;
    final profile = profileState.profile;
    _enabled = card.enabled;
    _displayNameController.text = card.displayName.isNotEmpty
        ? card.displayName
        : profile.firstName;
    _jobTitleController.text = card.jobTitle ?? '';
    _companyController.text = card.company ?? '';
    _emailController.text = card.email.value;
    _linkedInController.text = card.linkedInUrl.value;
    _emailVisible = card.email.visible;
    _linkedInVisible = card.linkedInUrl.visible;
    _initialized = true;
  }

  NetworkingCard _buildCard() {
    return NetworkingCard(
      enabled: _enabled,
      displayName: _displayNameController.text.trim(),
      jobTitle: _jobTitleController.text.trim().isEmpty
          ? null
          : _jobTitleController.text.trim(),
      company: _companyController.text.trim().isEmpty
          ? null
          : _companyController.text.trim(),
      email: ShareField(
        value: _emailController.text.trim(),
        visible: _emailVisible,
      ),
      linkedInUrl: ShareField(
        value: _linkedInController.text.trim(),
        visible: _linkedInVisible,
      ),
    );
  }

  Future<void> _maybeShowDemoWarning() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_demoWarningKey) == true) return;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Demo business card'),
        content: const Text(
          'In this demo, your selected fields are encoded in the QR link. '
          'Use work contact details only. Production will use revocable tokens.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
    await prefs.setBool(_demoWarningKey, true);
  }

  String? _normalizeLinkedInForSave() {
    final raw = _linkedInController.text.trim();
    if (raw.isEmpty) return '';
    final normalized = normalizeLinkedInUrl(raw);
    if (normalized == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid LinkedIn profile URL (linkedin.com/in/…).',
          ),
        ),
      );
      return null;
    }
    _linkedInController.text = normalized;
    return normalized;
  }

  Future<void> _save({bool navigateToShare = false}) async {
    if (_linkedInVisible && _linkedInController.text.trim().isNotEmpty) {
      final normalized = _normalizeLinkedInForSave();
      if (normalized == null) return;
    }
    final card = _buildCard();
    if (card.enabled && card.displayName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name is required.')),
      );
      return;
    }
    if (card.enabled && !card.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enable at least one channel (email or LinkedIn) to share.',
          ),
        ),
      );
      return;
    }
    if (_emailVisible && _emailController.text.trim().isNotEmpty) {
      await _maybeShowDemoWarning();
    }
    if (!mounted) return;
    await context.read<ProfileState>().saveNetworkingCard(card);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Business card saved')));
    if (navigateToShare && card.enabled && card.isConfigured) {
      context.push(AppRoutes.connectShare);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileState>();
    _loadFromProfile(profileState);
    final previewCard = _buildCard();

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.profile),
          ),
        ),
        title: const Text('Edit business card'),
      ),
      body: ResponsiveLayout(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
              title: const Text('Enable business card'),
              subtitle: const Text(
                'When off, your QR is disabled until you turn this on.',
              ),
            ),
            const SizedBox(height: 16),
            Text('Identity', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display name',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _jobTitleController,
              decoration: const InputDecoration(
                labelText: 'Job title (optional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Company (optional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            Text('Channels', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() {}),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _emailVisible,
              onChanged: (value) => setState(() => _emailVisible = value),
              title: const Text('Show email on my card'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _linkedInController,
              decoration: const InputDecoration(
                labelText: 'LinkedIn profile URL',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _linkedInVisible,
              onChanged: (value) => setState(() => _linkedInVisible = value),
              title: const Text('Show LinkedIn on my card'),
            ),
            const SizedBox(height: 16),
            Card(
              color: AppChromeColors.of(context).skeleton,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Only people you show this QR can see selected fields. '
                  'Not listed in any attendee directory.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _save(),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save card'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: previewCard.enabled && previewCard.isConfigured
                  ? () => _save(navigateToShare: true)
                  : null,
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Save and show QR'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                await context.read<ProfileState>().clearNetworkingCard();
                if (!context.mounted) return;
                setState(() {
                  _initialized = false;
                  _enabled = false;
                  _emailVisible = false;
                  _linkedInVisible = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Business card cleared')),
                );
              },
              child: const Text('Delete card'),
            ),
          ],
        ),
      ),
    );
  }
}
