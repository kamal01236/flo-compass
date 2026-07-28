import '../../core/config/app_config.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/venue.dart';

class PageMetaSnapshot {
  const PageMetaSnapshot({
    required this.title,
    required this.description,
    required this.ogTitle,
    required this.ogUrl,
    required this.ogImage,
    this.ogType = 'website',
  });

  final String title;
  final String description;
  final String ogTitle;
  final String ogUrl;
  final String ogImage;
  final String ogType;
}

/// Returns [Uri.origin] on web http(s) loads; empty string in VM tests (`file:`).
String resolvePageMetaOrigin([Uri? base]) {
  final uri = base ?? Uri.base;
  final scheme = uri.scheme;
  if (scheme == 'http' || scheme == 'https') {
    return uri.origin;
  }
  return '';
}

PageMetaSnapshot defaults({required String origin}) {
  final image = _absoluteUrl(origin, '/icons/Icon-512.png');
  final url = _absoluteUrl(origin, '/');
  const title = AppConfig.appTitle;
  const description = AppConfig.appDescription;
  return PageMetaSnapshot(
    title: title,
    description: description,
    ogTitle: title,
    ogUrl: url,
    ogImage: image,
  );
}

PageMetaSnapshot forSession({
  required Session session,
  required String origin,
  Venue? venue,
}) {
  final image = _absoluteUrl(origin, '/icons/Icon-512.png');
  final url = _absoluteUrl(origin, '/session/${session.id}');
  final ogTitle = '${session.title} · Flo 2026';
  final description = _sessionDescription(session, venue);

  return PageMetaSnapshot(
    title: ogTitle,
    description: description,
    ogTitle: ogTitle,
    ogUrl: url,
    ogImage: image,
    ogType: 'article',
  );
}

PageMetaSnapshot forSessionRoute({
  required String sessionId,
  required String origin,
}) {
  final image = _absoluteUrl(origin, '/icons/Icon-512.png');
  final url = _absoluteUrl(origin, '/session/$sessionId');
  const ogTitle = 'Session · Flo 2026';
  return PageMetaSnapshot(
    title: ogTitle,
    description: AppConfig.appDescription,
    ogTitle: ogTitle,
    ogUrl: url,
    ogImage: image,
    ogType: 'article',
  );
}

String truncateMetaDescription(String raw, {int max = 160}) {
  final normalized = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= max) {
    return normalized;
  }

  final truncated = normalized.substring(0, max);
  final lastSpace = truncated.lastIndexOf(' ');
  if (lastSpace > max ~/ 2) {
    return '${truncated.substring(0, lastSpace).trim()}…';
  }
  return '${truncated.trim()}…';
}

String _sessionDescription(Session session, Venue? venue) {
  final trimmedAbstract = session.abstract.trim();
  if (trimmedAbstract.isNotEmpty) {
    return truncateMetaDescription(trimmedAbstract);
  }
  final venueName = venue?.name ?? session.venueId;
  return '${session.day} ${session.startTime} · $venueName';
}

String _absoluteUrl(String origin, String path) {
  final base = origin.endsWith('/')
      ? origin.substring(0, origin.length - 1)
      : origin;
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  return '$base$normalizedPath';
}
