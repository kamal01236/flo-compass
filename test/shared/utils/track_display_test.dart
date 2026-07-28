import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/shared/utils/track_display.dart';

void main() {
  test('trackShortLabel returns short names unchanged', () {
    expect(trackShortLabel('AI & GenAI'), 'AI & GenAI');
    expect(trackShortLabel('ML & Data'), 'ML & Data');
  });

  test('trackShortLabel uses text before ampersand when name is long', () {
    expect(trackShortLabel('Cybersecurity & Trust'), 'Cybersecurity');
    expect(trackShortLabel('Sustainability & ESG'), 'Sustainability');
  });

  test('trackShortLabel falls back to first word for long single phrases', () {
    expect(trackShortLabel('Developer Experience'), 'Developer');
    expect(trackShortLabel('Client Delivery'), 'Client');
  });

  test('trackShortLabel truncates very long first words', () {
    final label = trackShortLabel('Supercalifragilisticexpialidocious Track');
    expect(label.length, lessThanOrEqualTo(14));
    expect(label.endsWith('…'), isTrue);
  });

  test('trackShortLabel handles empty input', () {
    expect(trackShortLabel(''), isEmpty);
    expect(trackShortLabel('   '), isEmpty);
  });
}
