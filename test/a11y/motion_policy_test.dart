import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/shared/a11y/motion_policy.dart';
import 'package:flo_compass/shared/widgets/streaming_text.dart';

void main() {
  testWidgets('StreamingText shows full text when disableAnimations is true', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(body: StreamingText(text: 'Hello Flo Compass')),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Hello Flo Compass'), findsOneWidget);
  });

  testWidgets('shouldAnimate is false when disableAnimations is true', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(shouldAnimate(ctx), isFalse);
  });
}
