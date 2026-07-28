import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../core/auth/platform_role.dart';
import '../../core/config/app_config.dart';
import '../../core/config/build_info.dart';
import '../../core/consent/consent_service.dart';
import '../../data/local/local_user_store.dart';
import 'analytics_config.dart';
import 'analytics_event.dart';
import 'analytics_property_allowlist.dart';
import 'sinks/console_sink.dart';
import 'sinks/http_batch_sink.dart';
import 'sinks/local_ring_buffer_sink.dart';
import 'sinks/noop_sink.dart';

typedef ConsentChecker = Future<bool> Function();

/// Unified analytics facade — consent-aware, PII-filtered, multi-sink fan-out.
class AnalyticsService {
  AnalyticsService({
    required AnalyticsConfig config,
    ConsentService? consentService,
    ConsentChecker? consentChecker,
    LocalUserStore? store,
    LocalRingBufferSink? ringBufferSink,
    ConsoleSink? consoleSink,
    HttpBatchSink? httpSink,
    NoOpSink? noOpSink,
    PlatformRole Function()? platformRoleProvider,
  }) : _config = config,
       _consentService = consentService,
       _consentChecker = consentChecker,
       _store = store ?? LocalUserStore(),
       _ringBuffer = ringBufferSink ?? LocalRingBufferSink(),
       _console = consoleSink ?? const ConsoleSink(),
       _http = httpSink,
       _noOp = noOpSink ?? const NoOpSink(),
       _platformRoleProvider =
           platformRoleProvider ?? (() => PlatformRole.attendee);

  final AnalyticsConfig _config;
  final ConsentService? _consentService;
  final ConsentChecker? _consentChecker;
  final LocalUserStore _store;
  final LocalRingBufferSink _ringBuffer;
  final ConsoleSink _console;
  final HttpBatchSink? _http;
  final NoOpSink _noOp;
  final PlatformRole Function() _platformRoleProvider;

  String? _anonymousSessionKey;
  final List<AnalyticsEvent> _recentMirror = [];
  static const _mirrorCapacity = 15;

  AnalyticsConfig get config => _config;

  LocalRingBufferSink get ringBuffer => _ringBuffer;

  HttpBatchSink? get httpSink => _http;

  List<AnalyticsEvent> get recentEvents => List.unmodifiable(_recentMirror);

  static AnalyticsService create({
    required AnalyticsConfig config,
    ConsentService? consentService,
    LocalUserStore? store,
    PlatformRole Function()? platformRoleProvider,
  }) {
    final resolvedStore = store ?? LocalUserStore();
    HttpBatchSink? httpSink;
    if (config.remoteEnabled) {
      httpSink = HttpBatchSink(config: config, store: resolvedStore);
    }
    return AnalyticsService(
      config: config,
      consentService: consentService,
      store: resolvedStore,
      ringBufferSink: LocalRingBufferSink(
        prefs: null,
        capacity: config.ringBufferCapacity,
      ),
      httpSink: httpSink,
      platformRoleProvider: platformRoleProvider,
    );
  }

  Future<void> track(
    String name, {
    Map<String, Object?> properties = const {},
    String? route,
    String? sessionId,
  }) async {
    if (!_config.enabled) return;
    final hasConsent = await _hasConsent();
    if (!hasConsent) return;

    final filtered = filterAnalyticsProperties(properties);
    final enriched = await _enrich(filtered);
    final event = AnalyticsEvent(
      name: name,
      properties: enriched,
      route: route,
      sessionId: sessionId,
      configProfile: AppConfig.configProfile,
      buildSha: BuildInfo.buildSha,
    );

    _rememberRecent(event);

    if (_config.consoleEnabled) {
      await _console.emit(event);
    }

    if (_config.localBufferEnabled) {
      await _ringBuffer.emit(event);
    }

    final http = _http;
    if (http != null && _config.remoteEnabled) {
      await http.emit(event);
    } else if (!_config.consoleEnabled && !_config.localBufferEnabled) {
      await _noOp.emit(event);
    }
  }

  Future<void> trackAppError({
    required String errorType,
    bool fatal = true,
    String? route,
  }) => track(
    'app_error',
    properties: {'error_type': errorType, 'fatal': fatal},
    route: route,
  );

  Future<void> flush() async {
    await _http?.flush();
  }

  Future<String> exportDiagnosticsJson() => _ringBuffer.exportJson();

  Future<String> exportJson() => exportDiagnosticsJson();

  Future<void> clearDiagnosticsBuffer() async {
    await _ringBuffer.clear();
    _recentMirror.clear();
  }

  Future<void> clearBuffer() => clearDiagnosticsBuffer();

  Future<int> diagnosticsEventCount() => _ringBuffer.count();

  Future<List<AnalyticsEvent>> recentDiagnosticsEvents({int limit = 10}) async {
    final all = await _ringBuffer.readAll();
    if (all.length <= limit) return all;
    return all.sublist(all.length - limit);
  }

  Future<bool> _hasConsent() async {
    final checker = _consentChecker;
    if (checker != null) return checker();
    final service = _consentService;
    if (service != null) return service.hasAccepted();
    return false;
  }

  Future<Map<String, Object?>> _enrich(Map<String, Object?> base) async {
    final key = await _anonymousSessionKeyResolved();
    return {
      ...base,
      'app_version': BuildInfo.version,
      'build_sha': BuildInfo.buildSha,
      'config_profile': AppConfig.configProfile,
      'platform_role': _platformRoleProvider().name,
      'anonymous_session_key': key,
    };
  }

  Future<String> _anonymousSessionKeyResolved() async {
    if (_anonymousSessionKey != null) return _anonymousSessionKey!;
    final existing = await _store.getAnalyticsAnonymousSessionKey();
    if (existing != null && existing.isNotEmpty) {
      _anonymousSessionKey = existing;
      return existing;
    }
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final key = sha256.convert(bytes).toString().substring(0, 32);
    await _store.setAnalyticsAnonymousSessionKey(key);
    _anonymousSessionKey = key;
    return key;
  }

  void _rememberRecent(AnalyticsEvent event) {
    _recentMirror.insert(0, event);
    if (_recentMirror.length > _mirrorCapacity) {
      _recentMirror.removeRange(_mirrorCapacity, _recentMirror.length);
    }
  }
}
