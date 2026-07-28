import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/audit_actor_resolver.dart';
import '../core/config/runtime_config.dart';
import '../data/services/ops_audit_service.dart';

class OpsConfigState extends ChangeNotifier {
  OpsConfigState({SharedPreferences? prefs, OpsAuditService? auditService})
    : _prefs = prefs,
      _auditService = auditService ?? OpsAuditService();

  static const _organizerKey = 'flo_compass_ops_organizer_allowlist';
  static const _adminKey = 'flo_compass_ops_admin_allowlist';

  SharedPreferences? _prefs;
  final OpsAuditService _auditService;

  bool loading = false;
  String? error;
  Set<String> organizerAllowlist = {};
  Set<String> adminAllowlist = {};
  Set<String>? _baselineOrganizerAllowlist;
  Set<String>? _baselineAdminAllowlist;

  Future<SharedPreferences> get _storage async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> init() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final prefs = await _storage;
      final organizerRaw = prefs.getString(_organizerKey);
      final adminRaw = prefs.getString(_adminKey);
      _baselineOrganizerAllowlist ??= Set<String>.from(
        RuntimeConfig.organizerAllowlist,
      );
      _baselineAdminAllowlist ??= Set<String>.from(
        RuntimeConfig.adminAllowlist,
      );
      organizerAllowlist = organizerRaw == null
          ? Set<String>.from(RuntimeConfig.organizerAllowlist)
          : _parseAllowlist(organizerRaw);
      adminAllowlist = adminRaw == null
          ? Set<String>.from(RuntimeConfig.adminAllowlist)
          : _parseAllowlist(adminRaw);
      _applyToRuntime();
    } catch (e) {
      error = kDebugMode ? '$e' : 'Failed to load ops configuration';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> saveAllowlists({
    required Set<String> organizer,
    required Set<String> admin,
    String? actor,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final prefs = await _storage;
      final normalizedOrganizer = _normalizeAllowlist(organizer);
      final normalizedAdmin = _normalizeAllowlist(admin);
      await prefs.setString(
        _organizerKey,
        jsonEncode(normalizedOrganizer.toList()..sort()),
      );
      await prefs.setString(
        _adminKey,
        jsonEncode(normalizedAdmin.toList()..sort()),
      );
      organizerAllowlist = normalizedOrganizer;
      adminAllowlist = normalizedAdmin;
      _applyToRuntime();
      await _auditService.record(
        action: AuditActions.opsAllowlistsUpdate,
        actor: resolveAuditActor(),
        entityType: 'ops_config',
        metadata: {
          'organizerCount': normalizedOrganizer.length,
          'adminCount': normalizedAdmin.length,
          'actorLabel': ?actor,
        },
      );
    } catch (e) {
      error = kDebugMode ? '$e' : 'Failed to save ops configuration';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _applyToRuntime() {
    RuntimeConfig.organizerAllowlist = Set<String>.from(organizerAllowlist);
    RuntimeConfig.adminAllowlist = Set<String>.from(adminAllowlist);
  }

  @override
  void dispose() {
    if (_baselineOrganizerAllowlist != null) {
      RuntimeConfig.organizerAllowlist = Set<String>.from(
        _baselineOrganizerAllowlist!,
      );
    }
    if (_baselineAdminAllowlist != null) {
      RuntimeConfig.adminAllowlist = Set<String>.from(_baselineAdminAllowlist!);
    }
    super.dispose();
  }

  Set<String> _parseAllowlist(String raw) {
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return _normalizeAllowlist(decoded.map((e) => e.toString()).toSet());
    } catch (_) {
      return <String>{};
    }
  }

  Set<String> _normalizeAllowlist(Set<String> raw) {
    return raw
        .map((entry) => entry.trim().toLowerCase())
        .where((entry) => entry.isNotEmpty)
        .toSet();
  }
}

Future<void> recordAudit({
  required String action,
  String? entityType,
  String? entityId,
  Map<String, dynamic>? metadata,
  AuditLogService? auditLog,
}) async {
  try {
    final service = auditLog ?? AuditLogService();
    await service.record(
      action: action,
      actor: resolveAuditActor(),
      entityType: entityType,
      entityId: entityId,
      metadata: metadata,
    );
  } catch (_) {
    // Audit is best-effort; never block user actions.
  }
}

@Deprecated('Use recordAudit with AuditActions constants')
Future<void> appendOpsAudit({
  required String action,
  OpsAuditService? auditService,
}) async {
  await recordAudit(action: action);
}
