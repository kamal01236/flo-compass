import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/shared/utils/id_validator.dart';

void main() {
  group('session ids', () {
    test('accepts valid session ids', () {
      expect(IdValidator.isValidSessionId('s-001'), isTrue);
      expect(IdValidator.isValidSessionId('s-1234'), isTrue);
      expect(IdValidator.sanitizeSessionId('s-001'), 's-001');
    });

    test('rejects invalid session ids', () {
      expect(IdValidator.isValidSessionId('../../../evil'), isFalse);
      expect(IdValidator.isValidSessionId('s-99999'), isFalse);
      expect(IdValidator.isValidSessionId('s-01'), isFalse);
      expect(IdValidator.sanitizeSessionId('bad'), isNull);
    });
  });

  group('speaker ids', () {
    test('accepts spk-NNN', () {
      expect(IdValidator.isValidSpeakerId('spk-001'), isTrue);
      expect(IdValidator.sanitizeSpeakerId('spk-030'), 'spk-030');
    });

    test('rejects invalid speaker ids', () {
      expect(IdValidator.sanitizeSpeakerId('spk-1'), isNull);
      expect(IdValidator.sanitizeSpeakerId('speaker-001'), isNull);
    });
  });

  group('venue ids', () {
    test('accepts ven- prefix with alphanumerics', () {
      expect(IdValidator.isValidVenueId('ven-601'), isTrue);
      expect(IdValidator.isValidVenueId('ven-C601'), isTrue);
      expect(IdValidator.sanitizeVenueId('ven-G01'), 'ven-G01');
    });

    test('rejects lowercase-only invalid venue ids', () {
      expect(IdValidator.sanitizeVenueId('ven-evil/path'), isNull);
    });
  });

  group('learning path ids', () {
    test('accepts path- slug', () {
      expect(IdValidator.isValidLearningPathId('path-ai-leadership'), isTrue);
      expect(
        IdValidator.sanitizeLearningPathId('path-ai-leadership'),
        'path-ai-leadership',
      );
    });
  });

  group('track ids', () {
    test('accepts trk-NN', () {
      expect(IdValidator.isValidTrackId('trk-01'), isTrue);
      expect(IdValidator.sanitizeTrackId('trk-10'), 'trk-10');
    });

    test('rejects invalid track ids', () {
      expect(IdValidator.sanitizeTrackId('trk-1'), isNull);
    });
  });
}
