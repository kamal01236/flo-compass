import 'dart:convert';
import 'dart:io';

const int kSeed = 20260709;
const String kEventName = 'Flo 2026';
const String kBuilding = 'Nagarro Gurgaon Office';
const List<String> kDayIds = ['Day 1', 'Day 2', 'Day 3'];
const List<String> kSlots = [
  '09:00',
  '10:00',
  '11:00',
  '12:00',
  '13:00',
  '14:00',
  '15:00',
  '16:00',
];
const Map<String, String> kSlotEnd = {
  '09:00': '10:00',
  '10:00': '11:00',
  '11:00': '12:00',
  '12:00': '13:00',
  '13:00': '14:00',
  '14:00': '15:00',
  '15:00': '16:00',
  '16:00': '17:00',
};

class Lcg {
  Lcg(int seed) : _state = seed & 0x7FFFFFFF;
  int _state;

  int nextInt(int max) {
    _state = (_state * 1103515245 + 12345) & 0x7FFFFFFF;
    return _state % max;
  }
}

List<Map<String, dynamic>> buildVenues() {
  final venues = <Map<String, dynamic>>[
    {
      'id': 'ven-G01',
      'name': 'Reception and Welcome Hall',
      'building': kBuilding,
      'floor': 'G',
      'zone': 'Reception',
      'wing': 'central',
      'mapZone': 'reception',
      'capacity': 500,
      'description':
          'Ground-floor welcome hall for opening, closing, and all-hands sessions.',
    },
    {
      'id': 'ven-C601',
      'name': 'Community Cafeteria',
      'building': kBuilding,
      'floor': '6',
      'zone': 'Cafeteria',
      'wing': 'N',
      'mapZone': 'north',
      'capacity': 200,
      'description':
          'North wing social hub with curated 12:00 lightning talks and networking.',
    },
  ];

  for (var i = 1; i <= 4; i++) {
    venues.add({
      'id': 'ven-T60$i',
      'name': 'Training Room $i',
      'building': kBuilding,
      'floor': '6',
      'zone': 'Training',
      'wing': 'S',
      'mapZone': 'south',
      'capacity': 60,
      'description':
          'South wing training room for live labs, workshops, and masterclasses.',
    });
  }

  for (var floor = 7; floor <= 13; floor++) {
    for (final wing in ['N', 'S']) {
      for (var i = 1; i <= 6; i++) {
        venues.add({
          'id': 'ven-$floor$wing$i',
          'name': 'Floor $floor ${wing == 'N' ? 'North' : 'South'} Pod $i',
          'building': kBuilding,
          'floor': '$floor',
          'zone': 'Sitting Area',
          'wing': wing,
          'mapZone': wing == 'N' ? 'north' : 'south',
          'capacity': 20 + (i % 3) * 5,
          'description':
              'Small-group learning pod for practical sessions and peer discussions.',
        });
      }
    }
  }
  return venues;
}

List<Map<String, dynamic>> buildTracks() {
  const trackColors = [
    '#10B981',
    '#06B6D4',
    '#6366F1',
    '#F59E0B',
    '#EC4899',
    '#22C55E',
    '#EF4444',
    '#14B8A6',
    '#8B5CF6',
    '#84CC16',
  ];
  return [
    {
      'id': 'trk-01',
      'name': 'AI & GenAI',
      'description': 'Agents, copilots, and enterprise AI operating models.',
      'tags': ['genai', 'llm_agents', 'responsible_ai', 'innovation'],
      'color': trackColors[0],
    },
    {
      'id': 'trk-02',
      'name': 'ML & Data',
      'description': 'MLOps, data contracts, and analytics modernization.',
      'tags': ['mlops', 'data_mesh', 'analytics', 'responsible_ai'],
      'color': trackColors[1],
    },
    {
      'id': 'trk-03',
      'name': 'Cloud & Platform',
      'description': 'Platform engineering, Kubernetes, and reliability.',
      'tags': ['cloud', 'kubernetes', 'platform_engineering', 'architecture'],
      'color': trackColors[2],
    },
    {
      'id': 'trk-04',
      'name': 'Innovation & R&D',
      'description': 'Labs, prototypes, and emerging technologies in delivery.',
      'tags': ['innovation', 'emerging_tech', 'hackathon'],
      'color': trackColors[3],
    },
    {
      'id': 'trk-05',
      'name': 'Leadership & Culture',
      'description': 'Leading high-impact teams in modern enterprises.',
      'tags': ['leadership', 'culture', 'strategy'],
      'color': trackColors[4],
    },
    {
      'id': 'trk-06',
      'name': 'CEO Vision & Strategy',
      'description': 'Board-level strategy and long-term value creation.',
      'tags': ['ceo_vision', 'strategy', 'leadership'],
      'color': trackColors[5],
    },
    {
      'id': 'trk-07',
      'name': 'Client Delivery',
      'description': 'Consulting execution excellence across industries.',
      'tags': ['client_delivery', 'strategy', 'transformation'],
      'color': trackColors[6],
    },
    {
      'id': 'trk-08',
      'name': 'Developer Experience',
      'description': 'Cursor workflows, APIs, and engineering productivity.',
      'tags': ['devex', 'cursor', 'apis', 'platform_engineering'],
      'color': trackColors[7],
    },
    {
      'id': 'trk-09',
      'name': 'Cybersecurity & Trust',
      'description': 'Secure AI and practical threat modeling for teams.',
      'tags': ['cybersecurity', 'responsible_ai', 'compliance'],
      'color': trackColors[8],
    },
    {
      'id': 'trk-10',
      'name': 'Sustainability & ESG',
      'description': 'Green engineering and sustainability playbooks.',
      'tags': ['sustainability', 'innovation', 'leadership'],
      'color': trackColors[9],
    },
  ];
}

List<Map<String, dynamic>> buildSpeakers(Lcg rng) {
  final curated = <List<dynamic>>[
    [
      'spk-001',
      'Vikram Ashar',
      'Chairman',
      ['ceo_vision', 'strategy', 'leadership'],
    ],
    [
      'spk-002',
      'Elena Novak',
      'Chief Executive Officer (CEO)',
      ['ceo_vision', 'strategy', 'genai'],
    ],
    [
      'spk-003',
      'Dr. Arjun Mehta',
      'Chief Technology Officer (CTO)',
      ['architecture', 'genai', 'emerging_tech'],
    ],
    [
      'spk-004',
      'Sarah Lindstrom',
      'Chief Operating Officer (COO)',
      ['strategy', 'client_delivery'],
    ],
    [
      'spk-005',
      'Anil Kapoor',
      'Chief Financial Officer (CFO)',
      ['strategy', 'financial_services'],
    ],
    [
      'spk-006',
      'Priya Sharma',
      'Chief People Officer (CPO)',
      ['culture', 'leadership'],
    ],
    [
      'spk-007',
      'Marcus Chen',
      'Chief Delivery Officer (CDO)',
      ['client_delivery', 'strategy'],
    ],
    [
      'spk-008',
      'Dr. Fiona Okafor',
      'Global Head of AI Practice',
      ['genai', 'responsible_ai', 'llm_agents'],
    ],
    [
      'spk-009',
      'Rajesh Iyer',
      'Chief Architect',
      ['architecture', 'cloud', 'platform_engineering'],
    ],
    [
      'spk-010',
      'James Whitfield',
      'VP, Cloud Engineering',
      ['cloud', 'kubernetes', 'platform_engineering'],
    ],
    [
      'spk-011',
      'Ananya Desai',
      'Unit Head — Financial Services',
      ['financial_services', 'client_delivery'],
    ],
    [
      'spk-012',
      'Michael Torres',
      'Unit Head — Healthcare & Life Sciences',
      ['healthcare', 'client_delivery'],
    ],
    [
      'spk-013',
      'Lisa Bergmann',
      'Practice Head — Data & Analytics',
      ['mlops', 'data_mesh'],
    ],
    [
      'spk-014',
      'Kenji Yamamoto',
      'Distinguished Engineer',
      ['architecture', 'devex', 'emerging_tech'],
    ],
    [
      'spk-015',
      'Sofia Petrov',
      'Principal Architect — Integration',
      ['architecture', 'apis', 'cloud'],
    ],
    [
      'spk-016',
      'David Okonkwo',
      'Head of Cybersecurity',
      ['cybersecurity', 'responsible_ai'],
    ],
    [
      'spk-017',
      'Mei Lin',
      'Head of Sustainability Practice',
      ['sustainability', 'innovation'],
    ],
    [
      'spk-018',
      'Thomas Berger',
      'VP, Client Partner — Automotive',
      ['automotive', 'client_delivery'],
    ],
    [
      'spk-019',
      'Rachel Kim',
      'Senior Director, DevEx',
      ['devex', 'cursor', 'apis'],
    ],
    [
      'spk-020',
      'Omar Hassan',
      'Lead Consultant, GenAI',
      ['genai', 'llm_agents', 'client_delivery'],
    ],
  ];

  final speakers = curated
      .map(
        (row) => {
          'id': row[0] as String,
          'name': row[1] as String,
          'title': row[2] as String,
          'bio':
              '${row[1]} helps teams move from idea to delivery with practical playbooks, coaching, and measurable outcomes across enterprise programs.',
          'expertiseTags': row[3],
          'photoAsset': 'assets/images/speakers/${row[0]}.png',
        },
      )
      .toList();

  const firstNames = [
    'Aarav',
    'Ira',
    'Nisha',
    'Rohan',
    'Kavya',
    'Meera',
    'Aniket',
    'Tara',
    'Dev',
    'Leena',
  ];
  const lastNames = [
    'Sharma',
    'Kumar',
    'Patel',
    'Rao',
    'Mehta',
    'Singh',
    'Nair',
    'Bose',
    'Desai',
    'Iyer',
  ];
  const titles = [
    'Senior Consultant',
    'Engineering Manager',
    'Solution Architect',
    'Practice Lead',
    'Lead Data Scientist',
    'Principal Engineer',
  ];
  final expertise = buildTracks().map((e) => e['tags'] as List).toList();

  for (var i = 21; i <= 90; i++) {
    final id = 'spk-${i.toString().padLeft(3, '0')}';
    final first = firstNames[(i - 21) % firstNames.length];
    final last = lastNames[rng.nextInt(lastNames.length)];
    final tagPool = expertise[rng.nextInt(expertise.length)];
    speakers.add({
      'id': id,
      'name': '$first $last',
      'title': titles[rng.nextInt(titles.length)],
      'bio':
          '$first $last runs hands-on sessions focused on reusable playbooks, peer learning, and concrete delivery outcomes teams can apply the next Monday.',
      'expertiseTags': [tagPool.first, tagPool.last],
    });
  }

  return speakers;
}

List<Map<String, dynamic>> _featuredSessions() {
  return [
    {
      'title': "Chairman's Ignite: Where Innovation Meets Grit",
      'day': 'Day 1',
      'startTime': '09:00',
      'venueId': 'ven-G01',
      'trackId': 'trk-06',
      'speakerIds': ['spk-001'],
      'format': 'Keynote',
      'level': 'beginner',
      'tags': ['ceo_vision', 'strategy', 'leadership'],
    },
    {
      'title': 'CEO Fireside: Nagarro Unfiltered — The Next Five Years',
      'day': 'Day 1',
      'startTime': '10:00',
      'venueId': 'ven-G01',
      'trackId': 'trk-06',
      'speakerIds': ['spk-002'],
      'format': 'Fireside Chat',
      'level': 'beginner',
      'tags': ['ceo_vision', 'strategy', 'genai'],
    },
    {
      'title': 'CTO Masterclass: Engineering at the Edge of Now',
      'day': 'Day 1',
      'startTime': '11:00',
      'venueId': 'ven-T601',
      'trackId': 'trk-03',
      'speakerIds': ['spk-003'],
      'format': 'Masterclass',
      'level': 'intermediate',
      'tags': ['architecture', 'genai', 'emerging_tech'],
    },
    {
      'title': 'Live Lab: Ship an Agentic Cursor Workflow in 60 Minutes',
      'day': 'Day 1',
      'startTime': '14:00',
      'venueId': 'ven-T602',
      'trackId': 'trk-08',
      'speakerIds': ['spk-019'],
      'format': 'Live Lab',
      'level': 'intermediate',
      'tags': ['cursor', 'devex', 'genai'],
    },
    {
      'title':
          'Roundtable: Cloud-Native at Enterprise Scale — Bring Your Migration Stories',
      'day': 'Day 1',
      'startTime': '15:00',
      'venueId': 'ven-7N1',
      'trackId': 'trk-03',
      'speakerIds': ['spk-009', 'spk-015'],
      'format': 'Roundtable',
      'level': 'advanced',
      'tags': ['cloud', 'architecture', 'platform_engineering'],
    },
    {
      'title':
          'Deep Dive: Responsible AI Under the Hood — Guardrails You Can Ship',
      'day': 'Day 2',
      'startTime': '10:00',
      'venueId': 'ven-T603',
      'trackId': 'trk-01',
      'speakerIds': ['spk-008'],
      'format': 'Deep Dive',
      'level': 'advanced',
      'tags': ['responsible_ai', 'genai', 'llm_agents'],
    },
    {
      'title': 'Playbook: Winning Delivery in Regulated Industries',
      'day': 'Day 2',
      'startTime': '14:00',
      'venueId': 'ven-8S3',
      'trackId': 'trk-07',
      'speakerIds': ['spk-011', 'spk-012'],
      'format': 'Playbook',
      'level': 'intermediate',
      'tags': ['client_delivery', 'strategy', 'compliance'],
    },
    {
      'title': 'Hands-on: Kubernetes Chaos Drills for SRE Teams',
      'day': 'Day 2',
      'startTime': '15:00',
      'venueId': 'ven-T604',
      'trackId': 'trk-03',
      'speakerIds': ['spk-010'],
      'format': 'Hands-on',
      'level': 'intermediate',
      'tags': ['kubernetes', 'cloud', 'platform_engineering'],
    },
    {
      'title': 'AMA: Cybersecurity Chiefs on AI Threat Models',
      'day': 'Day 3',
      'startTime': '11:00',
      'venueId': 'ven-9N4',
      'trackId': 'trk-09',
      'speakerIds': ['spk-016'],
      'format': 'AMA',
      'level': 'advanced',
      'tags': ['cybersecurity', 'responsible_ai', 'compliance'],
    },
    {
      'title': 'Innovation Showcase: 12 Bets from Nagarro Labs (Vote Live)',
      'day': 'Day 3',
      'startTime': '15:00',
      'venueId': 'ven-G01',
      'trackId': 'trk-04',
      'speakerIds': ['spk-007', 'spk-014'],
      'format': 'Showcase',
      'level': 'intermediate',
      'tags': ['innovation', 'hackathon', 'emerging_tech'],
    },
  ];
}

Map<String, List<String>> _slotVenuePools(List<Map<String, dynamic>> venues) {
  final all = venues.map((e) => e['id'] as String).toList();
  final pods = all
      .where((id) => RegExp(r'^ven-(7|8|9|10|11|12|13)[NS][1-6]$').hasMatch(id))
      .toList();
  final training = all.where((id) => id.startsWith('ven-T60')).toList();
  final core = ['ven-G01', ...training, ...pods];
  return {
    '09:00': ['ven-G01', ...training],
    '10:00': core,
    '11:00': core,
    '12:00': ['ven-C601'],
    '13:00': core,
    '14:00': core,
    '15:00': core,
    '16:00': ['ven-G01', ...pods.take(30)],
  };
}

const Map<String, int> _targetSessionsPerSlot = {
  '09:00': 5,
  '10:00': 36,
  '11:00': 36,
  '12:00': 1,
  '13:00': 50,
  '14:00': 50,
  '15:00': 30,
  '16:00': 6,
};

Map<String, List<String>> _titleFormats = {
  'Live Lab': ['Live Lab: %topic%'],
  'Deep Dive': ['Deep Dive: %topic% Under the Hood'],
  'Playbook': ['Playbook: %topic% from Battle-Tested Teams'],
  'Roundtable': ['Roundtable: %topic% — Bring Your Questions'],
  'Hands-on': ['Hands-on: Build %artifact% in 60 Minutes'],
  'Fireside Chat': ['Fireside: %topic% with the %role%'],
  'Masterclass': ['Masterclass: %topic% from Zero to Ship'],
  'Unlocked': ['Unlocked: %topic% Without the Hype'],
  'Story': ['The Real Story: %topic% in Production'],
  'AMA': ['AMA: %speaker% on %topic%'],
  'Ignite': ['Ignite: %topic% in 20 Slides / 20 Seconds'],
  'Showcase': ['Playbook: %topic% from Battle-Tested Teams'],
  'Keynote': ['Masterclass: %topic% from Zero to Ship'],
};

List<String> _formatsForSlot(String slot) {
  switch (slot) {
    case '09:00':
      return ['Keynote', 'Masterclass', 'Fireside Chat'];
    case '12:00':
      return ['Ignite'];
    case '16:00':
      return ['Roundtable', 'Fireside Chat', 'AMA'];
    default:
      return [
        'Live Lab',
        'Deep Dive',
        'Playbook',
        'Hands-on',
        'Roundtable',
        'AMA',
      ];
  }
}

const _topics = [
  'Responsible AI Guardrails',
  'Agentic Delivery Workflows',
  'Cloud Platform Reliability',
  'Developer Experience Playbooks',
  'Data Product Contracts',
  'Security by Design',
  'Leadership in Hybrid Teams',
  'Kubernetes Day-2 Ops',
  'Innovation at Enterprise Scale',
  'Consulting Delivery Precision',
];
const _artifacts = [
  'a team-ready checklist',
  'a reusable architecture blueprint',
  'an evaluation harness',
  'a production runbook',
  'a launch scorecard',
];
const _roles = ['CTO', 'Practice Head', 'Principal Engineer', 'Client Partner'];

String _renderTitle({
  required Lcg rng,
  required String format,
  required String speaker,
}) {
  final template = _titleFormats[format]!.first;
  return template
      .replaceAll('%topic%', _topics[rng.nextInt(_topics.length)])
      .replaceAll('%artifact%', _artifacts[rng.nextInt(_artifacts.length)])
      .replaceAll('%speaker%', speaker.split(' ').first)
      .replaceAll('%role%', _roles[rng.nextInt(_roles.length)]);
}

String _buildAbstract({
  required Lcg rng,
  required String format,
  required String speaker,
}) {
  final painPoints = [
    'Teams often lose weeks debating tools instead of shipping value',
    'Many programs stall when prototypes never become repeatable delivery patterns',
    'Leaders struggle to align architecture decisions with measurable outcomes',
    'Cross-functional squads need concrete playbooks, not generic slide decks',
  ];
  final learns = [
    'a step-by-step implementation flow used by high-performing squads',
    'the exact trade-offs to evaluate before committing architecture decisions',
    'how to move from pilot to production without breaking trust or velocity',
    'a practical way to align engineering quality with delivery speed',
  ];
  return '${painPoints[rng.nextInt(painPoints.length)]}. '
      'In this $format, $speaker walks through ${learns[rng.nextInt(learns.length)]}. '
      'You\'ll leave with:\n'
      '- a reusable checklist you can adapt to your team context\n'
      '- a mental model to choose the right level of investment\n'
      '- one Monday-ready next step for your roadmap\n'
      'Bring a real use case from your team so you can adapt the playbook on the spot.';
}

List<Map<String, dynamic>> buildSessions({
  required Lcg rng,
  required List<Map<String, dynamic>> venues,
  required List<Map<String, dynamic>> speakers,
  required List<Map<String, dynamic>> tracks,
}) {
  final sessions = <Map<String, dynamic>>[];
  final featured = _featuredSessions();
  var counter = 1;
  final occupied = <String>{};
  final speakerBookings = <String, Set<String>>{};
  final venueMap = {for (final v in venues) v['id'] as String: v};
  final pools = _slotVenuePools(venues);

  void addSession(Map<String, dynamic> seed, {required bool featuredFlag}) {
    final id = 's-${counter.toString().padLeft(3, '0')}';
    counter++;
    final venue = venueMap[seed['venueId']]!;
    final roomCap = venue['capacity'] as int;
    final slot = seed['startTime'] as String;
    final day = seed['day'] as String;
    final bookingToken = '$day|$slot';
    final speakersForSession = List<String>.from(seed['speakerIds'] as List);
    for (final spk in speakersForSession) {
      speakerBookings.putIfAbsent(spk, () => <String>{}).add(bookingToken);
    }
    occupied.add('$day|$slot|${seed['venueId']}');
    sessions.add({
      'id': id,
      'title': seed['title'],
      'abstract': seed['abstract'],
      'day': day,
      'startTime': slot,
      'endTime': kSlotEnd[slot],
      'venueId': seed['venueId'],
      'trackId': seed['trackId'],
      'speakerIds': speakersForSession,
      'tags': seed['tags'],
      'format': seed['format'],
      'level': seed['level'],
      'featured': featuredFlag,
      'capacity': roomCap,
      'building': kBuilding,
      'attendeeInterestCount': 30 + rng.nextInt(420),
      'occupancyPercent': 35 + rng.nextInt(60),
    });
  }

  for (final seed in featured) {
    final speakerName =
        speakers.firstWhere(
              (s) => s['id'] == (seed['speakerIds'] as List).first,
            )['name']
            as String;
    addSession({
      ...seed,
      'abstract': _buildAbstract(
        rng: rng,
        format: seed['format'] as String,
        speaker: speakerName,
      ),
    }, featuredFlag: true);
  }

  for (final day in kDayIds) {
    for (final slot in kSlots) {
      final target = _targetSessionsPerSlot[slot]!;
      final pool = List<String>.from(pools[slot]!);
      final usedInSlot = <String>{};
      var created = 0;
      while (created < target && usedInSlot.length < pool.length) {
        final venueId = pool[rng.nextInt(pool.length)];
        if (usedInSlot.contains(venueId)) continue;
        usedInSlot.add(venueId);
        if (occupied.contains('$day|$slot|$venueId')) continue;

        final track = tracks[rng.nextInt(tracks.length)];
        final trackId = track['id'] as String;
        final trackTags = List<String>.from(track['tags'] as List);
        final format = _formatsForSlot(
          slot,
        )[rng.nextInt(_formatsForSlot(slot).length)];
        final level = ['beginner', 'intermediate', 'advanced'][rng.nextInt(3)];

        final speakerIds = <String>[];
        final speakerCount = slot == '09:00'
            ? 1
            : (rng.nextInt(100) < 82 ? 1 : 2);
        for (var i = 0; i < speakerCount; i++) {
          var attempts = 0;
          while (attempts < 120) {
            final pick = speakers[rng.nextInt(speakers.length)]['id'] as String;
            final booked =
                speakerBookings[pick]?.contains('$day|$slot') ?? false;
            if (!booked && !speakerIds.contains(pick)) {
              speakerIds.add(pick);
              break;
            }
            attempts++;
          }
          if (speakerIds.length <= i) {
            speakerIds.add('spk-0${(i + 1).toString().padLeft(2, '0')}');
          }
        }

        final primarySpeaker =
            speakers.firstWhere((s) => s['id'] == speakerIds.first)['name']
                as String;
        addSession({
          'title': _renderTitle(
            rng: rng,
            format: format,
            speaker: primarySpeaker,
          ),
          'abstract': _buildAbstract(
            rng: rng,
            format: format,
            speaker: primarySpeaker,
          ),
          'day': day,
          'startTime': slot,
          'venueId': venueId,
          'trackId': trackId,
          'speakerIds': speakerIds,
          'tags': <String>{
            ...trackTags.take(2),
            ...trackTags.skip(1).take(2),
          }.toList(),
          'format': format,
          'level': level,
        }, featuredFlag: false);
        created++;
      }
    }
  }
  return sessions;
}

Map<String, dynamic> buildMeta() {
  return {
    'eventName': kEventName,
    'venue': kBuilding,
    'building': kBuilding,
    'timezone': 'IST (UTC+05:30) — venue local time',
    'timezoneNote':
        'All session times are Nagarro Gurgaon Office local time (IST, UTC+05:30).',
    'slots': kSlots,
    'days': [
      {
        'id': 'Day 1',
        'name': 'Day 1',
        'date': '2026-11-04',
        'description':
            'Opening day at Nagarro Gurgaon Office with Chairman and CEO key sessions.',
      },
      {
        'id': 'Day 2',
        'name': 'Day 2',
        'date': '2026-11-05',
        'description':
            'Hands-on labs, architecture deep dives, and delivery stories.',
      },
      {
        'id': 'Day 3',
        'name': 'Day 3',
        'date': '2026-11-06',
        'description': 'Community day with AMAs and innovation showcases.',
      },
    ],
  };
}

Future<void> _writeJson(String path, Object value) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(value)}\n',
  );
  stdout.writeln('  wrote $path');
}

Future<void> main() async {
  final rng = Lcg(kSeed);
  final venues = buildVenues();
  final tracks = buildTracks();
  final speakers = buildSpeakers(rng);
  final sessions = buildSessions(
    rng: rng,
    venues: venues,
    speakers: speakers,
    tracks: tracks,
  );
  final meta = buildMeta();

  await _writeJson('assets/data/flo2026_meta.json', meta);
  await _writeJson('assets/data/flo2026_venues.json', venues);
  await _writeJson('assets/data/flo2026_tracks.json', tracks);
  await _writeJson('assets/data/flo2026_speakers.json', speakers);
  await _writeJson('assets/data/flo2026_sessions.json', sessions);

  final featuredCount = sessions.where((s) => s['featured'] == true).length;
  stdout.writeln('Done.');
  stdout.writeln('  venues:   ${venues.length}');
  stdout.writeln('  tracks:   ${tracks.length}');
  stdout.writeln('  speakers: ${speakers.length}');
  stdout.writeln('  sessions: ${sessions.length} (featured: $featuredCount)');
}
