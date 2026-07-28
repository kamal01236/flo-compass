import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flo_compass/core/auth/auth_service.dart';
import 'package:flo_compass/core/auth/auth_token_provider.dart';
import 'package:flo_compass/core/config/auth_config.dart';
import 'package:flo_compass/core/config/runtime_config.dart';
import 'package:flo_compass/core/network/api_client.dart';
import 'package:flo_compass/data/local/local_user_store.dart';
import 'package:flo_compass/shared/utils/oauth_redirect.dart';

void main() {
  late AuthConfig originalAuth;

  setUp(() {
    originalAuth = RuntimeConfig.auth;
    RuntimeConfig.auth = _enabledAuthConfig;
    OAuthRedirect.testExchangeToken = null;
  });

  tearDown(() {
    RuntimeConfig.auth = originalAuth;
    OAuthRedirect.testExchangeToken = null;
  });

  group('AuthService.restoreSession', () {
    test('restores valid non-expired access token without refresh', () async {
      SharedPreferences.setMockInitialValues({
        LocalUserStore.authSubjectKey: 'user-1',
        LocalUserStore.authDisplayNameKey: 'Test User',
        LocalUserStore.authExpiresAtKey: DateTime.now()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch,
        LocalUserStore.authAccessTokenKey: 'fresh-access',
        LocalUserStore.authIdTokenKey: 'fresh-id',
      });
      var refreshCalled = false;
      OAuthRedirect.testExchangeToken = (_, _) async {
        refreshCalled = true;
        return null;
      };

      final store = LocalUserStore();
      final service = AuthService(store: store);
      await service.restoreSession();

      expect(service.isAuthenticated, isTrue);
      expect(service.session?.accessToken, 'fresh-access');
      expect(refreshCalled, isFalse);
    });

    test('refreshes expired access token when refresh token exists', () async {
      SharedPreferences.setMockInitialValues({
        LocalUserStore.authSubjectKey: 'user-1',
        LocalUserStore.authDisplayNameKey: 'Test User',
        LocalUserStore.authExpiresAtKey: DateTime.now()
            .subtract(const Duration(minutes: 5))
            .millisecondsSinceEpoch,
        LocalUserStore.authAccessTokenKey: 'expired-access',
        LocalUserStore.authRefreshTokenKey: 'refresh-token',
        LocalUserStore.authIdTokenKey: 'old-id',
      });
      OAuthRedirect.testExchangeToken = (_, body) async {
        expect(body['grant_type'], 'refresh_token');
        expect(body['refresh_token'], 'refresh-token');
        return {
          'access_token': 'new-access',
          'refresh_token': 'new-refresh',
          'id_token': 'new-id',
          'expires_in': 3600,
        };
      };

      final store = LocalUserStore();
      final service = AuthService(store: store);
      await service.restoreSession();

      expect(service.isAuthenticated, isTrue);
      expect(service.session?.accessToken, 'new-access');

      final meta = await store.readAuthMetadata();
      expect(meta?.accessToken, 'new-access');
      expect(meta?.refreshToken, 'new-refresh');
    });

    test('returns null when expired and no refresh token', () async {
      SharedPreferences.setMockInitialValues({
        LocalUserStore.authSubjectKey: 'user-1',
        LocalUserStore.authDisplayNameKey: 'Test User',
        LocalUserStore.authExpiresAtKey: DateTime.now()
            .subtract(const Duration(minutes: 5))
            .millisecondsSinceEpoch,
        LocalUserStore.authAccessTokenKey: 'expired-access',
      });

      final service = AuthService(store: LocalUserStore());
      await service.restoreSession();

      expect(service.isAuthenticated, isFalse);
      expect(service.session, isNull);
    });
  });

  group('ApiClient 401 retry', () {
    test('retries once after refresh succeeds', () async {
      final client = _RetryClient();
      final tokenProvider = _RefreshingTokenProvider(
        initialToken: 'stale-token',
        refreshedToken: 'fresh-token',
      );
      final api = ApiClient(client: client, tokenProvider: tokenProvider);

      final response = await api.get(Uri.parse('https://api.example.com/data'));

      expect(response.statusCode, 200);
      expect(client.getCount, 2);
      expect(tokenProvider.refreshCount, 1);
      expect(client.lastAuthorization, 'Bearer fresh-token');
    });
  });
}

const _enabledAuthConfig = AuthConfig(
  enabled: true,
  tenantId: 'tenant',
  clientId: 'client',
  redirectUri: 'https://example.com/auth/callback',
  scopes: ['openid', 'profile', 'email', 'offline_access'],
);

class _RefreshingTokenProvider implements AuthTokenProvider {
  _RefreshingTokenProvider({
    required this.initialToken,
    required this.refreshedToken,
  });

  final String initialToken;
  final String refreshedToken;
  int refreshCount = 0;
  bool _useRefreshed = false;

  @override
  Future<String?> getAccessToken() async {
    return _useRefreshed ? refreshedToken : initialToken;
  }

  @override
  Future<bool> refresh() async {
    refreshCount++;
    _useRefreshed = true;
    return true;
  }
}

class _RetryClient extends http.BaseClient {
  int getCount = 0;
  String? lastAuthorization;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    getCount++;
    lastAuthorization = request.headers['Authorization'];
    final status = getCount == 1 ? 401 : 200;
    return http.StreamedResponse(Stream.value([]), status, request: request);
  }
}
