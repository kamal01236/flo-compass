/// Short label for track passport rings (full name in [Tooltip]).
String trackShortLabel(String trackName) {
  final name = trackName.trim();
  if (name.isEmpty) return name;

  const amp = ' & ';
  final ampIdx = name.indexOf(amp);
  if (ampIdx > 0) {
    if (name.length <= 18) return name;
    return name.substring(0, ampIdx).trim();
  }

  final words = name.split(RegExp(r'\s+'));
  if (words.length > 1) {
    final first = words.first;
    if (first.length <= 13) return first;
    return '${first.substring(0, 13)}…';
  }

  if (name.length <= 14) return name;
  return '${name.substring(0, 13)}…';
}
