# Flo Compass Architecture

Living architecture reference for the Flo Compass Flutter web app.

## Layers

| Layer | Path | Responsibility |
|-------|------|----------------|
| Features | `lib/features/` | Screens, feature widgets, user flows |
| Shared | `lib/shared/` | Reusable widgets, theme, utils, a11y |
| Providers | `lib/providers/` | ChangeNotifier state (Provider) |
| Domain | `lib/domain/` | Entities, repository interfaces |
| Data | `lib/data/` | Repositories, DTOs, mappers, services |
| Core | `lib/core/` | Config, DI, auth, consent, network |

## Boot order

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `configureDependencies()` — loads `RuntimeConfig`, registers `GetIt` services
3. Provider `init()` — profile, event, plan, engagement, settings, consent, auth
4. `createAppRouter()` — GoRouter with consent + onboarding guards
5. `MaterialApp.router` with l10n delegates and theme

## Data source switch

- `dataSource`: `mock` (default) or `remote`
- `apiBaseUrl`: empty until backend exists; override via `--dart-define=API_BASE_URL=...`
- When `remote` without URL: `RemoteEventRepository` delegates to `MockEventRepository`

See [data-sources.md](data-sources.md).

## Auth modes

- **Disabled** (`auth.enabled: false`): anonymous + consent gate only; no login UI
- **OAuth2 PKCE** (`auth.enabled: true`): Azure AD optional login; capability gating for XP/leaderboard

See [auth-and-consent.md](auth-and-consent.md).

## Consent flow

Privacy consent is required for **all users** (anonymous and authenticated) on first launch.
Decline blocks app use (GDPR pattern). Login adds a supplemental notice only.

## Release versioning

- App version from `pubspec.yaml` `version:` field
- Build SHA via `--dart-define=BUILD_SHA=<git-sha>` (default `dev`)
- Tag convention: `v<semver>` on release commits; CI injects `BUILD_SHA` at build time
