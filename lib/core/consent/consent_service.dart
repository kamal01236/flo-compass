import '../../data/local/local_user_store.dart';

/// Current privacy policy version — bump when policy text changes materially.
const kPrivacyPolicyVersion = '2026-07-11';

class ConsentService {
  ConsentService({LocalUserStore? store}) : _store = store ?? LocalUserStore();

  final LocalUserStore _store;

  Future<bool> hasAccepted() =>
      _store.hasAcceptedConsent(kPrivacyPolicyVersion);

  Future<DateTime?> acceptedAt() => _store.getConsentAcceptedAt();

  String get requiredVersion => kPrivacyPolicyVersion;

  Future<void> accept() async {
    await _store.setConsentAccepted(
      version: kPrivacyPolicyVersion,
      acceptedAt: DateTime.now(),
    );
  }

  Future<void> decline() => _store.clearConsent();
}
