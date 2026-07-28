#!/usr/bin/env node
import { chromium } from 'playwright';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(HERE, '..', 'output', 'probe');
const SEED = path.join(HERE, '..', 'seed.js');
const BASE = process.env.FLO_DEMO_BASE_URL || 'http://localhost:8080';

async function clickCanvas(page, x, y) {
  const canvas = page.locator('flt-glass-pane >> canvas').first();
  await canvas.click({ position: { x, y }, force: true });
}

async function main() {
  await fs.mkdir(OUT, { recursive: true });
  const seed = await fs.readFile(SEED, 'utf8');
  const browser = await chromium.launch({ headless: true, args: ['--no-sandbox', '--use-gl=swiftshader'] });
  const ctx = await browser.newContext({ viewport: { width: 1920, height: 1080 } });
  await ctx.addInitScript(seed);
  const page = await ctx.newPage();

  // baseline overview
  await page.goto(`${BASE}/session/s-001`, { waitUntil: 'load', timeout: 45_000 });
  await page.waitForTimeout(2500);

  for (const x of [400, 640, 960, 1280, 1520, 1680]) {
    await page.goto(`${BASE}/session/s-001`, { waitUntil: 'load', timeout: 30_000 });
    await page.waitForTimeout(2000);
    await clickCanvas(page, x, 88);
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(OUT, `session-x${x}-y88.png`) });
    console.log(`session canvas click x=${x}`);
  }

  await page.goto(`${BASE}/session/s-001?focus=qa`, { waitUntil: 'load' });
  await page.waitForTimeout(2000);
  await page.screenshot({ path: path.join(OUT, 'session-focus-qa-baseline.png') });

  await page.goto(`${BASE}/profile`, { waitUntil: 'load', timeout: 45_000 });
  await page.waitForTimeout(2500);
  for (const x of [100, 180, 260, 340, 420, 500]) {
    await page.goto(`${BASE}/profile`, { waitUntil: 'load', timeout: 30_000 });
    await page.waitForTimeout(2000);
    await clickCanvas(page, x, 128);
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(OUT, `profile-x${x}-y128.png`) });
    console.log(`profile canvas click x=${x}`);
  }

  await browser.close();
  console.log('done', OUT);
}

main().catch(console.error);
