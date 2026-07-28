# Auth and Consent

## Privacy consent (all users)

- `ConsentService` / `ConsentState` track `hasAcceptedPrivacy`, `privacyPolicyVersion`, `acceptedAt`
- `LocalUserStore` persists consent keys in `shared_preferences` (web: not encrypted — see backlog `encrypted-web-storage.md`)
- `ConsentGate` blocks main shell until accepted
- `/privacy` route shows full policy text
- Decline shows limited-mode message; user cannot proceed

## OAuth2 PKCE (optional)

When `auth.enabled: true` in config:

1. User taps Login on profile → redirect to Azure AD authorize URL with PKCE challenge
2. Azure redirects to `/auth/callback` with `code`
3. `AuthService` exchanges code for tokens (POST token endpoint)
4. Session stored in memory + `LocalUserStore` metadata

Config fields: `tenantId`, `clientId`, `redirectUri`, `scopes`.

Secrets stay out of repo; inject via CI `--dart-define` if needed.

## Capability matrix

| Capability | Anonymous + consent | Authenticated |
|------------|---------------------|---------------|
| Browse / plan / companion | Yes | Yes |
| Submit feedback | Yes | Yes (+ user id) |
| Earn XP / leaderboard | No | Yes |
| Event registration signal | No | Yes |

`AppCapability` enum + `capability_guard.dart` enforce checks when auth is enabled.
