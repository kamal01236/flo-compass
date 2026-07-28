import '../models/models.dart';

class StreamAction {
  const StreamAction({
    required this.label,
    this.url,
    this.isMock = false,
    this.isStreamable = false,
  });

  final String label;
  final String? url;
  final bool isMock;
  final bool isStreamable;

  static const none = StreamAction(label: 'On-site only', isStreamable: false);
}

class SessionStreamResolver {
  const SessionStreamResolver();

  static const _featuredStreams = <String, String>{
    's-001': 'https://demo.flo-compass.example/stream/s-001',
    's-002': 'https://demo.flo-compass.example/stream/s-002',
    's-003': 'https://demo.flo-compass.example/stream/s-003',
    's-010': 'https://demo.flo-compass.example/stream/s-010',
    's-020': 'https://demo.flo-compass.example/stream/s-020',
  };

  StreamAction resolve(Session session) {
    if (!_isStreamableFormat(session.format)) {
      return StreamAction.none;
    }

    final mapped = _featuredStreams[session.id];
    if (mapped != null) {
      return StreamAction(
        label: 'Join demo stream',
        url: mapped,
        isMock: true,
        isStreamable: true,
      );
    }

    if (session.featured) {
      return StreamAction(
        label: 'Stream likely (demo)',
        url: 'https://demo.flo-compass.example/stream/${session.id}',
        isMock: true,
        isStreamable: true,
      );
    }

    return StreamAction(
      label: 'May be streamed',
      isMock: true,
      isStreamable: true,
    );
  }

  bool _isStreamableFormat(String format) {
    return isStreamableFormat(format);
  }

  /// Public heuristic for keynote/panel/AMA/fireside formats.
  static bool isStreamableFormat(String format) {
    final lower = format.toLowerCase();
    return lower.contains('keynote') ||
        lower.contains('panel') ||
        lower.contains('ama') ||
        lower.contains('fireside');
  }
}
