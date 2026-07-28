import 'package:flutter/foundation.dart';

import '../core/auth/app_capability.dart';
import '../core/auth/auth_service.dart';
import '../core/auth/mock_user.dart';
import '../core/auth/platform_role.dart';
import '../shared/utils/oauth_redirect.dart';

class AuthState extends ChangeNotifier {
  AuthState({AuthService? service}) : _service = service ?? AuthService();

  final AuthService _service;

  bool _initialized = false;
  bool get isReady => _initialized;
  bool get isEnabled => _service.isEnabled;
  bool get isAuthenticated => _service.isAuthenticated;
  String? get displayName => _service.session?.displayName;
  String? get email => _service.session?.email;
  PlatformRole get platformRole => _service.platformRole;

  AuthService get service => _service;

  Future<void> init() async {
    await _service.restoreSession();
    _initialized = true;
    notifyListeners();
  }

  bool hasCapability(AppCapability capability) =>
      _service.hasCapability(capability);

  Future<void> beginLogin({String returnUrl = '/profile'}) async {
    final url = _service.beginLogin(returnUrl: returnUrl);
    await OAuthRedirect.navigateTo(url);
  }

  Future<bool> handleCallback({
    required String? code,
    required String? state,
    required String? error,
  }) async {
    final session = await _service.handleCallback(
      code: code,
      state: state,
      error: error,
    );
    notifyListeners();
    return session != null;
  }

  String? consumeReturnUrl() => _service.consumeReturnUrl();

  Future<void> logout() async {
    await _service.logout();
    notifyListeners();
  }

  Future<void> signInMock(MockUser user) async {
    await _service.signInMock(user);
    notifyListeners();
  }
}
