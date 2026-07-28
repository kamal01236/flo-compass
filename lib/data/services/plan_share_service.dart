import 'dart:convert';

import '../../shared/utils/id_validator.dart';

class PlanShareService {
  String encodeSessionIds(Iterable<String> sessionIds) {
    final valid = sessionIds
        .map(IdValidator.sanitizeSessionId)
        .whereType<String>()
        .take(20)
        .toList();
    final payload = jsonEncode({'s': valid});
    return base64Url.encode(utf8.encode(payload));
  }

  List<String> decodeSessionIds(String encoded) {
    try {
      final raw = utf8.decode(base64Url.decode(encoded));
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (json['s'] as List<dynamic>? ?? [])
          .whereType<String>()
          .map(IdValidator.sanitizeSessionId)
          .whereType<String>()
          .take(20)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
