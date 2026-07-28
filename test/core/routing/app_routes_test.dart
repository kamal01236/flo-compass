import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/core/routing/app_routes.dart';

void main() {
  group('sanitizeReturnTo', () {
    test('returns null for null or empty input', () {
      expect(AppRoutes.sanitizeReturnTo(null), isNull);
      expect(AppRoutes.sanitizeReturnTo(''), isNull);
    });

    test('rejects protocol-relative and absolute URLs', () {
      expect(AppRoutes.sanitizeReturnTo('//evil.com'), isNull);
      expect(AppRoutes.sanitizeReturnTo('https://evil.com'), isNull);
      expect(AppRoutes.sanitizeReturnTo('http://evil.com/path'), isNull);
    });

    test('accepts same-origin relative paths', () {
      expect(AppRoutes.sanitizeReturnTo('/discover'), '/discover');
      expect(AppRoutes.sanitizeReturnTo('/connect/abc123'), '/connect/abc123');
      expect(
        AppRoutes.sanitizeReturnTo(Uri.encodeComponent('/discover')),
        '/discover',
      );
    });
  });

  group('isVisitorLocation', () {
    test('treats connect token path as public via uri.path', () {
      expect(
        AppRoutes.isVisitorLocation('/discover', '/connect/abc123'),
        isTrue,
      );
    });

    test('treats connect token path as public via matchedLocation', () {
      expect(AppRoutes.isVisitorLocation('/connect/abc123', '/'), isTrue);
    });

    test('root path is not a visitor route', () {
      expect(AppRoutes.isVisitorLocation('/', '/'), isFalse);
    });

    test('discover is not a visitor route', () {
      expect(AppRoutes.isVisitorLocation('/discover', '/discover'), isFalse);
    });
  });

  group('isSharedPublicPath', () {
    test('connect edit and share are not public', () {
      expect(AppRoutes.isSharedPublicPath(AppRoutes.connectEdit), isFalse);
      expect(AppRoutes.isSharedPublicPath(AppRoutes.connectShare), isFalse);
    });

    test('connect token path is public', () {
      expect(AppRoutes.isSharedPublicPath('/connect/eyJhIjoxfQ'), isTrue);
    });

    test('/map and /map?room= are public', () {
      expect(AppRoutes.isSharedPublicPath('/map'), isTrue);
      expect(AppRoutes.isSharedPublicPath('/map?room=ven-601'), isTrue);
    });

    test('rejects map and directions prefix attacks', () {
      expect(AppRoutes.isSharedPublicPath('/mapping-attack'), isFalse);
      expect(AppRoutes.isSharedPublicPath('/directions-evil'), isFalse);
    });

    test('/session/s-001 is public; extra segments are not', () {
      expect(AppRoutes.isSharedPublicPath('/session/s-001'), isTrue);
      expect(AppRoutes.isSharedPublicPath('/session/s-001/extra'), isFalse);
    });

    test('/speaker and /learning-path reject extra segments', () {
      expect(AppRoutes.isSharedPublicPath('/speaker/spk-001'), isTrue);
      expect(AppRoutes.isSharedPublicPath('/speaker/spk-001/evil'), isFalse);
      expect(AppRoutes.isSharedPublicPath('/learning-path/path-ai'), isTrue);
      expect(
        AppRoutes.isSharedPublicPath('/learning-path/path-ai/extra'),
        isFalse,
      );
    });
  });
}
