import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flo_compass/l10n/app_localizations.dart';
import '../../providers/announcement_provider.dart';
import '../theme/app_theme.dart';

AnnouncementState? _tryAnnouncementState(BuildContext context) {
  try {
    return Provider.of<AnnouncementState>(context, listen: false);
  } on ProviderNotFoundException {
    return null;
  }
}

class PublishedAnnouncementBanner extends StatefulWidget {
  const PublishedAnnouncementBanner({super.key});

  @override
  State<PublishedAnnouncementBanner> createState() =>
      _PublishedAnnouncementBannerState();
}

class _PublishedAnnouncementBannerState
    extends State<PublishedAnnouncementBanner> {
  static const _dismissedKey = 'flo_dismissed_announcement_ids';
  Set<String> _dismissedIds = {};
  bool _prefsReady = false;

  @override
  void initState() {
    super.initState();
    _loadDismissed();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tryAnnouncementState(context)?.load();
    });
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_dismissedKey) ?? const [];
    if (!mounted) return;
    setState(() {
      _dismissedIds = ids.toSet();
      _prefsReady = true;
    });
  }

  Future<void> _dismiss(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final next = {..._dismissedIds, id};
    await prefs.setStringList(_dismissedKey, next.toList());
    if (!mounted) return;
    setState(() => _dismissedIds = next);
  }

  @override
  Widget build(BuildContext context) {
    final announcements = _tryAnnouncementState(context);
    if (!_prefsReady || announcements == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: announcements,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final visible = announcements.publishedAnnouncements
            .where((item) => !_dismissedIds.contains(item.id))
            .toList();
        if (visible.isEmpty) return const SizedBox.shrink();

        final latest = visible.first;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: MaterialBanner(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  latest.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(latest.body),
              ],
            ),
            leading: const Icon(
              Icons.campaign_outlined,
              color: AppColors.accentStart,
            ),
            backgroundColor: AppColors.accentStart.withValues(alpha: 0.08),
            actions: [
              TextButton(
                onPressed: () => _dismiss(latest.id),
                child: Text(l10n.commonDismiss),
              ),
            ],
          ),
        );
      },
    );
  }
}
