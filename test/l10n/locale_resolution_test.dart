import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flo_compass/l10n/app_localizations.dart';

void main() {
  testWidgets('supports EN DE ES locales', (tester) async {
    final expected = {'en': 'Discover', 'de': 'Entdecken', 'es': 'Descubrir'};
    for (final locale in AppLocalizations.supportedLocales) {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Text(l10n.tabDiscover);
            },
          ),
        ),
      );
      expect(find.text(expected[locale.languageCode]!), findsOneWidget);
    }
  });
}
