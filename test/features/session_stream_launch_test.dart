import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/shared/utils/safe_launch_url.dart';
import 'package:flo_compass/shared/utils/session_stream_launch.dart';

void main() {
  test('isAllowedLaunchScheme rejects javascript', () {
    expect(isAllowedLaunchScheme(Uri.parse('javascript:alert(1)')), isFalse);
  });

  test('isAllowedLaunchScheme accepts https demo stream', () {
    expect(
      isAllowedLaunchScheme(
        Uri.parse('https://demo.flo-compass.example/stream/s-001'),
      ),
      isTrue,
    );
  });

  testWidgets('launchDemoStream shows snackbar for blocked scheme', (
    tester,
  ) async {
    var launched = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                launched = await launchDemoStream(
                  context,
                  'javascript:void(0)',
                  launch: (_) async => true,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(launched, isFalse);
    expect(
      find.text('Could not open stream — link blocked or invalid'),
      findsOneWidget,
    );
  });

  testWidgets('launchDemoStream invokes launcher for allowed URL', (
    tester,
  ) async {
    Uri? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                await launchDemoStream(
                  context,
                  'https://demo.flo-compass.example/stream/s-001',
                  launch: (uri) async {
                    opened = uri;
                    return true;
                  },
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();

    expect(opened?.toString(), 'https://demo.flo-compass.example/stream/s-001');
  });
}
