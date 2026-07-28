import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/name_initials.dart';
import '../../utils/session_capacity.dart';
import '../../../data/services/session_stream_resolver.dart';

class SessionCard extends StatefulWidget {
  const SessionCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.matchReasons = const [],
    this.featured = false,
    this.inPlan = false,
    this.trackColor,
    this.occupancyPercent = 40,
    this.attendeeInterestCount = 0,
    this.showSocialProof = false,
    this.speakerName,
    this.speakerPhotoAsset,
    this.hideSpeakerPhoto = false,
    this.plainEnglishSummary,
    this.sessionAbstract,
    this.sessionFormat,
    this.onTap,
    this.onTapDown,
    this.onTogglePlan,
    this.trailing,
    this.streamNudgeLabel,
  });

  final String title;
  final String subtitle;
  final List<String> matchReasons;
  final bool featured;
  final bool inPlan;
  final Color? trackColor;
  final int occupancyPercent;
  final int attendeeInterestCount;
  final bool showSocialProof;
  final String? speakerName;
  final String? speakerPhotoAsset;
  final bool hideSpeakerPhoto;
  final String? plainEnglishSummary;
  final String? sessionAbstract;
  final String? sessionFormat;
  final VoidCallback? onTap;
  final GestureTapDownCallback? onTapDown;
  final VoidCallback? onTogglePlan;
  final Widget? trailing;
  final String? streamNudgeLabel;

  @override
  State<SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<SessionCard> {
  bool _abstractExpanded = false;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final (capacityColor, capacityLabel) = capacityPresentation(
      widget.occupancyPercent,
    );
    final streamable =
        widget.sessionFormat != null &&
        SessionStreamResolver.isStreamableFormat(widget.sessionFormat!);
    final nudge = streamNudgeFor(
      occupancyPercent: widget.occupancyPercent,
      isStreamable: streamable,
    );
    final showPlainEnglish = widget.plainEnglishSummary != null;
    return Semantics(
      label: 'Session ${widget.title}. ${widget.subtitle}',
      button: widget.onTap != null,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: widget.onTapDown,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: widget.trackColor != null
                ? BoxDecoration(
                    border: Border(
                      left: BorderSide(color: widget.trackColor!, width: 4),
                    ),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.speakerName != null) ...[
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              widget.trackColor ?? AppColors.accentStart,
                          backgroundImage:
                              widget.hideSpeakerPhoto ||
                                  widget.speakerPhotoAsset == null
                              ? null
                              : AssetImage(widget.speakerPhotoAsset!),
                          child:
                              widget.hideSpeakerPhoto ||
                                  widget.speakerPhotoAsset == null
                              ? Text(
                                  nameInitials(widget.speakerName!),
                                  style: const TextStyle(fontSize: 12),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (widget.featured)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Tooltip(
                                  message: 'Featured session',
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 16,
                                        color: AppColors.accentStart,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Featured',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (widget.onTogglePlan != null ||
                          widget.trailing != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.onTogglePlan != null)
                              Semantics(
                                label: widget.inPlan
                                    ? 'Remove from plan'
                                    : 'Add to plan',
                                button: true,
                                child: IconButton(
                                  tooltip: widget.inPlan
                                      ? 'Remove from plan'
                                      : 'Add to plan',
                                  constraints: const BoxConstraints(
                                    minWidth: 44,
                                    minHeight: 44,
                                  ),
                                  onPressed: widget.onTogglePlan,
                                  icon: Icon(
                                    widget.inPlan
                                        ? Icons.bookmark
                                        : Icons.bookmark_outline,
                                    color: widget.inPlan
                                        ? AppColors.accentStart
                                        : null,
                                  ),
                                ),
                              ),
                            if (widget.trailing != null) widget.trailing!,
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: muted,
                      fontSize: 13,
                    ),
                  ),
                  if (nudge != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      nudge.label,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (showPlainEnglish) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.plainEnglishSummary!,
                            maxLines: _abstractExpanded ? null : 2,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        if (widget.sessionAbstract != null &&
                            widget.sessionAbstract!.isNotEmpty)
                          Semantics(
                            label: _abstractExpanded
                                ? 'Collapse session abstract'
                                : 'Expand session abstract',
                            button: true,
                            child: IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                              tooltip: _abstractExpanded
                                  ? 'Hide abstract'
                                  : 'Show abstract',
                              onPressed: () => setState(
                                () => _abstractExpanded = !_abstractExpanded,
                              ),
                              icon: Icon(
                                _abstractExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_abstractExpanded &&
                        widget.sessionAbstract != null &&
                        widget.sessionAbstract!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.sessionAbstract!,
                        style: TextStyle(
                          color: muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Tooltip(
                        message: 'Simulated capacity for demo purposes',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 10, color: capacityColor),
                            const SizedBox(width: 4),
                            Text(
                              capacityLabel,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (widget.showSocialProof)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${widget.attendeeInterestCount} saved',
                              style: TextStyle(
                                fontSize: 12,
                                color: muted,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Tooltip(
                              message:
                                  'Demo estimate — not official attendance',
                              child: Icon(
                                Icons.info_outline,
                                size: 14,
                                color: muted.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (widget.matchReasons.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final reason in widget.matchReasons)
                          Chip(
                            label: Text(
                              reason,
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
