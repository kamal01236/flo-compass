import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/data/models/models.dart';
import 'package:flo_compass/data/services/recap_summary_builder.dart';
import 'package:flo_compass/providers/engagement_provider.dart';
import 'package:flo_compass/providers/event_provider.dart';
import 'package:flo_compass/providers/plan_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds summary with notes and worth-it sessions', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const session = Session(
      id: 's-001',
      title: 'CEO Keynote',
      abstract: '',
      day: 'Day 1',
      startTime: '10:00',
      endTime: '11:00',
      venueId: 'ven-1',
      trackId: 'trk-01',
      speakerIds: [],
      tags: ['genai'],
      format: 'Keynote',
      level: 'beginner',
      featured: true,
      capacity: 100,
      building: 'Nagarro Gurgaon Office',
    );

    final event = EventState();
    event.loading = false;
    event.sessions = [session];

    final plan = PlanState(prefs: prefs);
    await plan.init();
    await plan.toggle('s-001');

    final engagement = EngagementState();
    engagement.snapshot = EngagementSnapshot.empty.copyWith(
      pulseBySessionId: const {'s-001': 'worth_it'},
      notesBySessionId: const {
        's-001': 'Great opening — remember the AI roadmap quote.',
      },
    );

    final summary = RecapSummaryBuilder().build(
      engagement: engagement,
      event: event,
      plan: plan,
    );

    expect(summary.plannedSessionTitles, contains('CEO Keynote'));
    expect(summary.worthItSessions, contains('CEO Keynote'));
    expect(summary.noteExcerpts, hasLength(1));
    expect(summary.noteExcerpts.first.excerpt, contains('AI roadmap'));

    final text = summary.toText();
    expect(text, contains('CEO Keynote'));
    expect(text, contains('Worth it'));
  });
}
