import 'package:flutter/foundation.dart';

import '../core/consent/consent_service.dart';
import '../data/services/audit_log_service.dart';
import 'ops_config_provider.dart';

class ConsentState extends ChangeNotifier {
  ConsentState({ConsentService? service})
    : _service = service ?? ConsentService();

  final ConsentService _service;

  bool _initialized = false;
  bool hasAcceptedPrivacy = false;
  String privacyPolicyVersion = kPrivacyPolicyVersion;
  DateTime? acceptedAt;

  bool get isReady => _initialized;

  Future<void> init() async {
    hasAcceptedPrivacy = await _service.hasAccepted();
    privacyPolicyVersion = _service.requiredVersion;
    acceptedAt = await _service.acceptedAt();
    _initialized = true;
    notifyListeners();
  }

  Future<void> acceptPrivacy() async {
    await _service.accept();
    hasAcceptedPrivacy = true;
    acceptedAt = DateTime.now();
    notifyListeners();
    await recordAudit(
      action: AuditActions.consentAccept,
      entityType: 'consent',
      metadata: {'version': privacyPolicyVersion},
    );
  }

  Future<void> declinePrivacy() async {
    await _service.decline();
    hasAcceptedPrivacy = false;
    acceptedAt = null;
    notifyListeners();
    await recordAudit(
      action: AuditActions.consentDecline,
      entityType: 'consent',
      metadata: {'version': privacyPolicyVersion},
    );
  }
}
