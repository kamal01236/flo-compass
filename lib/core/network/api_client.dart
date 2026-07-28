import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_token_provider.dart';
import '../config/runtime_config.dart';
import '../logging/app_logger.dart';
import 'network_exception.dart';

class ApiClient {
  ApiClient({http.Client? client, AuthTokenProvider? tokenProvider})
    : _client = client ?? http.Client(),
      _tokenProvider = tokenProvider;

  final http.Client _client;
  final AuthTokenProvider? _tokenProvider;

  Uri baseUri(String path, {Map<String, String>? query}) {
    final base = RuntimeConfig.apiBaseUrl;
    if (base.isEmpty) {
      throw StateError('apiBaseUrl is not configured');
    }
    final normalized = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    return Uri.parse('$normalized$path').replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers(Map<String, String>? headers) async {
    final merged = <String, String>{'Accept': 'application/json', ...?headers};
    final token = await _tokenProvider?.getAccessToken();
    if (token != null && token.isNotEmpty) {
      merged['Authorization'] = 'Bearer $token';
    }
    return merged;
  }

  Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      var response = await _client
          .get(uri, headers: await _headers(headers))
          .timeout(timeout);
      if (response.statusCode == 401 && _tokenProvider != null) {
        final provider = _tokenProvider;
        final refreshed = await provider.refresh();
        if (refreshed) {
          response = await _client
              .get(uri, headers: await _headers(headers))
              .timeout(timeout);
        }
      }
      if (response.statusCode >= 400) {
        throw NetworkException(
          'GET ${uri.path} failed',
          statusCode: response.statusCode,
        );
      }
      return response;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      AppLog.e('ApiClient GET failed', e, st);
      throw NetworkException('GET ${uri.path} failed: $e');
    }
  }

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 8),
    bool skipStatusCheck = false,
  }) async {
    try {
      final encoded = body is String ? body : jsonEncode(body);
      var merged = await _headers(headers);
      if (!merged.containsKey('Content-Type')) {
        merged['Content-Type'] = 'application/json';
      }
      var response = await _client
          .post(uri, headers: merged, body: encoded)
          .timeout(timeout);
      if (response.statusCode == 401 && _tokenProvider != null) {
        final provider = _tokenProvider;
        final refreshed = await provider.refresh();
        if (refreshed) {
          merged = await _headers(headers);
          if (!merged.containsKey('Content-Type')) {
            merged['Content-Type'] = 'application/json';
          }
          response = await _client
              .post(uri, headers: merged, body: encoded)
              .timeout(timeout);
        }
      }
      if (!skipStatusCheck && response.statusCode >= 400) {
        throw NetworkException(
          'POST ${uri.path} failed',
          statusCode: response.statusCode,
        );
      }
      return response;
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      AppLog.e('ApiClient POST failed', e, st);
      throw NetworkException('POST ${uri.path} failed: $e');
    }
  }

  void dispose() => _client.close();
}
