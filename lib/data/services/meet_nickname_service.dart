import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

/// Suggest, validate, and check nickname collisions for Flo Meets.
class MeetNicknameService {
  MeetNicknameService({Random? random}) : _random = random ?? Random();

  final Random _random;
  List<String>? _pool;

  static const minLength = 3;
  static const maxLength = 20;
  static final _pattern = RegExp(r'^[A-Za-z][A-Za-z0-9 _-]{2,19}$');

  Future<List<String>> loadPool() async {
    if (_pool != null) return _pool!;
    final raw = await rootBundle.loadString(
      'assets/data/meet_nickname_pool.json',
    );
    final decoded = jsonDecode(raw) as List<dynamic>;
    _pool = decoded.map((e) => e as String).toList();
    return _pool!;
  }

  Future<String> suggest({Set<String> taken = const {}}) async {
    final pool = await loadPool();
    final available = pool.where((n) => !taken.contains(n)).toList();
    if (available.isEmpty) {
      return _fallbackNickname(taken);
    }
    return available[_random.nextInt(available.length)];
  }

  String validate(String nickname, {Set<String> taken = const {}}) {
    final trimmed = nickname.trim();
    if (trimmed.length < minLength || trimmed.length > maxLength) {
      return 'Nickname must be $minLength–$maxLength characters.';
    }
    if (!_pattern.hasMatch(trimmed)) {
      return 'Use letters, numbers, spaces, hyphens, or underscores.';
    }
    if (taken.contains(trimmed)) {
      return 'That nickname is already taken.';
    }
    return '';
  }

  bool isCollision(String nickname, Set<String> taken) {
    return taken.contains(nickname.trim());
  }

  String _fallbackNickname(Set<String> taken) {
    for (var i = 0; i < 100; i++) {
      final candidate = 'Flo${_random.nextInt(9000) + 1000}';
      if (!taken.contains(candidate)) return candidate;
    }
    return 'Flo${DateTime.now().millisecondsSinceEpoch % 100000}';
  }
}
