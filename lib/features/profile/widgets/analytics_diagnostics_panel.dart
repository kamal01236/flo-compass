import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/di/service_locator.dart';
import '../../../shared/utils/web_download.dart';

/// Dev-profile diagnostics panel for recent analytics events.
class AnalyticsDiagnosticsPanel extends StatefulWidget {
  const AnalyticsDiagnosticsPanel({super.key});

  @override
  State<AnalyticsDiagnosticsPanel> createState() =>
      _AnalyticsDiagnosticsPanelState();
}

class _AnalyticsDiagnosticsPanelState extends State<AnalyticsDiagnosticsPanel> {
  int _count = 0;
  bool _loading = true;

  AnalyticsService? get _analytics =>
      sl.isRegistered<AnalyticsService>() ? sl<AnalyticsService>() : null;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final analytics = _analytics;
    if (analytics == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final count = await analytics.diagnosticsEventCount();
    if (!mounted) return;
    setState(() {
      _count = count;
      _loading = false;
    });
  }

  Future<void> _exportJson() async {
    final analytics = _analytics;
    if (analytics == null) return;
    final json = await analytics.exportJson();
    downloadText(
      json,
      'flo-compass-analytics.json',
      mimeType: 'application/json',
    );
  }

  Future<void> _clearBuffer() async {
    final analytics = _analytics;
    if (analytics == null) return;
    await analytics.clearBuffer();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Analytics buffer cleared')));
    await _refresh();
  }

  Future<void> _sendNow() async {
    final analytics = _analytics;
    if (analytics == null) return;
    await analytics.flush();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Remote analytics flush requested')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (AppConfig.configProfile != 'dev') {
      return const SizedBox.shrink();
    }

    final analytics = _analytics;
    if (analytics == null) {
      return const SizedBox.shrink();
    }

    final events = analytics.recentEvents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        Text('Diagnostics', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(
          'Anonymous usage events stored locally ($_count in ring buffer).',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator(strokeWidth: 2))
        else if (events.isEmpty)
          Text(
            'No events captured yet — navigate the app to populate.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          )
        else
          ...events
              .take(10)
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${e.name} · ${e.route ?? e.properties['route'] ?? '—'} · '
                    '${e.resolvedTimestamp().toIso8601String().substring(11, 19)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(onPressed: _refresh, child: const Text('Refresh')),
            OutlinedButton(
              onPressed: events.isEmpty ? null : _exportJson,
              child: const Text('Export JSON'),
            ),
            OutlinedButton(
              onPressed: events.isEmpty ? null : _clearBuffer,
              child: const Text('Clear buffer'),
            ),
            if (analytics.config.remoteEnabled)
              OutlinedButton(
                onPressed: _sendNow,
                child: const Text('Send now'),
              ),
          ],
        ),
      ],
    );
  }
}
