import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../data/models/flo_meet_connection.dart';
import '../../data/models/flo_meet_partner.dart';
import '../../data/services/flo_meets_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/flo_meets_provider.dart';
import '../../providers/profile_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/shared_widgets.dart';

/// Safe overview of a room partner with a single symmetric Connect CTA.
class FloMeetMatchWindowScreen extends StatefulWidget {
  const FloMeetMatchWindowScreen({
    super.key,
    required this.roomId,
    required this.partnerId,
  });

  final String roomId;
  final String partnerId;

  @override
  State<FloMeetMatchWindowScreen> createState() =>
      _FloMeetMatchWindowScreenState();
}

class _FloMeetMatchWindowScreenState extends State<FloMeetMatchWindowScreen> {
  FloMeetPartner? _partner;
  int _matchPercent = 0;
  List<String> _overlap = const [];
  bool _loading = true;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final floMeets = context.read<FloMeetsState>();
    final profile = context.read<ProfileState>();
    if (floMeets.rooms.isEmpty) await floMeets.loadRooms();
    final members = await floMeets.membersForRoom(
      roomId: widget.roomId,
      userRole: profile.profile.role,
      professionalInterests: profile.profile.interests,
    );
    RankedRoomMember? ranked;
    for (final m in members) {
      if (m.partner.id == widget.partnerId) {
        ranked = m;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _partner = ranked?.partner;
      _matchPercent = ranked?.matchPercent ?? 0;
      _overlap = ranked?.overlapTags ?? const [];
      _loading = false;
    });
  }

  Future<void> _onConnect() async {
    if (_connecting) return;
    setState(() => _connecting = true);
    final floMeets = context.read<FloMeetsState>();
    final profile = context.read<ProfileState>();
    try {
      if (!floMeets.isJoined(widget.roomId)) {
        await floMeets.joinRoom(widget.roomId);
      }
      await floMeets.connect(
        roomId: widget.roomId,
        partnerId: widget.partnerId,
        userRole: profile.profile.role,
        professionalInterests: profile.profile.interests,
        networkingCard: profile.profile.networkingCard,
      );
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final floMeets = context.watch<FloMeetsState>();
    final connection = floMeets.connectionFor(widget.roomId, widget.partnerId);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.floMeetsMatchWindowTitle)),
      body: ResponsiveLayout(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _partner == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.floMeetsPartnerNotFound),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          context.go(AppRoutes.floMeetRoom(widget.roomId)),
                      child: Text(l10n.floMeetsBackToRoom),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _partner!.nickname,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.floMeetsMatchPercent(_matchPercent),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.accentStart,
                      ),
                    ),
                    if (_overlap.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        l10n.floMeetsOverlapTitle,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in _overlap) Chip(label: Text(tag)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 28),
                    _ConnectCta(
                      connection: connection,
                      connecting: _connecting,
                      l10n: l10n,
                      onConnect: _onConnect,
                      onOpenMatch: connection?.meetId != null
                          ? () => context.go(
                              AppRoutes.floMeetDetail(connection!.meetId!),
                            )
                          : null,
                      onShareConnect: connection?.isMatch == true
                          ? () => context.push(AppRoutes.connectShare)
                          : null,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ConnectCta extends StatelessWidget {
  const _ConnectCta({
    required this.connection,
    required this.connecting,
    required this.l10n,
    required this.onConnect,
    this.onOpenMatch,
    this.onShareConnect,
  });

  final FloMeetConnection? connection;
  final bool connecting;
  final AppLocalizations l10n;
  final VoidCallback onConnect;
  final VoidCallback? onOpenMatch;
  final VoidCallback? onShareConnect;

  @override
  Widget build(BuildContext context) {
    if (connection?.isMatch == true) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: onOpenMatch,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(l10n.floMeetsMatchedContinue),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onShareConnect,
            icon: const Icon(Icons.qr_code_2_outlined),
            label: Text(l10n.floMeetsOpenConnectShare),
          ),
        ],
      );
    }

    if (connection?.isWaiting == true || connecting) {
      return FilledButton.tonal(
        onPressed: null,
        child: Text(
          connecting ? l10n.floMeetsConnecting : l10n.floMeetsWaitingForThem,
        ),
      );
    }

    return FilledButton.icon(
      onPressed: onConnect,
      icon: const Icon(Icons.handshake_outlined),
      label: Text(l10n.floMeetsConnectCta),
    );
  }
}
