import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/domain/entities/session.dart';
import 'package:flo_compass/domain/entities/venue.dart';
import 'package:flo_compass/shared/utils/page_meta_builder.dart';

void main() {
  const origin = 'https://flo.example.com';
  const sampleSession = Session(
    id: 's-001',
    title: "Chairman's Ignite: Where Innovation Meets Grit",
    abstract:
        'Teams often lose weeks debating tools instead of shipping value. '
        'In this Keynote, Vikram Ashar walks through the exact trade-offs '
        'to evaluate before committing architecture decisions.',
    day: 'Day 1',
    startTime: '09:00',
    endTime: '10:00',
    venueId: 'ven-G01',
    trackId: 'trk-06',
    speakerIds: ['spk-001'],
    tags: ['ceo_vision'],
    format: 'Keynote',
    level: 'All levels',
    featured: true,
    capacity: 500,
    building: 'Nagarro Gurgaon Office',
  );
  const sampleVenue = Venue(
    id: 'ven-G01',
    name: 'Ground Auditorium',
    floor: 'Ground',
    zone: 'Main',
    wing: 'central',
    capacity: 500,
    building: 'Nagarro Gurgaon Office',
  );

  group('resolvePageMetaOrigin', () {
    test('returns origin for http and https', () {
      expect(
        resolvePageMetaOrigin(Uri.parse('https://flo.example.com/path')),
        'https://flo.example.com',
      );
    });

    test('returns empty string for file scheme in VM tests', () {
      expect(resolvePageMetaOrigin(Uri.parse('file:///tmp/test')), '');
    });
  });

  group('defaults', () {
    test('uses homepage copy and absolute urls', () {
      final meta = defaults(origin: origin);

      expect(meta.title, contains('Flo Compass'));
      expect(meta.ogTitle, meta.title);
      expect(meta.description, isNotEmpty);
      expect(meta.ogUrl, 'https://flo.example.com/');
      expect(meta.ogImage, 'https://flo.example.com/icons/Icon-512.png');
      expect(meta.ogType, 'website');
    });
  });

  group('forSession', () {
    test('formats title and article type', () {
      final meta = forSession(
        session: sampleSession,
        origin: origin,
        venue: sampleVenue,
      );

      expect(
        meta.title,
        "Chairman's Ignite: Where Innovation Meets Grit · Flo 2026",
      );
      expect(meta.ogTitle, meta.title);
      expect(meta.ogUrl, 'https://flo.example.com/session/s-001');
      expect(meta.ogType, 'article');
      expect(meta.description, contains('Teams often lose weeks'));
    });

    test('falls back to schedule and venue when abstract is empty', () {
      final session = Session(
        id: 's-empty',
        title: 'Empty abstract session',
        abstract: '   ',
        day: 'Day 2',
        startTime: '14:00',
        endTime: '15:00',
        venueId: 'ven-G01',
        trackId: 'trk-01',
        speakerIds: const [],
        tags: const [],
        format: 'Talk',
        level: 'Intermediate',
        featured: false,
        capacity: 80,
        building: 'Nagarro Gurgaon Office',
      );

      final meta = forSession(
        session: session,
        origin: origin,
        venue: sampleVenue,
      );

      expect(meta.description, 'Day 2 14:00 · Ground Auditorium');
    });
  });

  group('truncateMetaDescription', () {
    test('returns short text unchanged', () {
      expect(truncateMetaDescription('Short summary.'), 'Short summary.');
    });

    test('collapses whitespace before truncating', () {
      expect(truncateMetaDescription('One   two\nthree'), 'One two three');
    });

    test('truncates at word boundary with ellipsis', () {
      final long = List.filled(30, 'word').join(' ');
      final result = truncateMetaDescription(long, max: 40);

      expect(result.length, lessThanOrEqualTo(41));
      expect(result, endsWith('…'));
      expect(result, isNot(contains('wordword')));
    });
  });
}
