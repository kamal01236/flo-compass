#!/usr/bin/env node
// probe-tab-clicks.mjs — test which click strategy switches Flutter TabBar
import { chromium } from 'playwright';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(HERE, 'output', 'probe');
const SEED = path.join(HERE, '..', 'seed.js');
const OVERLAY = path.join(HERE, '..', 'overlay.js');
const BASE = process.env.FLO_DEMO_BASE_URL || 'http://localhost:8080';

async function main() {
  await fs.mkdir(OUT, { recursive: true });
  const seed = await fs.readFile(SEED, 'utf8');
  const overlay = await fs.readFile(OVERLAY, 'utf8');

  const browser = await chromium.launch({ headless: true, args: ['--no-sandbox', '--use-gl=swiftshader'] });
  const ctx = await browser.newContext({ viewport: { width: 1920, height: 1080 } });
  await ctx.addInitScript(seed);
  await ctx.addInitScript(overlay);
  const page = await ctx.newPage();

  await page.goto(`${BASE}/session/s-001`, { waitUntil: 'load', timeout: 45_000 });
  await page.waitForTimeout(2000);
  await page.screenshot({ path: path.join(OUT, '00-overview.png') });

  const domInfo = await page.evaluate(() => {
    const pane = document.querySelector('flt-glass-pane');
    const canvas = document.querySelector('flt-glass-pane canvas') || document.querySelector('canvas');
    const semantics = [...document.querySelectorAll('[role="tab"], [aria-label*="Q"], flt-semantics')].slice(0, 20).map((el) => ({
      tag: el.tagName,
      role: el.getAttribute('role'),
      label: el.getAttribute('aria-label') || el.textContent?.slice(0, 40),
      rect: el.getBoundingClientRect?.()?.toJSON?.(),
    }));
    return {
      pane: pane?.getBoundingClientRect?.()?.toJSON?.(),
      canvas: canvas?.getBoundingClientRect?.()?.toJSON?.(),
      semanticsCount: document.querySelectorAll('flt-semantics').length,
      semantics,
      bodyChildren: [...document.body.children].map((c) => c.tagName),
    };
  });
  console.log('DOM:', JSON.stringify(domInfo, null, 2));

  const strategies = [
    { name: 'pane-click-1580-88', fn: async () => {
      const pane = page.locator('flt-glass-pane').first();
      const box = await pane.boundingBox();
      await pane.click({ position: { x: 1580 - box.x, y: 88 - box.y }, force: true });
    }},
    { name: 'canvas-click-1580-88', fn: async () => {
      await page.locator('flt-glass-pane canvas').first().click({ position: { x: 1580, y: 88 }, force: true });
    }},
    { name: 'mouse-1580-88', fn: async () => {
      await page.mouse.move(1580, 88);
      await page.mouse.down();
      await page.mouse.up();
    }},
    { name: 'pointer-events-1580-88', fn: async () => {
      await page.evaluate(({ x, y }) => {
        const target = document.querySelector('flt-glass-pane canvas') || document.querySelector('flt-glass-pane') || document.body;
        const base = { bubbles: true, cancelable: true, view: window, clientX: x, clientY: y, screenX: x, screenY: y, pointerId: 1, pointerType: 'mouse', isPrimary: true, button: 0 };
        target.dispatchEvent(new PointerEvent('pointerdown', { ...base, buttons: 1, pressure: 0.5, width: 1, height: 1 }));
        target.dispatchEvent(new PointerEvent('pointerup', { ...base, buttons: 0, pressure: 0 }));
        target.dispatchEvent(new MouseEvent('click', { ...base, buttons: 0, detail: 1 }));
      }, { x: 1580, y: 88 });
    }},
    { name: 'focus-qa-url', fn: async () => {
      await page.goto(`${BASE}/session/s-001?focus=qa`, { waitUntil: 'load' });
      await page.waitForTimeout(1500);
    }},
    { name: 'keyboard-tabs', fn: async () => {
      // Tab to tab bar then arrow keys
      await page.keyboard.press('Tab');
      await page.waitForTimeout(200);
      for (let i = 0; i < 8; i++) {
        await page.keyboard.press('Tab');
        await page.waitForTimeout(100);
      }
      await page.keyboard.press('ArrowRight');
      await page.keyboard.press('ArrowRight');
      await page.waitForTimeout(500);
    }},
    { name: 'semantics-click', fn: async () => {
      const tabs = page.locator('[role="tab"]');
      const count = await tabs.count();
      console.log('  role=tab count:', count);
      if (count >= 3) await tabs.nth(2).click({ force: true });
    }},
  ];

  for (const s of strategies) {
    // reset to overview
    await page.goto(`${BASE}/session/s-001`, { waitUntil: 'load', timeout: 30_000 });
    await page.waitForTimeout(1500);
    try {
      await s.fn();
      await page.waitForTimeout(800);
      await page.screenshot({ path: path.join(OUT, `${s.name}.png`) });
      console.log(`OK ${s.name}`);
    } catch (err) {
      console.log(`FAIL ${s.name}:`, err.message);
    }
  }

  await browser.close();
  console.log('Screenshots in', OUT);
}

main().catch(console.error);
