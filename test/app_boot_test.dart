import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/app.dart';
import 'support/consent_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await seedAcceptedConsent();
  });

  testWidgets('buildApp boots without exception', (tester) async {
    late Widget app;
    await tester.runAsync(() async {
      app = await buildApp();
    });
    await tester.pumpWidget(app);
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
