import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/shared/utils/session_note_excerpt.dart';

void main() {
  test('excerptSessionNote returns trimmed text when short', () {
    expect(excerptSessionNote('  hello world  '), 'hello world');
  });

  test('excerptSessionNote truncates long notes', () {
    final long = 'a' * 100;
    final excerpt = excerptSessionNote(long);
    expect(excerpt.length, sessionNoteExcerptLength + 1);
    expect(excerpt.endsWith('…'), isTrue);
  });

  test('excerptSessionNote returns empty for blank input', () {
    expect(excerptSessionNote('   '), isEmpty);
  });
}
