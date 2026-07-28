import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/features/discover/discover_filters.dart';

void main() {
  test('fromUri ignores invalid params', () {
    final filters = DiscoverFilters.fromUri(
      Uri.parse('/discover?day=Invalid&floor=99&wing=X&sort=bad'),
    );
    expect(filters.day, isNull);
    expect(filters.floor, isNull);
    expect(filters.wing, isNull);
    expect(filters.sort, DiscoverSortMode.relevance);
  });

  test('toUri round-trip preserves all params', () {
    const original = DiscoverFilters(
      day: 'Day 1',
      floor: '7',
      wing: 'N',
      track: 'trk-01',
      query: 'genai',
      sort: DiscoverSortMode.speakerTier,
    );
    final uri = original.toUri();
    final parsed = DiscoverFilters.fromUri(uri);
    expect(parsed, original);
  });

  test('fromUri decodes day with space', () {
    final filters = DiscoverFilters.fromUri(
      Uri.parse('/discover?day=Day%201&floor=G'),
    );
    expect(filters.day, 'Day 1');
    expect(filters.floor, 'G');
  });
}
