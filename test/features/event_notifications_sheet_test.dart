import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/providers/agenda_alerts_provider.dart';
import 'package:flo_compass/providers/app_settings_provider.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';
import 'package:flo_compass/providers/profile_provider.dart';
import 'package:flo_compass/shared/widgets/event_notifications_sheet.dart';
import '../support/test_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventState()),
        ChangeNotifierProvider(create: (_) => PlanState()),
        ChangeNotifierProvider(create: (_) => ProfileState()),
        ChangeNotifierProvider(create: (_) => AppSettingsState()),
        ChangeNotifierProvider(create: (_) => AgendaAlertsState()),
      ],
      child: MaterialApp(
        localizationsDelegates: testLocalizationDelegates,
        supportedLocales: testSupportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('shows agenda alert row and refresh footer', (tester) async {
    final agendaAlert = AgendaChangeAlert(
      id: 'alert-1',
      sessionId: 's-a',
      title: 'Keynote',
      type: AgendaChangeType.roomChanged,
      detectedAt: DateTime(2026, 11, 4, 9),
      reason: AgendaChangeReason.inPlan,
      previousVenueId: 'ven-G01',
      newVenueId: 'ven-601',
    );

    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () => showEventNotificationsSheet(
              context,
              agendaChangeAlerts: [agendaAlert],
              sessionAlerts: const [],
              leaveNowAlerts: const [],
              minutesUntil: (_) => 10,
              venueNameFor: (_) => 'Room 601',
              onDismissAgendaAlert: (_) {},
              onRefreshAgenda: () async {},
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Room changed'), findsOneWidget);
    expect(find.text('In plan'), findsOneWidget);
    expect(find.text('Refresh agenda'), findsOneWidget);
  });
}
