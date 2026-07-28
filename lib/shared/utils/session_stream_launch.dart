import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'safe_launch_url.dart';

typedef StreamUrlLauncher = Future<bool> Function(Uri uri);

/// Opens a demo stream URL after scheme allowlist checks.
Future<bool> launchDemoStream(
  BuildContext context,
  String url, {
  StreamUrlLauncher? launch,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !isAllowedLaunchScheme(uri)) {
    _showSnack(context, 'Could not open stream — link blocked or invalid');
    return false;
  }

  final launcher =
      launch ?? ((u) => launchUrl(u, mode: LaunchMode.platformDefault));
  final launched = await launcher(uri);
  if (!launched && context.mounted) {
    _showSnack(context, 'Could not open stream link');
  }
  return launched;
}

void _showSnack(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
