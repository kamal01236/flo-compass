/// Normalizes user-entered LinkedIn profile URLs for sharing and launch.
///
/// Returns a canonical `https://` URL when [raw] looks like a LinkedIn profile
/// link; otherwise returns `null`.
String? normalizeLinkedInUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  var candidate = trimmed;
  if (!candidate.contains('://')) {
    if (candidate.startsWith('linkedin.com') ||
        candidate.startsWith('www.linkedin.com')) {
      candidate = 'https://$candidate';
    } else if (candidate.startsWith('/in/')) {
      candidate = 'https://www.linkedin.com$candidate';
    } else if (candidate.startsWith('in/')) {
      candidate = 'https://www.linkedin.com/$candidate';
    } else {
      candidate = 'https://$candidate';
    }
  }

  final parsed = Uri.tryParse(candidate);
  if (parsed == null) return null;

  final scheme = parsed.scheme.isEmpty ? 'https' : parsed.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return null;

  final host = parsed.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
  if (host != 'linkedin.com') return null;

  final normalized = parsed.replace(scheme: 'https');
  return normalized.toString();
}
