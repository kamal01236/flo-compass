import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/routing/app_routes.dart';
import '../../data/models/networking_card.dart';
import '../../data/services/networking_card_share_service.dart';
import '../../features/qr/qr_url_builder.dart';
import '../../providers/profile_provider.dart';
import '../../shared/widgets/shared_widgets.dart';

class NetworkingCardShareScreen extends StatefulWidget {
  const NetworkingCardShareScreen({super.key});

  @override
  State<NetworkingCardShareScreen> createState() =>
      _NetworkingCardShareScreenState();
}

class _NetworkingCardShareScreenState extends State<NetworkingCardShareScreen> {
  final _shareService = NetworkingCardShareService();

  String get _origin => QrUrlBuilder.resolveOrigin(Uri.base);

  String? _shareUrl(NetworkingCard card) {
    if (!card.enabled || !card.isConfigured) return null;
    final token = _shareService.encode(card);
    return QrUrlBuilder.connectUrl(token, origin: _origin);
  }

  void _exit(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card =
        context.watch<ProfileState>().profile.networkingCard ??
        NetworkingCard.empty;
    final url = _shareUrl(card);

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _exit(context),
          ),
        ),
        title: const Text('My QR card'),
      ),
      body: ResponsiveLayout(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Show this QR so someone can scan and save your business card. '
              'Only the fields you chose are shared.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            if (url == null) ...[
              const Text(
                'Turn on your business card and pick at least one channel to share.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push(AppRoutes.connectEdit),
                child: const Text('Edit business card'),
              ),
            ] else ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: QrImageView(
                    data: url,
                    version: QrVersions.auto,
                    size: 240,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => _exit(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
