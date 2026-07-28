import 'package:flutter_test/flutter_test.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/services/plain_english_service.dart';

void main() {
  const service = PlainEnglishService();

  test('summarize uses format, tag, level, and duration', () {
    const session = Session(
      id: 's-1',
      title: 'GenAI Lab',
      abstract: 'abstract',
      day: 'Day 1',
      startTime: '10:00',
      endTime: '11:00',
      venueId: 'ven-7N1',
      trackId: 'trk-01',
      speakerIds: ['spk-001'],
      tags: ['genai'],
      format: 'Hands-on lab',
      level: 'intermediate',
      featured: false,
      capacity: 40,
      building: 'Nagarro Gurgaon Office',
    );

    expect(
      service.summarize(session),
      'Hands-on lab about GenAI. Intermediate. 60 minutes.',
    );
  });

  test('summarize falls back when tags are empty', () {
    const session = Session(
      id: 's-2',
      title: 'Talk',
      abstract: 'abstract',
      day: 'Day 1',
      startTime: '14:00',
      endTime: '15:00',
      venueId: 'ven-7N1',
      trackId: 'trk-01',
      speakerIds: [],
      tags: [],
      format: 'Keynote',
      level: 'beginner',
      featured: true,
      capacity: 200,
      building: 'Nagarro Gurgaon Office',
    );

    expect(
      service.summarize(session),
      'Keynote talk about general topics. Beginner. 60 minutes.',
    );
  });
}
