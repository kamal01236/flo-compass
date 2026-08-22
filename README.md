# Flo Compass

Flutter web event companion: session discovery, My Plan, venue map, and AI Q&A over mock conference data.

## Stack

- Flutter **3.44.0** / Dart **3.10+** (web only)
- **Production:** GitHub Actions → static **GitHub Pages** (same pattern as [asset-os](https://github.com/kamal01236/asset-os))
- nginx SPA via `docker/Dockerfile` for **local** Tier 2 smoke only

## Local development (WSL2)

Use Ubuntu 24.04 WSL2 with Flutter and Docker installed **inside WSL** (not Docker Desktop).

```bash
flutter pub get
flutter analyze && flutter test

# Dev server (hot reload) — open http://localhost:3000 from Windows
bash scripts/wsl_dev.sh
# or: flutter run -d web-server --web-port=3000 --web-hostname=0.0.0.0
```

### Local Docker smoke (Tier 2)

```bash
docker compose up --build
# http://localhost:8080/
# http://localhost:8080/session/s-001  (deep-link refresh must not 404)
```

## Deploy (GitHub Actions → GitHub Pages)

Push to `main` (or `master`) runs [`.github/workflows/ci-deploy.yml`](.github/workflows/ci-deploy.yml):

1. Validate (analyze, tests, data/route checks)
2. `flutter build web --release` with `--base-href /flo-compass/` and `CONFIG_PROFILE=prod`
3. Copy `404.html` from `index.html` (SPA deep-link fallback on Pages)
4. Publish via `actions/deploy-pages`

**Public preview URL:** [https://kamal01236.github.io/flo-compass/](https://kamal01236.github.io/flo-compass/)

### One-time GitHub Pages setup

1. Repo must be **public** (Free plan) or have GitHub Pro/Team for private Pages.
2. **Settings → Pages → Build and deployment → Source** = **GitHub Actions**.
3. Push to `main` (or **Actions → CI and Deploy → Run workflow**).
4. After a green **Deploy to GitHub Pages** job, open the URL above.
5. Deep-link check: open `/flo-compass/session/s-001` and refresh — must load the app (not a hard 404).

No deploy tokens are required for Pages (uses `GITHUB_TOKEN` + OIDC).

### Optional: Fly.io / GHCR

`docker/Dockerfile`, `fly.toml`, and local `docker compose` remain for container smoke tests. Fly is **not** on the default CI path (same decision as asset-os after empty `FLY_API_TOKEN` deploys). Re-add a Fly job only if you intentionally host there.

## Config profiles

| Profile | When | Notes |
|---------|------|--------|
| `dev` | Local demos | Mock admin role / demo flags — **do not** ship to production |
| `prod` | CI + Pages | Default in GitHub Actions |
| `default` | Fallback | See `assets/config/` |

Local override:

```bash
flutter run -d web-server --web-port=3000 --web-hostname=0.0.0.0 \
  --dart-define=CONFIG_PROFILE=dev
```

## Repository layout (high level)

| Path | Purpose |
|------|---------|
| `lib/` | App code |
| `assets/data/` | Mock Flo dataset |
| `web/` | Flutter web shell (`$FLUTTER_BASE_HREF` for Pages) |
| `docker/` | Local Tier 2 Dockerfile + nginx |
| `.github/workflows/` | CI + Pages deploy |
| `hackathon-docs/` | **Legacy** archive (not used by CI) |

## License / product

Flo Compass complements official event platforms (registration/ticketing stay elsewhere). See `.cursor/rules/flo-compass-product.mdc`.
