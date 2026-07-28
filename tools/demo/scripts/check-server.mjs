#!/usr/bin/env node
// check-server.mjs - fail fast when the demo target is not reachable.
//
// Default target is the local Tier 2 Docker/nginx stack on :8080. Override
// via FLO_DEMO_BASE_URL for Tier 1 dev server (:3000) or an Azure preview.

const BASE = (process.env.FLO_DEMO_BASE_URL || 'http://localhost:8080').replace(/\/$/, '');
const HEALTH = `${BASE}/health`;

const controller = new AbortController();
const timer = setTimeout(() => controller.abort(), 8000);

try {
  const res = await fetch(HEALTH, { signal: controller.signal });
  if (!res.ok) {
    throw new Error(`HTTP ${res.status}`);
  }
  const text = (await res.text()).trim();
  console.log(`  server ok: ${BASE} (${text || 'no body'})`);
  process.exit(0);
} catch (err) {
  console.error(`\n  ERROR: cannot reach ${HEALTH}`);
  console.error(`         ${err.message || err}`);
  console.error('');
  console.error('  Start the local Tier 2 stack (Docker + nginx) in WSL first:');
  console.error('    bash scripts/wsl_deploy.sh');
  console.error('    # or: docker compose up --build');
  console.error('');
  console.error(`  Alternatively, override the target: FLO_DEMO_BASE_URL=... npm run all`);
  process.exit(1);
} finally {
  clearTimeout(timer);
}
