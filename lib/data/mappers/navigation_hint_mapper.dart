import '../../domain/entities/navigation_hint.dart';

NavigationHint navigationHintFromJson(Map<String, dynamic> json) {
  return NavigationHint(
    id: json['id'] as String,
    fromFloor: json['fromFloor'] as String,
    toFloor: json['toFloor'] as String,
    fromWing: json['fromWing'] as String,
    toWing: json['toWing'] as String,
    text: json['text'] as String,
  );
}

List<NavigationHint> navigationHintsFromBundle(Map<String, dynamic> json) {
  final hints = json['hints'] as List<dynamic>? ?? const [];
  return hints
      .map((e) => navigationHintFromJson(e as Map<String, dynamic>))
      .toList();
}
