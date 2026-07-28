import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'every learning path sessionId exists in flo2026_sessions.json',
    () async {
      final sessionsRaw = await File(
        'assets/data/flo2026_sessions.json',
      ).readAsString();
      final sessions = (jsonDecode(sessionsRaw) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final sessionIds = sessions.map((s) => s['id'] as String).toSet();

      final pathsRaw = await File(
        'assets/data/learning_paths.json',
      ).readAsString();
      final pathsDoc = jsonDecode(pathsRaw) as Map<String, dynamic>;
      final paths = (pathsDoc['paths'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      expect(paths.length, inInclusiveRange(5, 8));

      for (final path in paths) {
        final ids = (path['sessionIds'] as List<dynamic>).cast<String>();
        expect(ids, isNotEmpty, reason: 'path ${path['id']} empty');
        for (final id in ids) {
          expect(
            sessionIds,
            contains(id),
            reason: 'unknown session $id in ${path['id']}',
          );
        }
      }
    },
  );
}
