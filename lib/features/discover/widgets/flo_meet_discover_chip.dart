import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../data/models/flo_meet.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';

class FloMeetDiscoverChip extends StatelessWidget {
  const FloMeetDiscoverChip({super.key, required this.meet});

  final FloMeet meet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final time = _fmt(meet.windowStart);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ActionChip(
        avatar: Icon(
          Icons.people_outline,
          size: 18,
          color: AppColors.accentStart,
        ),
        label: Text(l10n.floMeetsDiscoverChip(time)),
        onPressed: () => context.push(AppRoutes.floMeetDetail(meet.id)),
      ),
    );
  }

  static String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
