import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flo_compass/features/operations/organizer_operations_panel.dart';
import 'package:flo_compass/providers/announcement_provider.dart';
import 'package:flo_compass/providers/organizer_dashboard_provider.dart';
import '../../support/test_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap({
    required OrganizerDashboardState dashboard,
    required AnnouncementState announcements,
    required Widget child,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dashboard),
        ChangeNotifierProvider.value(value: announcements),
      ],
      child: MaterialApp(
        localizationsDelegates: testLocalizationDelegates,
        supportedLocales: testSupportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('shows dashboard error with retry', (tester) async {
    final dashboard = OrganizerDashboardState();
    final announcements = AnnouncementState();

    await tester.pumpWidget(
      wrap(
        dashboard: dashboard,
        announcements: announcements,
        child: const OrganizerOperationsPanel(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    dashboard.error = 'Stats unavailable';
    dashboard.notifyListeners();
    await tester.pump();

    expect(find.text('Stats unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('retry reloads dashboard', (tester) async {
    final dashboard = OrganizerDashboardState();
    final announcements = AnnouncementState();

    await tester.pumpWidget(
      wrap(
        dashboard: dashboard,
        announcements: announcements,
        child: const OrganizerOperationsPanel(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    dashboard.error = 'Stats unavailable';
    dashboard.notifyListeners();
    await tester.pump();

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(dashboard.loading || dashboard.error == null, isTrue);
  });
}
