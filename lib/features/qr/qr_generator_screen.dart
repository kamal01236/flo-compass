import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/models/models.dart';
import '../../providers/event_provider.dart';
import '../../shared/utils/web_download.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'qr_url_builder.dart';

enum _QrTargetMode { session, room }

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final _qrKey = GlobalKey();
  _QrTargetMode _mode = _QrTargetMode.session;
  Session? _selectedSession;
  Venue? _selectedVenue;

  String get _origin => QrUrlBuilder.resolveOrigin(Uri.base);

  String? get _targetUrl {
    return switch (_mode) {
      _QrTargetMode.session when _selectedSession != null =>
        QrUrlBuilder.sessionUrl(_selectedSession!.id, origin: _origin),
      _QrTargetMode.room when _selectedVenue != null => QrUrlBuilder.roomUrl(
        _selectedVenue!.id,
        origin: _origin,
      ),
      _ => null,
    };
  }

  String get _label {
    return switch (_mode) {
      _QrTargetMode.session when _selectedSession != null =>
        _selectedSession!.title,
      _QrTargetMode.room when _selectedVenue != null => _selectedVenue!.name,
      _ => 'Select a target',
    };
  }

  Map<String, List<Venue>> _venuesByFloor(List<Venue> venues) {
    final grouped = <String, List<Venue>>{};
    for (final venue in venues) {
      grouped.putIfAbsent(venue.floor, () => []).add(venue);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    return grouped;
  }

  Future<void> _downloadPng() async {
    final context = _qrKey.currentContext;
    if (context == null) return;
    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    downloadPng(
      bytes.buffer.asUint8List(),
      'flo-compass-qr-${_mode == _QrTargetMode.session ? _selectedSession?.id ?? 'session' : _selectedVenue?.id ?? 'room'}.png',
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = context.watch<EventState>();

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/profile'),
          ),
        ),
        title: const Text('Demo QR posters'),
      ),
      body: ResponsiveLayout(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'For Flo 2026 demo signage. Complements Accelevents — not official check-in.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            SegmentedButton<_QrTargetMode>(
              segments: const [
                ButtonSegment(
                  value: _QrTargetMode.session,
                  label: Text('Session'),
                ),
                ButtonSegment(value: _QrTargetMode.room, label: Text('Room')),
              ],
              selected: {_mode},
              onSelectionChanged: (selected) {
                setState(() => _mode = selected.first);
              },
            ),
            const SizedBox(height: 16),
            if (_mode == _QrTargetMode.session) ...[
              Autocomplete<Session>(
                optionsBuilder: (textEditingValue) {
                  final query = textEditingValue.text.trim().toLowerCase();
                  if (query.isEmpty) {
                    return event.sessions.take(20);
                  }
                  return event.sessions.where((session) {
                    return session.id.toLowerCase().contains(query) ||
                        session.title.toLowerCase().contains(query);
                  });
                },
                displayStringForOption: (session) =>
                    '${session.title} (${session.id})',
                onSelected: (session) {
                  setState(() => _selectedSession = session);
                },
                fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Search session',
                      hintText: 'Title or id',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  );
                },
              ),
            ] else ...[
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Room',
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Venue>(
                    isExpanded: true,
                    value: _selectedVenue,
                    hint: const Text('Select a room'),
                    items: [
                      for (final floor in const [
                        'G',
                        '6',
                        '7',
                        '8',
                        '9',
                        '10',
                        '11',
                        '12',
                        '13',
                      ])
                        for (final venue
                            in _venuesByFloor(event.venues)[floor] ??
                                const <Venue>[])
                          DropdownMenuItem(
                            value: venue,
                            child: Text(
                              '${floor == 'G' ? 'Ground' : 'Floor $floor'} — '
                              '${venue.name} (${venue.id})',
                            ),
                          ),
                    ],
                    onChanged: (venue) =>
                        setState(() => _selectedVenue = venue),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (_targetUrl != null)
              RepaintBoundary(
                key: _qrKey,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        QrImageView(
                          data: _targetUrl!,
                          size: 240,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _label,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          _targetUrl!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              const EmptyState(
                title: 'Pick a session or room',
                message: 'The QR code appears here once you choose a target.',
                icon: Icons.qr_code_2,
              ),
            const SizedBox(height: 16),
            if (_targetUrl != null)
              FilledButton.icon(
                onPressed: _downloadPng,
                icon: const Icon(Icons.download),
                label: const Text('Download PNG'),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _targetUrl == null
                  ? null
                  : () => context.push(_targetUrl!.replaceFirst(_origin, '')),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open target in app'),
            ),
          ],
        ),
      ),
    );
  }
}
