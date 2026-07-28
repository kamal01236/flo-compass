import 'package:flutter/foundation.dart';

enum DiscoverSortMode {
  relevance,
  soonest,
  featuredFirst,
  speakerTier,
  happeningNow,
}

extension DiscoverSortModeX on DiscoverSortMode {
  String get label => switch (this) {
    DiscoverSortMode.relevance => 'Relevance',
    DiscoverSortMode.soonest => 'Soonest',
    DiscoverSortMode.featuredFirst => 'Featured first',
    DiscoverSortMode.speakerTier => 'Speaker tier',
    DiscoverSortMode.happeningNow => 'Happening now',
  };
}

/// Sort modes exposed in the Discover AppBar menu.
const discoverAppBarSortModes = <DiscoverSortMode>[
  DiscoverSortMode.relevance,
  DiscoverSortMode.soonest,
  DiscoverSortMode.featuredFirst,
  DiscoverSortMode.speakerTier,
];

@immutable
class DiscoverFilters {
  const DiscoverFilters({
    this.day,
    this.floor,
    this.wing,
    this.track,
    this.query,
    this.sort = DiscoverSortMode.relevance,
  });

  final String? day;
  final String? floor;
  final String? wing;
  final String? track;
  final String? query;
  final DiscoverSortMode sort;

  static const _validDays = {'Day 1', 'Day 2', 'Day 3'};
  static const _validFloors = {'G', '6', '7', '8', '9', '10', '11', '12', '13'};
  static const _validWings = {'N', 'S'};

  factory DiscoverFilters.fromUri(Uri uri) {
    final params = uri.queryParameters;
    final day = _validDays.contains(params['day']) ? params['day'] : null;
    final floor = _validFloors.contains(params['floor'])
        ? params['floor']
        : null;
    final wing = _validWings.contains(params['wing']) ? params['wing'] : null;
    final track = params['track']?.trim();
    final query = params['q']?.trim();
    final sort = _sortFromParam(params['sort']);
    return DiscoverFilters(
      day: day,
      floor: floor,
      wing: wing,
      track: track?.isEmpty == true ? null : track,
      query: query?.isEmpty == true ? null : query,
      sort: sort,
    );
  }

  static DiscoverSortMode _sortFromParam(String? value) {
    return switch (value) {
      'soonest' => DiscoverSortMode.soonest,
      'featured' => DiscoverSortMode.featuredFirst,
      'speakerTier' => DiscoverSortMode.speakerTier,
      'happening' => DiscoverSortMode.happeningNow,
      _ => DiscoverSortMode.relevance,
    };
  }

  static String _sortToParam(DiscoverSortMode sort) {
    return switch (sort) {
      DiscoverSortMode.relevance => 'relevance',
      DiscoverSortMode.soonest => 'soonest',
      DiscoverSortMode.featuredFirst => 'featured',
      DiscoverSortMode.speakerTier => 'speakerTier',
      DiscoverSortMode.happeningNow => 'happening',
    };
  }

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    if (day != null) params['day'] = day!;
    if (floor != null) params['floor'] = floor!;
    if (wing != null) params['wing'] = wing!;
    if (track != null && track!.isNotEmpty) params['track'] = track!;
    if (query != null && query!.isNotEmpty) params['q'] = query!;
    if (sort != DiscoverSortMode.relevance) {
      params['sort'] = _sortToParam(sort);
    }
    return params;
  }

  Uri toUri() {
    return Uri(path: '/discover', queryParameters: toQueryParameters());
  }

  bool get isEmpty =>
      day == null &&
      floor == null &&
      wing == null &&
      track == null &&
      (query == null || query!.isEmpty) &&
      sort == DiscoverSortMode.relevance;

  DiscoverFilters copyWith({
    String? day,
    bool clearDay = false,
    String? floor,
    bool clearFloor = false,
    String? wing,
    bool clearWing = false,
    String? track,
    bool clearTrack = false,
    String? query,
    bool clearQuery = false,
    DiscoverSortMode? sort,
  }) {
    return DiscoverFilters(
      day: clearDay ? null : (day ?? this.day),
      floor: clearFloor ? null : (floor ?? this.floor),
      wing: clearWing ? null : (wing ?? this.wing),
      track: clearTrack ? null : (track ?? this.track),
      query: clearQuery ? null : (query ?? this.query),
      sort: sort ?? this.sort,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DiscoverFilters &&
        other.day == day &&
        other.floor == floor &&
        other.wing == wing &&
        other.track == track &&
        other.query == query &&
        other.sort == sort;
  }

  @override
  int get hashCode => Object.hash(day, floor, wing, track, query, sort);
}
