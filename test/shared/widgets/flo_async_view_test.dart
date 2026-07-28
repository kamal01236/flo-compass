import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flo_compass/shared/widgets/flo_async_view.dart';
import '../../support/test_localizations.dart';

void main() {
  testWidgets('shows loading then data', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: testLocalizationDelegates,
        supportedLocales: testSupportedLocales,
        home: FloAsyncView<String>(
          loading: false,
          error: null,
          data: 'ok',
          builder: (_, data) => Text(data),
        ),
      ),
    );
    expect(find.text('ok'), findsOneWidget);
  });

  testWidgets('shows error with retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: testLocalizationDelegates,
        supportedLocales: testSupportedLocales,
        home: FloAsyncView<String>(
          loading: false,
          error: 'fail',
          data: null,
          onRetry: () => retried = true,
          builder: (_, data) => Text(data),
        ),
      ),
    );
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });
}
