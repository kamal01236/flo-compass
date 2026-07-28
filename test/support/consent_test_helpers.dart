import 'package:shared_preferences/shared_preferences.dart';

import 'package:flo_compass/core/consent/consent_service.dart';
import 'package:flo_compass/data/local/local_user_store.dart';
import 'package:flo_compass/providers/consent_provider.dart';

/// Pre-accept privacy consent for widget tests that boot the full app.
Future<void> seedAcceptedConsent() async {
  SharedPreferences.setMockInitialValues({});
  final store = LocalUserStore();
  await store.setConsentAccepted(
    version: kPrivacyPolicyVersion,
    acceptedAt: DateTime.now(),
  );
}

/// ConsentState with privacy already accepted for router tests.
Future<ConsentState> acceptedConsentState() async {
  final state = ConsentState();
  await state.init();
  await state.acceptPrivacy();
  return state;
}
