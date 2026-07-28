import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/services/navigation_search_service.dart';
import 'package:flo_compass/domain/inputs/navigation_search_context.dart';

void main() {
  late NavigationSearchContext catalog;

  setUp(() {
    catalog = NavigationSearchContext(
      sessions: [
        const Session(
          id: 's-001',
          title: 'CEO Keynote on GenAI',
          abstract: 'a',
          day: 'Day 1',
          startTime: '10:00',
          endTime: '11:00',
          venueId: 'ven-G01',
          trackId: 'trk-01',
          speakerIds: ['spk-001'],
          tags: ['genai'],
          format: 'Keynote',
          level: 'beginner',
          featured: true,
          capacity: 100,
          building: 'Nagarro Gurgaon Office',
        ),
      ],
      speakers: [
        const Speaker(
          id: 'spk-001',
          name: 'Vikram Ashar',
          title: 'Chairman',
          tier: 1,
          bio: 'bio',
          photoAsset: null,
        ),
      ],
      venues: [
        const Venue(
          id: 'ven-G01',
          name: 'Ground Auditorium',
          floor: 'G',
          zone: 'auditorium',
          wing: 'N',
          capacity: 200,
          building: 'Nagarro Gurgaon Office',
        ),
      ],
      tracks: [
        const Track(
          id: 'trk-01',
          name: 'AI & GenAI',
          tags: ['genai'],
          color: '#10B981',
        ),
      ],
    );
  });

  test('empty query returns actions only', () {
    final groups = NavigationSearchService.search(
      '',
      catalog: catalog,
      onConflicts: (_, _) {},
    );
    expect(groups.sessions, isEmpty);
    expect(groups.actions.length, greaterThan(3));
  });

  test('magic keyword day2 navigates to Day 2 discover', () {
    final groups = NavigationSearchService.search(
      'day2',
      catalog: catalog,
      onConflicts: (_, _) {},
    );
    expect(groups.actions, hasLength(1));
    expect(groups.actions.first.route, '/discover?day=Day%202');
  });

  test('speaker name match ranks in speakers group', () {
    final groups = NavigationSearchService.search(
      'vikram',
      catalog: catalog,
      onConflicts: (_, _) {},
    );
    expect(groups.speakers, isNotEmpty);
    expect(groups.speakers.first.label, 'Vikram Ashar');
    expect(groups.speakers.first.route, '/speaker/spk-001');
  });

  test('session title contains query', () {
    final groups = NavigationSearchService.search(
      'keynote',
      catalog: catalog,
      onConflicts: (_, _) {},
    );
    expect(groups.sessions, isNotEmpty);
    expect(groups.sessions.first.label, contains('Keynote'));
  });
}
