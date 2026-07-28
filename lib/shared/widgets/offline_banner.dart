import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.announce = false});

  /// When true, screen readers announce the offline state (transition only).
  final bool announce;

  @override
  Widget build(BuildContext context) {
    final message = AppLocalizations.of(context).offlineBanner;
    return Semantics(
      liveRegion: announce,
      label: message,
      child: Material(
        color: Colors.amber.shade800.withValues(alpha: 0.92),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.cloud_off, color: Colors.amber.shade50, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Colors.amber.shade50,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
