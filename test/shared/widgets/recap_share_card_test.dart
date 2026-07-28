import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/shared/theme/app_theme.dart';
import 'package:flo_compass/shared/widgets/recap_share_card.dart';

void main() {
  testWidgets('RecapShareCard shows headline and stats', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Center(
            child: RecapShareCard(
              xp: 175,
              levelLabel: 'Explorer · Lvl 2',
              bookmarked: 8,
              attended: 3,
              tracksExplored: 4,
              topRatedTrack: 'GenAI Engineering',
              plannedSessionTitles: const [
                'Live Lab: Ship an Agentic Cursor Workflow',
                'Opening Keynote: Flo 2026',
                'Panel: Responsible AI at Scale',
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Flo Compass'), findsOneWidget);
    expect(find.text('My Flo 2026'), findsOneWidget);
    expect(find.text('175 XP'), findsOneWidget);
    expect(find.text('Explorer · Lvl 2'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('Bookmarked'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Attended'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Tracks'), findsOneWidget);
    expect(find.text('Top rated track'), findsOneWidget);
    expect(find.text('GenAI Engineering'), findsOneWidget);
    expect(find.text('On my plan'), findsOneWidget);
    expect(
      find.text('Live Lab: Ship an Agentic Cursor Workflow'),
      findsOneWidget,
    );
  });

  testWidgets('RecapShareCard omits optional sections when empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: RecapShareCard(
            xp: 0,
            levelLabel: 'Explorer · Lvl 1',
            bookmarked: 0,
            attended: 0,
            tracksExplored: 0,
          ),
        ),
      ),
    );

    expect(find.text('Flo Compass'), findsOneWidget);
    expect(find.text('My Flo 2026'), findsOneWidget);
    expect(find.text('Top rated track'), findsNothing);
    expect(find.text('On my plan'), findsNothing);
  });
}
