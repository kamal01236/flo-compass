import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flo_compass/l10n/app_localizations.dart';
import 'package:flo_compass/shared/widgets/offline_banner.dart';

void main() {
  Widget pumpUnderLocale(Locale locale) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: OfflineBanner()),
    );
  }

  testWidgets('OfflineBanner renders English message', (tester) async {
    await tester.pumpWidget(pumpUnderLocale(const Locale('en')));
    await tester.pumpAndSettle();
    expect(
      find.text("You're offline — showing saved Flo 2026 data."),
      findsOneWidget,
    );
  });

  testWidgets('OfflineBanner renders German message', (tester) async {
    await tester.pumpWidget(pumpUnderLocale(const Locale('de')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Du bist offline — gespeicherte Flo 2026-Daten werden angezeigt.',
      ),
      findsOneWidget,
    );
  });
}
