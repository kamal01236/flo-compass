import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/services/navigation_history_service.dart';
import '../../data/services/navigation_search_service.dart';
import '../../providers/context_adapters.dart';
import '../../providers/event_provider.dart';
import '../../providers/plan_provider.dart';
import '../../shared/utils/now_next_resolver.dart';

class CommandPalette extends StatefulWidget {
  const CommandPalette({super.key, required this.router, this.historyService});

  final GoRouter router;
  final NavigationHistoryService? historyService;

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _historyService = NavigationHistoryService();
  Timer? _debounce;
  String _query = '';
  int _selectedIndex = 0;
  List<NavigationHistoryEntry> _recent = const [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final service = widget.historyService ?? _historyService;
    final recent = await service.load();
    if (!mounted) return;
    setState(() => _recent = recent);
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      setState(() {
        _query = _controller.text;
        _selectedIndex = 0;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onConflicts(BuildContext context, GoRouter router) {
    router.go('/my-plan');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scroll to conflicts in My Plan')),
    );
  }

  NavigationSearchGroups _buildGroups(BuildContext context) {
    final event = context.watch<EventState>();
    final plan = context.watch<PlanState>();
    final nowNext = resolveNowNext(
      planned: plan.plannedSessions(event.sessions),
      minutesUntil: event.minutesUntil,
      minutesRemaining: event.minutesRemaining,
      liveFallback: event.happeningNow(),
    );
    return NavigationSearchService.search(
      _query,
      catalog: buildNavigationSearchContext(event),
      plannedSessions: plan.plannedSessions(event.sessions),
      nowNext: nowNext,
      onConflicts: _onConflicts,
    );
  }

  List<_PaletteRow> _flattenRows(NavigationSearchGroups groups) {
    final rows = <_PaletteRow>[];
    if (_query.trim().isEmpty && _recent.isNotEmpty) {
      rows.add(const _PaletteRow.header('Recent'));
      for (final entry in _recent) {
        rows.add(_PaletteRow.recent(entry));
      }
    }
    if (groups.actions.isNotEmpty) {
      rows.add(const _PaletteRow.header('Actions'));
      for (final item in groups.actions) {
        rows.add(_PaletteRow.result(item));
      }
    }
    if (groups.sessions.isNotEmpty) {
      rows.add(const _PaletteRow.header('Sessions'));
      for (final item in groups.sessions) {
        rows.add(_PaletteRow.result(item));
      }
    }
    if (groups.speakers.isNotEmpty) {
      rows.add(const _PaletteRow.header('Speakers'));
      for (final item in groups.speakers) {
        rows.add(_PaletteRow.result(item));
      }
    }
    if (groups.venues.isNotEmpty) {
      rows.add(const _PaletteRow.header('Venues'));
      for (final item in groups.venues) {
        rows.add(_PaletteRow.result(item));
      }
    }
    if (groups.tracks.isNotEmpty) {
      rows.add(const _PaletteRow.header('Tracks'));
      for (final item in groups.tracks) {
        rows.add(_PaletteRow.result(item));
      }
    }
    return rows;
  }

  List<_PaletteRow> _selectableRows(List<_PaletteRow> rows) {
    return rows.where((r) => r.isSelectable).toList();
  }

  Future<void> _executeRow(_PaletteRow row) async {
    final router = widget.router;
    final service = widget.historyService ?? _historyService;

    if (row.recent != null) {
      final entry = row.recent!;
      unawaited(
        service.record(
          route: entry.route,
          label: entry.label,
          subtitle: entry.subtitle,
        ),
      );
      Navigator.of(context).pop();
      if (entry.route.startsWith('/session/') ||
          entry.route.startsWith('/speaker/')) {
        router.push(entry.route);
      } else {
        router.go(entry.route);
      }
      return;
    }

    final result = row.result!;
    final route = result.route ?? '';
    unawaited(
      service.record(
        route: route.isNotEmpty ? route : '/discover',
        label: result.label,
        subtitle: result.subtitle,
      ),
    );
    Navigator.of(context).pop();
    final rootContext = router.routerDelegate.navigatorKey.currentContext;
    result.execute(rootContext ?? context, router);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final groups = _buildGroups(context);
    final rows = _flattenRows(groups);
    final selectable = _selectableRows(rows);
    if (selectable.isEmpty) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1).clamp(0, selectable.length - 1);
      });
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1).clamp(0, selectable.length - 1);
      });
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      unawaited(_executeRow(selectable[_selectedIndex]));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _buildGroups(context);
    final rows = _flattenRows(groups);
    final selectable = _selectableRows(rows);
    if (_selectedIndex >= selectable.length) {
      _selectedIndex = selectable.isEmpty ? 0 : selectable.length - 1;
    }
    var selectableCursor = -1;

    return Dialog(
      child: SizedBox(
        width: 680,
        height: 520,
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search sessions, speakers, venues, tracks…',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: rows.isEmpty
                    ? const ListTile(
                        title: Text('No matches'),
                        subtitle: Text('Try a magic word: now, day2, map'),
                      )
                    : ListView.builder(
                        itemCount: rows.length,
                        itemBuilder: (context, index) {
                          final row = rows[index];
                          if (!row.isSelectable) {
                            return ListTile(
                              dense: true,
                              title: Text(
                                row.header!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                          selectableCursor++;
                          final selected = selectableCursor == _selectedIndex;
                          if (row.recent != null) {
                            final entry = row.recent!;
                            return ListTile(
                              selected: selected,
                              leading: const Icon(Icons.history),
                              title: Text(entry.label),
                              subtitle: entry.subtitle == null
                                  ? Text(entry.route)
                                  : Text(entry.subtitle!),
                              onTap: () => unawaited(_executeRow(row)),
                            );
                          }
                          final result = row.result!;
                          return ListTile(
                            selected: selected,
                            leading: Icon(result.icon),
                            title: Text(result.label),
                            subtitle: result.subtitle == null
                                ? null
                                : Text(result.subtitle!),
                            onTap: () => unawaited(_executeRow(row)),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteRow {
  const _PaletteRow._({this.header, this.result, this.recent});

  const _PaletteRow.header(String title) : this._(header: title);
  const _PaletteRow.result(NavigationResult r) : this._(result: r);
  const _PaletteRow.recent(NavigationHistoryEntry e) : this._(recent: e);

  final String? header;
  final NavigationResult? result;
  final NavigationHistoryEntry? recent;

  bool get isSelectable => result != null || recent != null;
}

Future<void> showCommandPalette(BuildContext context) async {
  final router = GoRouter.of(context);
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => CommandPalette(router: router),
  );
}
