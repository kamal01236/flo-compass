import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flo_compass/shared/widgets/flo_meets_round_coordinator.dart';

void main() {
  testWidgets('FloMeetsRoundCoordinator is an idle passthrough', (
    tester,
  ) async {
    await tester.pumpWidget(
      const FloMeetsRoundCoordinator(
        child: MaterialApp(home: Scaffold(body: Text('idle'))),
      ),
    );
    expect(find.text('idle'), findsOneWidget);
  });
}
