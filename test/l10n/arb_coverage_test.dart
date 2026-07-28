import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ensures every non-metadata key present in the template (`app_en.arb`) also
/// exists in every other locale ARB (`app_de.arb`, `app_es.arb`).
///
/// This is a fast, unit-level guard — no Flutter binding required, no shared
/// setup with widget tests. It parses the raw JSON so a missing key surfaces
/// with a clear failure message before it can regress the generated
/// AppLocalizations classes.
void main() {
  const arbDir = 'lib/l10n';
  const templateFile = 'app_en.arb';
  const otherLocaleFiles = ['app_de.arb', 'app_es.arb'];

  Map<String, dynamic> readArb(String fileName) {
    final file = File('$arbDir/$fileName');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'Expected ARB file at ${file.path}',
    );
    final decoded = jsonDecode(file.readAsStringSync());
    expect(
      decoded,
      isA<Map<String, dynamic>>(),
      reason: '${file.path} must be a JSON object',
    );
    return decoded as Map<String, dynamic>;
  }

  /// Non-metadata keys are the message keys themselves; metadata keys start
  /// with `@` (e.g. `@profileSignedInAs` describing placeholders) or the
  /// locale marker `@@locale`.
  Set<String> messageKeys(Map<String, dynamic> arb) {
    return arb.keys.where((key) => !key.startsWith('@')).toSet();
  }

  test('every en ARB key exists in de and es', () {
    final template = readArb(templateFile);
    final templateKeys = messageKeys(template);

    for (final localeFile in otherLocaleFiles) {
      final localeArb = readArb(localeFile);
      final localeKeys = messageKeys(localeArb);
      final missing = templateKeys.difference(localeKeys).toList()..sort();
      expect(
        missing,
        isEmpty,
        reason:
            '$localeFile is missing ${missing.length} key(s) present in '
            '$templateFile: $missing',
      );
    }
  });
}
