import 'package:flutter/material.dart';

import '../../data/models/networking_card.dart';
import '../../data/services/networking_card_share_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/name_initials.dart';

/// Polished preview of a digital business card for profile, editor, and share flows.
class BusinessCardPreview extends StatelessWidget {
  const BusinessCardPreview({super.key, this.card, this.payload})
    : assert(card != null || payload != null, 'Provide either card or payload');

  const BusinessCardPreview.fromCard({super.key, required this.card})
    : payload = null;

  const BusinessCardPreview.fromPayload({super.key, required this.payload})
    : card = null;

  final NetworkingCard? card;
  final NetworkingCardPayload? payload;

  static const _emptyPrompt =
      'Add a display name and enable at least one channel to preview.';

  @override
  Widget build(BuildContext context) {
    final resolved = _resolvePayload();
    final showDisabledOverlay = card != null && card!.enabled == false;
    final isEmpty = resolved == null;

    return Stack(
      children: [
        _CardShell(
          child: isEmpty
              ? showDisabledOverlay
                    ? const SizedBox(height: 72)
                    : Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          _emptyPrompt,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      )
              : _CardContent(payload: resolved),
        ),
        if (showDisabledOverlay)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.55),
                child: Center(
                  child: Text(
                    'Business card disabled',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  NetworkingCardPayload? _resolvePayload() {
    if (payload != null) {
      return payload!.isEmpty ? null : payload;
    }
    final service = NetworkingCardShareService();
    final decoded = service.decode(service.encode(card!));
    if (decoded == null || decoded.isEmpty) return null;
    return decoded;
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppChromeColors.of(context).skeleton,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accentStart, AppColors.accentEnd],
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({required this.payload});

  final NetworkingCardPayload payload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.accentStart.withValues(alpha: 0.2),
            foregroundColor: AppColors.accentStart,
            child: Text(
              nameInitials(payload.displayName),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payload.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (payload.jobTitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    payload.jobTitle!,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (payload.company != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    payload.company!,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (payload.email != null || payload.linkedInUrl != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (payload.email != null)
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.email_outlined,
                            size: 18,
                            color: AppColors.accentStart,
                            semanticLabel: 'Email',
                          ),
                        ),
                      if (payload.linkedInUrl != null)
                        const Icon(
                          Icons.link,
                          size: 18,
                          color: AppColors.accentStart,
                          semanticLabel: 'LinkedIn',
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
