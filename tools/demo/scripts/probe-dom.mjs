#!/usr/bin/env node
import { chromium } from 'playwright';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(HERE, '..', 'output', 'probe');
const SEED = path.join(HERE, '..', 'seed.js');
const BASE = process.env.FLO_DEMO_BASE_URL || 'http://localhost:8080';

async function main() {
  await fs.mkdir(OUT, { recursive: true });
  const seed = await fs.readFile(SEED, 'utf8');
  const browser = await chromium.launch({ headless: true, args: ['--no-sandbox', '--use-gl=swiftshader'] });
  const ctx = await browser.newContext({ viewport: { width: 1920, height: 1080 } });
  await ctx.addInitScript(seed);
  const page = await ctx.newPage();
  await page.goto(`${BASE}/session/s-001`, { waitUntil: 'load', timeout: 45_000 });
  await page.waitForTimeout(3000);

  const info = await page.evaluate(() => {
    function dump(el, depth = 0) {
      if (!el || depth > 6) return null;
      const r = el.getBoundingClientRect();
      const o = {
        tag: el.tagName,
        w: Math.round(r.width),
        h: Math.round(r.height),
        x: Math.round(r.x),
        y: Math.round(r.y),
      };
      if (el.shadowRoot) {
        o.shadow = [...el.shadowRoot.children].map((c) => dump(c, depth + 1)).filter(Boolean);
      } else if (el.children?.length && depth < 4) {
        o.children = [...el.children].slice(0, 8).map((c) => dump(c, depth + 1)).filter(Boolean);
      }
      return o;
    }
    const fv = document.querySelector('flutter-view') || document.querySelector('FLUTTER-VIEW');
    return {
      flutterView: dump(fv),
      glassPane: dump(document.querySelector('flt-glass-pane')),
      canvases: [...document.querySelectorAll('canvas')].map((c) => ({
        w: c.width, h: c.height, css: c.getBoundingClientRect?.()?.toJSON?.(),
      })),
    };
  });
  console.log(JSON.stringify(info, null, 2));

  // Try click on flutter-view via mouse at Q&A tab coords
  await page.mouse.click(1580, 88);
  await page.waitForTimeout(800);
  await page.screenshot({ path: path.join(OUT, 'after-mouse-qa.png') });

  await page.goto(`${BASE}/session/s-001?focus=qa`, { waitUntil: 'load' });
  await page.waitForTimeout(1500);
  await page.screenshot({ path: path.join(OUT, 'focus-qa.png') });

  await browser.close();
}

main().catch(console.error);
