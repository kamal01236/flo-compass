# Data Sources

## EventRepository contract

`EventRepository` (`lib/domain/repositories/event_repository.dart`) defines:

- `loadMeta`, `loadSessions`, `loadSpeakers`, `loadVenues`, `loadTracks`, `loadLearningPaths`, `getSessionById`

## Implementations

| Class | When used |
|-------|-----------|
| `MockEventRepository` | `dataSource: mock` (default) — loads JSON assets |
| `RemoteEventRepository` | `dataSource: remote` — HTTP via `ApiClient`; falls back to mock when `apiBaseUrl` empty |

## ApiClient

- Optional `Authorization` header via `AuthTokenProvider` callback
- `baseUri` helper from `RuntimeConfig.apiBaseUrl`
- Timeouts; no UI coupling

## DI wiring

```dart
sl.registerLazySingleton<EventRepository>(() {
  if (RuntimeConfig.dataSource == DataSource.remote) {
    return RemoteEventRepository(apiClient: sl(), fallback: MockEventRepository());
  }
  return MockEventRepository(strictIntegrity: false);
});
```

Full remote sync and OpenAPI contracts: see `docs/plans/backlog/api-contract-openapi.md`.
