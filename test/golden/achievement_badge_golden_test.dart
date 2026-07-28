import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/shared/widgets/achievement_badge.dart';

void main() {
  testWidgets('achievement badge renders expected labels', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: AchievementBadge(
              id: 'schedule_starter',
              name: 'Schedule Starter',
              description: 'You built your first plan.',
              unlockedAt: null,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Schedule Starter'), findsOneWidget);
    expect(find.textContaining('first plan'), findsOneWidget);
  });
}
