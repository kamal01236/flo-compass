import '../support/test_agenda_alerts_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/services/event_clock_service.dart';
import 'package:flo_compass/features/shell/main_shell.dart';
import 'package:flo_compass/l10n/app_localizations.dart';
import 'package:flo_compass/providers/app_settings_provider.dart';
import 'package:flo_compass/providers/engagement_provider.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/providers/profile_provider.dart';
import 'package:flo_compass/shared/utils/discover_scroll_bridge.dart';
import 'package:flo_compass/shared/widgets/event_notification_icon_button.dart';
import 'package:flo_compass/shared/widgets/now_next_bar.dart';
import 'package:flo_compass/shared/widgets/pre_event_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const session = Session(
    id: 's-001',
    title: 'CEO Keynote',
    abstract: 'a',
    day: 'Day 1',
    startTime: '10:00',
    endTime: '11:00',
    venueId: 'ven-G01',
    trackId: 'trk-01',
    speakerIds: ['spk-001'],
    tags: ['genai'],
    format: 'Keynote',
    level: 'beginner',
    featured: true,
    capacity: 100,
    building: 'Nagarro Gurgaon Office',
  );

  late EventState event;
  late PlanState plan;
  late ProfileState profileState;
  late AppSettingsState appSettings;
  late EngagementState engagement;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    final clock = EventClockService();
    clock.setOverride(DateTime(2026, 11, 4, 10, 30));
    event = EventState(eventClockService: clock);
    event.loading = false;
    event.sessions = [session];
    plan = PlanState(prefs: prefs);
    await plan.init();
    await plan.toggle(session.id);
    profileState = ProfileState(prefs: prefs);
    await profileState.init();
    engagement = EngagementState(prefs: prefs);
    await engagement.init();
    appSettings = AppSettingsState(prefs: prefs);
    await appSettings.init();
  });

  tearDown(() {
    event.dispose();
  });

  Widget buildShell({required EventDayMode mode, required Size viewport}) {
    appSettings.settings = AppSettings(
      themeMode: AppThemeMode.dark,
      eventDayMode: mode,
    );

    final router = GoRouter(
      initialLocation: '/discover',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/discover',
                  builder: (context, state) =>
                      const _ScrollableDiscoverForTest(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/companion',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Companion content')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/meets',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Meets content')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/my-plan',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Plan content')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => Scaffold(
                    appBar: AppBar(
                      actions: const [EventNotificationAppBarAction()],
                    ),
                    body: const Text('Profile content'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: event),
        ChangeNotifierProvider.value(value: plan),
        ChangeNotifierProvider.value(value: profileState),
        ChangeNotifierProvider.value(value: engagement),
        ChangeNotifierProvider.value(value: appSettings),
        testAgendaAlertsProvider(),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(size: viewport, disableAnimations: true),
            child: child!,
          );
        },
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  testWidgets('hides event day header before Day 1', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    event.setDemoTime(DateTime(2026, 11, 3, 12, 0));

    await tester.pumpWidget(
      buildShell(mode: EventDayMode.on, viewport: const Size(390, 844)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PreEventBanner), findsNothing);
    expect(find.byType(NowNextBar), findsNothing);

    event.setDemoTime(DateTime(2026, 11, 4, 10, 30));
  });

  testWidgets('shows NowNextBar with map and bell when event day mode is on', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildShell(mode: EventDayMode.on, viewport: const Size(390, 844)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(NowNextBar), findsOneWidget);
    expect(find.text('CEO Keynote'), findsOneWidget);
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
    expect(find.text('Ask Flo'), findsOneWidget);
    expect(find.text('My Plan'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);
  });

  testWidgets('shows compact map and bell when plan is empty', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await plan.clear();
    expect(plan.isInPlan(session.id), isFalse);
    event.setDemoTime(DateTime(2026, 11, 4, 8, 0));

    await tester.pumpWidget(
      buildShell(mode: EventDayMode.on, viewport: const Size(390, 844)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NowNextBar), findsOneWidget);
    expect(find.text('NOW'), findsNothing);
    expect(find.text('NEXT'), findsNothing);
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(find.text('CEO Keynote'), findsNothing);

    event.setDemoTime(DateTime(2026, 11, 4, 10, 30));
  });

  testWidgets('hides NowNextBar when event day mode is off', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildShell(mode: EventDayMode.off, viewport: const Size(390, 844)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(NowNextBar), findsNothing);
    expect(find.byType(ActionChip), findsNothing);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.byType(ActionChip), findsNothing);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
  });

  testWidgets('no overflow at 360x640 with event day on', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildShell(mode: EventDayMode.on, viewport: const Size(360, 640)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(NowNextBar), findsOneWidget);
  });

  testWidgets('desktop width layout with event day on has no exception', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildShell(mode: EventDayMode.on, viewport: const Size(1400, 900)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(NowNextBar), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
    expect(find.text('Item 0'), findsOneWidget);
  });

  testWidgets('collapses NowNextBar after scroll on mobile', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildShell(mode: EventDayMode.on, viewport: const Size(390, 844)),
    );
    await tester.pumpAndSettle();

    final expandedHeight = tester.getSize(find.byType(NowNextBar)).height;
    expect(expandedHeight, greaterThan(40));

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();

    final collapsedHeight = tester.getSize(find.byType(NowNextBar)).height;
    expect(collapsedHeight, lessThan(expandedHeight));
  });
}

class _ScrollableDiscoverForTest extends StatefulWidget {
  const _ScrollableDiscoverForTest();

  @override
  State<_ScrollableDiscoverForTest> createState() =>
      _ScrollableDiscoverForTestState();
}

class _ScrollableDiscoverForTestState
    extends State<_ScrollableDiscoverForTest> {
  final _controller = ScrollController();
  DiscoverScrollBridge? _bridge;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bridge = DiscoverScrollBridge.maybeOf(context);
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bridge?.register(() {
        if (!_controller.hasClients) return;
        _controller.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    });
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final offset = _controller.offset;
    _bridge?.reportScrollOffset(offset, atTop: offset <= 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _controller,
      itemCount: 50,
      itemBuilder: (_, index) => ListTile(title: Text('Item $index')),
    );
  }
}
