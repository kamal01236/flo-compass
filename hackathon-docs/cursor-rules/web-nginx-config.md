# Web Nginx Config

| Field | Value |
|-------|-------|
| **File** | `.cursor/rules/web-nginx-config.mdc` |
| **Purpose** | nginx SPA fallback, CSP, cache headers |
| **Scope** | `globs: docker/**` |
| **When to @cite** | nginx.conf, Dockerfile COPY, deep-link refresh, CSP or cache headers |

## Key guardrails

- go_router history mode requires `try_files` fallback to `/index.html`
- Config at `docker/nginx/default.conf`; must be COPYed in Dockerfile
- Cache: immutable long TTL for JS/assets; `no-cache` for `/index.html`
- Content-Security-Policy header required; gzip on for js/json/css/svg
- Do not remove nginx.conf or Dockerfile COPY line
- Do not change target port from 80 (ARM template expects it)

## Source

[`.cursor/rules/web-nginx-config.mdc`](../../.cursor/rules/web-nginx-config.mdc)
