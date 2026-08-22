---
name: GitHub Pages static deploy
overview: Deploy Flo Compass as static Flutter web via GitHub Actions → GitHub Pages, matching kamal01236/asset-os (no Fly required).
todos:
  - id: base-href
    content: Use $FLUTTER_BASE_HREF in web/index.html for /flo-compass/ Pages base
    status: completed
  - id: workflow
    content: Retarget CI to validate + flutter build web + deploy-pages (Asset OS pattern)
    status: completed
  - id: docs-rules
    content: Point README and deploy rules at Pages URL; demote Fly/GHCR as optional
    status: completed
  - id: enable-pages
    content: Enable repo Pages (Actions source) and verify pipeline
    status: in_progress
isProject: false
---

# GitHub Pages static deploy (Asset OS parity)

## Goal

Ship Flo Compass the same way [asset-os](https://github.com/kamal01236/asset-os) does:

- Push to `main` → GitHub Actions builds Flutter web
- Publish static `build/web` with `actions/upload-pages-artifact` + `actions/deploy-pages`
- Public URL: `https://kamal01236.github.io/flo-compass/`
- No `FLY_API_TOKEN` required for a working preview

## Reference (asset-os)

- Workflow: `.github/workflows/pages-deploy.yml`
- Build: `flutter build web --release --base-href /asset-os/`
- SPA deep links: `cp build/web/index.html build/web/404.html`
- Pages source: **GitHub Actions** (not branch `/`)

## Flo Compass deltas

| Item | Choice |
|------|--------|
| Base href | `/flo-compass/` (repo name) |
| Prod profile | `CONFIG_PROFILE=prod` + `BUILD_SHA` |
| Web flags | Keep `--pwa-strategy=none --no-web-resources-cdn` (existing SW/CSP fixes) |
| Validate | Keep analyze/test/data/route gates before deploy |
| Docker / Fly | Local Tier 2 only; Fly optional / demoted (same as asset-os after Fly token failures) |

## Phases

1. **Base href** — replace hardcoded `<base href="/">` with `$FLUTTER_BASE_HREF`
2. **CI** — rewrite `.github/workflows/ci-deploy.yml` to validate + Pages deploy
3. **Docs/rules** — README + Tier 3 / deployment rules point at Pages
4. **Enable Pages** — Settings → Pages → Source = GitHub Actions (API if permitted)

## Success criteria

- Workflow green on `main`
- `https://kamal01236.github.io/flo-compass/` loads
- Refresh on `/flo-compass/session/s-001` does not hard-404 (404.html → SPA)
