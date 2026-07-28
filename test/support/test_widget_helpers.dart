import 'package:flutter_test/flutter_test.dart';

import 'package:flo_compass/providers/event_provider.dart';

Future<void> boundedPumpAndSettle(
  WidgetTester tester, {
  Duration step = const Duration(milliseconds: 16),
  int maxTicks = 50,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    if (!tester.binding.hasScheduledFrame) return;
  }
  throw StateError('boundedPumpAndSettle timed out');
}

Future<void> disposeEventState(EventState event, WidgetTester tester) async {
  event.dispose();
  await tester.pump();
}
