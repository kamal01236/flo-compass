import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/models/user_profile.dart';
import 'package:flo_compass/shared/utils/session_format_filter.dart';

Session _session(String id, String format) {
  return Session(
    id: id,
    title: 'Session $id',
    abstract: 'abstract',
    day: 'Day 1',
    startTime: '10:00',
    endTime: '11:00',
    venueId: 'ven-G01',
    trackId: 'trk-01',
    speakerIds: const ['spk-001'],
    tags: const ['genai'],
    format: format,
    level: 'beginner',
    featured: false,
    capacity: 50,
    building: 'Nagarro Gurgaon Office',
  );
}

ScoredSession _scored(Session session) {
  return ScoredSession(session: session, score: 1, matchReasons: const []);
}

void main() {
  group('sessionMatchesEnergyFilter', () {
    test('all filter matches every format', () {
      expect(
        sessionMatchesEnergyFilter(
          _session('s-1', 'Keynote'),
          EnergyFilter.all,
        ),
        isTrue,
      );
      expect(
        sessionMatchesEnergyFilter(
          _session('s-2', 'Live Lab'),
          EnergyFilter.all,
        ),
        isTrue,
      );
    });

    test('lightKeynotes includes keynote-style formats', () {
      for (final format in lightKeynoteFormats) {
        expect(
          sessionMatchesEnergyFilter(
            _session('s-light', format),
            EnergyFilter.lightKeynotes,
          ),
          isTrue,
          reason: format,
        );
      }
      expect(
        sessionMatchesEnergyFilter(
          _session('s-deep', 'Live Lab'),
          EnergyFilter.lightKeynotes,
        ),
        isFalse,
      );
    });

    test('deepWorkshops includes workshop-style formats', () {
      for (final format in deepWorkshopFormats) {
        expect(
          sessionMatchesEnergyFilter(
            _session('s-deep', format),
            EnergyFilter.deepWorkshops,
          ),
          isTrue,
          reason: format,
        );
      }
      expect(
        sessionMatchesEnergyFilter(
          _session('s-light', 'Keynote'),
          EnergyFilter.deepWorkshops,
        ),
        isFalse,
      );
    });
  });

  group('applyEnergyFilter', () {
    final ranked = [
      _scored(_session('s-1', 'Keynote')),
      _scored(_session('s-2', 'Fireside Chat')),
      _scored(_session('s-3', 'Live Lab')),
      _scored(_session('s-4', 'AMA')),
    ];

    test('returns all sessions when filter is all', () {
      expect(applyEnergyFilter(ranked, EnergyFilter.all), hasLength(4));
    });

    test('filters to keynote-style sessions', () {
      final filtered = applyEnergyFilter(ranked, EnergyFilter.lightKeynotes);
      expect(filtered, hasLength(2));
      expect(filtered.map((s) => s.session.id), ['s-1', 's-2']);
    });

    test('filters to workshop-style sessions', () {
      final filtered = applyEnergyFilter(ranked, EnergyFilter.deepWorkshops);
      expect(filtered, hasLength(2));
      expect(filtered.map((s) => s.session.id), ['s-3', 's-4']);
    });
  });

  group('energyFilterCountLabel', () {
    test('uses format-specific labels when energy filter active', () {
      expect(
        energyFilterCountLabel(16, EnergyFilter.lightKeynotes),
        '16 keynote-style sessions',
      );
      expect(
        energyFilterCountLabel(42, EnergyFilter.deepWorkshops),
        '42 workshop-style sessions',
      );
      expect(
        energyFilterCountLabel(100, EnergyFilter.all),
        '100 sessions · personalized for you',
      );
    });
  });
}
