import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flo_compass/core/config/runtime_config.dart';
import 'package:flo_compass/core/network/api_client.dart';
import 'package:flo_compass/data/repositories/mock_event_repository.dart';
import 'package:flo_compass/data/repositories/remote_event_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('delegates to mock when apiBaseUrl empty', () async {
    RuntimeConfig.apiBaseUrl = '';
    final repo = RemoteEventRepository(
      apiClient: ApiClient(),
      fallback: MockEventRepository(strictIntegrity: false),
    );
    final sessions = await repo.loadSessions();
    expect(sessions, isNotEmpty);
  });

  test('falls back to mock when remote GET fails', () async {
    RuntimeConfig.apiBaseUrl = 'http://localhost:9999';
    final client = ApiClient(
      client: MockClient((request) async {
        return http.Response('not found', 404);
      }),
    );
    final repo = RemoteEventRepository(
      apiClient: client,
      fallback: MockEventRepository(strictIntegrity: false),
    );

    final meta = await repo.loadMeta();
    expect(meta.eventName, isNotEmpty);
    RuntimeConfig.apiBaseUrl = '';
  });
}
