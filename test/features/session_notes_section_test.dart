import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flo_compass/features/session_detail/widgets/session_notes_section.dart';
import 'package:flo_compass/providers/engagement_provider.dart';

void main() {
  testWidgets('SessionNoteEditor preloads saved notes', (tester) async {
    final engagement = EngagementState();
    engagement.snapshot = EngagementSnapshot.empty.copyWith(
      notesBySessionId: const {'s-001': 'Remember this moment.'},
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: engagement,
        child: const MaterialApp(
          home: Scaffold(body: SessionNoteEditor(sessionId: 's-001')),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, 'Remember this moment.');
  });

  testWidgets('SessionNotesExpandable shows excerpt when collapsed', (
    tester,
  ) async {
    final engagement = EngagementState();
    engagement.snapshot = EngagementSnapshot.empty.copyWith(
      notesBySessionId: const {
        's-001': 'Remember the AI roadmap quote from the keynote.',
      },
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: engagement,
        child: const MaterialApp(
          home: Scaffold(body: SessionNotesExpandable(sessionId: 's-001')),
        ),
      ),
    );

    expect(find.text('Notes'), findsOneWidget);
    expect(find.textContaining('AI roadmap'), findsOneWidget);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pump();
    expect(find.byIcon(Icons.expand_less), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('SessionNotesExpandable shows Add a note when empty', (
    tester,
  ) async {
    final engagement = EngagementState();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: engagement,
        child: const MaterialApp(
          home: Scaffold(body: SessionNotesExpandable(sessionId: 's-001')),
        ),
      ),
    );

    expect(find.text('Add a note'), findsOneWidget);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('SessionNotesExpandable keeps editor open when field is tapped', (
    tester,
  ) async {
    final engagement = EngagementState();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: engagement,
        child: const MaterialApp(
          home: Scaffold(body: SessionNotesExpandable(sessionId: 's-001')),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pump();

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Takeaway from session');
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.expand_less), findsOneWidget);
    expect(find.text('Takeaway from session'), findsOneWidget);
  });
}
