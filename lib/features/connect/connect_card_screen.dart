import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/routing/app_routes.dart';
import '../../data/models/networking_card.dart';
import '../../data/services/networking_card_share_service.dart';
import '../../shared/utils/linkedin_url.dart';
import '../../shared/utils/safe_launch_url.dart';
import '../../shared/utils/web_download.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'business_card_preview.dart';
import 'vcard_builder.dart';

class ConnectCardScreen extends StatelessWidget {
  const ConnectCardScreen({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    final payload = NetworkingCardShareService().decode(token);

    if (payload == null || payload.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Business card')),
        body: ResponsiveLayout(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'This business card link is invalid or has expired.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Business card')),
      body: ResponsiveLayout(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            BusinessCardPreview.fromPayload(payload: payload),
            const SizedBox(height: 24),
            Text(
              'Viewing this card does not require an account.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Text('Connect', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _saveContact(payload),
              icon: const Icon(Icons.contact_page_outlined),
              label: const Text('Save contact (vCard)'),
            ),
            if (payload.linkedInUrl != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _openLinkedIn(payload.linkedInUrl!),
                icon: const Icon(Icons.link),
                label: const Text('Open LinkedIn'),
              ),
            ],
            if (payload.email != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _openUrl('mailto:${payload.email}'),
                icon: const Icon(Icons.email_outlined),
                label: Text('Email ${payload.email}'),
              ),
            ],
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Flo Compass complements Accelevents — official registration, '
              'networking, and attendee directory live in Accelevents.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.discover),
              child: const Text('Get Flo Compass'),
            ),
            const SizedBox(height: 6),
            Text(
              'Personalize your agenda — consent and setup when you continue.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _saveContact(NetworkingCardPayload payload) {
    final vcard = buildVCard(payload);
    final slug = payload.displayName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    downloadText(
      vcard,
      'flo-connect-${slug.isEmpty ? 'contact' : slug}.vcf',
      mimeType: 'text/vcard',
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !isAllowedLaunchScheme(uri)) return;
    final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!launched && kDebugMode) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _openLinkedIn(String url) async {
    final normalized = normalizeLinkedInUrl(url);
    if (normalized == null) return;
    final uri = Uri.tryParse(normalized);
    if (uri == null || !isAllowedLaunchScheme(uri)) return;
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!launched && kDebugMode) {
      debugPrint('Could not launch LinkedIn: $normalized');
    }
  }
}
