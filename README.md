# Flo Compass

Flutter web event companion: session discovery, My Plan, venue map, and AI Q&A over mock conference data.

## Stack

- Flutter **3.44.0** / Dart **3.10+** (web only)
- nginx SPA hosting via `docker/Dockerfile`
- **CI/CD:** GitHub Actions → image on **GHCR** → deploy to **Fly.io**

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

## Deploy (GitHub → GHCR → Fly.io)

Push to `main` (or `master`) runs [`.github/workflows/ci-deploy.yml`](.github/workflows/ci-deploy.yml):

1. Validate (analyze, tests, data/route checks)
2. Build `docker/Dockerfile` with `CONFIG_PROFILE=prod`
3. Push `ghcr.io/<owner>/<repo>:<sha>` and `:latest`
4. If `FLY_API_TOKEN` is set, deploy that image to Fly.io

### One-time Fly setup

1. Install [flyctl](https://fly.io/docs/hands-on/install-flyctl/) and sign in: `fly auth login`
2. Create the app (pick a free name if `flo-compass` is taken):

   ```bash
   fly apps create flo-compass
   ```

3. Edit `app = '...'` in [`fly.toml`](fly.toml) to match, **or** set GitHub repo variable `FLY_APP_NAME`
4. In the GitHub repo: **Settings → Secrets and variables → Actions**
   - Secret: `FLY_API_TOKEN` — from `fly tokens create deploy`
   - Optional variable: `FLY_APP_NAME` — overrides `fly.toml` `app`
5. Allow GHCR packages for the repo (Actions already uses `GITHUB_TOKEN`). If the package is private, either make it public under **Packages**, or configure Fly registry auth so machines can pull the image.
6. Push to `main` — workflow summary prints `https://<app>.fly.dev`

### Public URL

After a successful deploy:

| Check | URL |
|-------|-----|
| App | `https://<app>.fly.dev/` |
| Deep link | `https://<app>.fly.dev/session/s-001` |
| Health | `https://<app>.fly.dev/health` |

Replace `<app>` with the value in `fly.toml` / `FLY_APP_NAME`.

### Manual deploy (optional)

```bash
fly deploy --config fly.toml --ha=false
# or reuse a GHCR image:
fly deploy --app <app> --image ghcr.io/<owner>/<repo>:<sha> --remote-only --ha=false
```

## Config profiles

| Profile | When | Notes |
|---------|------|--------|
| `dev` | Local demos | Mock admin role / demo flags — **do not** ship to production |
| `prod` | CI + Fly | Default in GitHub Actions and `fly.toml` |
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
| `docker/` | Dockerfile + nginx |
| `.github/workflows/` | CI + deploy |
| `fly.toml` | Fly.io service config |
| `hackathon-docs/` | **Legacy** archive (not used by CI) |

`docker/arm-template.json` is a leftover Azure template and is **not** used by the GitHub → Fly path.

## License / product

Flo Compass complements official event platforms (registration/ticketing stay elsewhere). See `.cursor/rules/flo-compass-product.mdc`.
