import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web/web.dart';

import 'oauth_redirect_stub.dart';

const _verifierKey = 'flo_pkce_verifier';
const _returnKey = 'flo_pkce_return';
const _stateKey = 'flo_pkce_state';

abstract final class OAuthRedirect {
  static void storePkceState({
    required String verifier,
    required String returnUrl,
    required String state,
  }) {
    window.sessionStorage.setItem(_verifierKey, verifier);
    window.sessionStorage.setItem(_returnKey, returnUrl);
    window.sessionStorage.setItem(_stateKey, state);
  }

  static PkceStoredState? readPkceState() {
    final verifier = window.sessionStorage.getItem(_verifierKey);
    final returnUrl = window.sessionStorage.getItem(_returnKey);
    final state = window.sessionStorage.getItem(_stateKey);
    if (verifier == null || returnUrl == null || state == null) return null;
    return PkceStoredState(
      verifier: verifier,
      returnUrl: returnUrl,
      state: state,
    );
  }

  static void clearPkceState() {
    window.sessionStorage.removeItem(_verifierKey);
    window.sessionStorage.removeItem(_returnKey);
    window.sessionStorage.removeItem(_stateKey);
  }

  static Future<void> navigateTo(String url) async {
    window.location.assign(url);
  }

  /// Test-only override for [exchangeToken].
  static Future<Map<String, dynamic>?> Function(
    Uri tokenUri,
    Map<String, String> body,
  )?
  testExchangeToken;

  static Future<Map<String, dynamic>?> exchangeToken(
    Uri tokenUri,
    Map<String, String> body,
  ) async {
    final override = OAuthRedirect.testExchangeToken;
    if (override != null) {
      return override(tokenUri, body);
    }
    final response = await http
        .post(
          tokenUri,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: body,
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode >= 400) return null;
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
