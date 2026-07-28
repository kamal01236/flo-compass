#!/usr/bin/env node
// calibrate-clicks.mjs — headed sweep to find Flutter TabBar hit targets (v3.1.2).
//
// Boots localhost:8080, navigates session detail + profile, sweeps Y×X grid,
// saves PNG proofs under output/calib/, writes suggested-coords.json.

import { chromium } from 'playwright';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, '..');
const OUT = path.join(ROOT, 'output');
const CALIB = path.join(OUT, 'calib');
const SCENES_JSON = path.join(ROOT, 'scenes.json');
const SEED_JS = path.join(ROOT, 'seed.js');
const OVERLAY_JS = path.join(ROOT, 'overlay.js');

const DEFAULT_BASE = 'http://localhost:8080';
const VIEWPORT = { width: 1920, height: 1080 };

async function main() {
  const scenesConfig = JSON.parse(await fs.readFile(SCENES_JSON, 'utf8'));
  const base = process.env.FLO_DEMO_BASE_URL || DEFAULT_BASE;
  const headed = process.env.FLO_DEMO_HEADED !== '0';
  const seed = await fs.readFile(SEED_JS, 'utf8');
  const overlay = await fs.readFile(OVERLAY_JS, 'utf8');

  await fs.mkdir(CALIB, { recursive: true });

  const browser = await chromium.launch({
    headless: !headed,
    args: ['--no-sandbox', '--disable-dev-shm-usage', '--use-gl=swiftshader'],
  });

  const context = await browser.newContext({ viewport: VIEWPORT });
  await context.addInitScript(seed);
  await context.addInitScript(overlay);
  const page = await context.newPage();

  const paneBox = await getPaneBox(page);
  console.log('flt-glass-pane box:', paneBox);

  const sessionCandidates = [];
  const profileCandidates = [];

  await page.goto(`${base.replace(/\/$/, '')}/session/s-001`, { waitUntil: 'load', timeout: 45_000 });
  await page.waitForTimeout(1500);
  for (const y of range(70, 140, 10)) {
    for (const x of range(200, 1700, 80)) {
      await clickFlutterAt(page, x, y);
      await page.waitForTimeout(350);
      const name = `session-y${y}-x${x}.png`;
      await page.screenshot({ path: path.join(CALIB, name) });
      sessionCandidates.push({ x, y, png: name });
    }
  }

  await page.goto(`${base.replace(/\/$/, '')}/profile`, { waitUntil: 'load', timeout: 45_000 });
  await page.waitForTimeout(1500);
  for (const y of range(100, 160, 10)) {
    for (const x of range(80, 600, 40)) {
      await clickFlutterAt(page, x, y);
      await page.waitForTimeout(350);
      const name = `profile-y${y}-x${x}.png`;
      await page.screenshot({ path: path.join(CALIB, name) });
      profileCandidates.push({ x, y, png: name });
    }
  }

  const existing = scenesConfig.coords ?? {};
  const suggested = {
    paneBox,
    generatedAt: new Date().toISOString(),
    note: 'Review PNGs manually — pick coords where tab ink indicator moved.',
    coords: {
      sessionTabBarY: existing.sessionTabBarY ?? 88,
      sessionOverviewX: existing.sessionOverviewX ?? 320,
      sessionLogisticsX: existing.sessionLogisticsX ?? 960,
      sessionQaX: existing.sessionQaX ?? 1580,
      profileTabBarY: existing.profileTabBarY ?? 128,
      profileYouX: existing.profileYouX ?? 120,
      profileProgressX: existing.profileProgressX ?? 260,
      profileSettingsX: existing.profileSettingsX ?? 410,
      mapButtonX: existing.mapButtonX ?? 820,
      mapButtonY: existing.mapButtonY ?? 820,
      shellAskFloX: existing.shellAskFloX ?? 720,
      shellMyPlanX: existing.shellMyPlanX ?? 1200,
      shellProfileX: existing.shellProfileX ?? 1680,
      shellTabY: existing.shellTabY ?? 1040,
      addToPlanX: existing.addToPlanX ?? 480,
      addToPlanY: existing.addToPlanY ?? 780,
    },
    sweepCount: { session: sessionCandidates.length, profile: profileCandidates.length },
  };

  await fs.writeFile(
    path.join(CALIB, 'suggested-coords.json'),
    JSON.stringify(suggested, null, 2),
  );

  await browser.close();
  console.log(`\nWrote ${sessionCandidates.length + profileCandidates.length} PNGs to output/calib/`);
  console.log('Suggested coords: output/calib/suggested-coords.json');
}

function range(start, end, step) {
  const out = [];
  for (let v = start; v <= end; v += step) out.push(v);
  return out;
}

async function getPaneBox(page) {
  const pane = page.locator('flt-glass-pane').first();
  return (await pane.boundingBox()) ?? null;
}

async function clickFlutterAt(page, x, y) {
  const pane = page.locator('flt-glass-pane').first();
  const box = await pane.boundingBox();
  if (box) {
    const localX = Math.max(1, x - box.x);
    const localY = Math.max(1, y - box.y);
    await pane.click({ position: { x: localX, y: localY }, force: true });
  } else {
    await page.mouse.move(x, y);
    await page.mouse.down();
    await page.mouse.up();
  }
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
