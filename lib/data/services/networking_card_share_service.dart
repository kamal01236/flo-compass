import 'dart:convert';

import '../../shared/utils/linkedin_url.dart';
import '../models/networking_card.dart';

/// Encodes/decodes networking card payloads as base64url JSON tokens.
class NetworkingCardShareService {
  String encode(NetworkingCard card) {
    final payload = <String, dynamic>{};
    final name = card.displayName.trim();
    if (name.isNotEmpty) payload['n'] = name;
    final title = card.jobTitle?.trim();
    if (title != null && title.isNotEmpty) payload['t'] = title;
    final company = card.company?.trim();
    if (company != null && company.isNotEmpty) payload['c'] = company;
    if (card.email.visible) {
      final email = card.email.value.trim();
      if (email.isNotEmpty) payload['e'] = email;
    }
    if (card.linkedInUrl.visible) {
      final linkedIn =
          normalizeLinkedInUrl(card.linkedInUrl.value.trim()) ??
          card.linkedInUrl.value.trim();
      if (linkedIn.isNotEmpty) payload['l'] = linkedIn;
    }
    return base64Url.encode(utf8.encode(jsonEncode(payload)));
  }

  NetworkingCardPayload? decode(String token) {
    try {
      final raw = utf8.decode(base64Url.decode(token));
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final name = (json['n'] as String? ?? '').trim();
      if (name.isEmpty) return null;
      return NetworkingCardPayload(
        displayName: name,
        jobTitle: _optionalString(json['t']),
        company: _optionalString(json['c']),
        email: _optionalString(json['e']),
        linkedInUrl: _optionalLinkedIn(json['l']),
      );
    } catch (_) {
      return null;
    }
  }

  String? _optionalString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _optionalLinkedIn(dynamic value) {
    final raw = _optionalString(value);
    if (raw == null) return null;
    return normalizeLinkedInUrl(raw);
  }
}
