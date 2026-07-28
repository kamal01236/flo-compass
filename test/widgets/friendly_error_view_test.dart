import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/shared/utils/friendly_error_messages.dart';
import 'package:flo_compass/shared/widgets/shared_widgets.dart';
import '../support/test_localizations.dart';

void main() {
  testWidgets('ErrorView shows friendly title, Retry, and Semantics', (
    tester,
  ) async {
    const kind = FriendlyErrorKind.loadFailure;
    final expected = FriendlyErrorCopy.random(kind, random: Random(0));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: testLocalizationDelegates,
        supportedLocales: testSupportedLocales,
        home: Scaffold(
          body: ErrorView(
            kind: kind,
            random: Random(0),
            technicalDetail: 'Failed to load event data.',
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.text(expected.title), findsOneWidget);
    expect(find.text(expected.message), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel(expected.semanticLabel), findsOneWidget);
    handle.dispose();
  });

  testWidgets('ErrorBoundary shows runtime copy after runtimeError fires', (
    tester,
  ) async {
    final runtimeError = ValueNotifier<Object?>(null);
    const runtimeTitles = [
      'Our compass spun north, south, and into the parking lot.',
      'Unscripted moment — not on the official schedule.',
      'We tripped over a cable in Ballroom A.',
      'Plot twist: the UI took an unplanned intermission.',
      'Even the best demos have a dress rehearsal.',
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: testLocalizationDelegates,
        supportedLocales: testSupportedLocales,
        home: ErrorBoundary(
          runtimeError: runtimeError,
          child: const Text('App content'),
        ),
      ),
    );

    expect(find.text('App content'), findsOneWidget);

    runtimeError.value = Exception('test');
    await tester.pump();

    expect(find.text('App content'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && runtimeTitles.contains(widget.data),
      ),
      findsOneWidget,
    );
    final handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel('Unexpected application error. Retry available.'),
      findsOneWidget,
    );
    handle.dispose();

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(find.text('App content'), findsOneWidget);
    runtimeError.dispose();
  });
}
