#!/usr/bin/env node
// walkthrough.mjs — Playwright driver for the Flo Compass demo (v3.1.2).
//
// v3.1.2 tab click calibration:
//  * clickFlutterAt — real taps via flt-glass-pane bounding box, not raw viewport mouse
//  * coords block in scenes.json — resolveActionCoords() maps coord keys to x/y
//  * tabSettleMs after clickTab for Material tab animation
//  * mergeDwellScenes — session 2+3+4 and profile 8+9 run as one continuous visit
//
// v3.1.1 click/scroll fix: skip_nav, scrollFlutter, midNarration, tab retry

import { chromium } from 'playwright';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(HERE, 'output');
const DWELL_JSON = path.join(OUT, 'dwell.json');
const SCENES_JSON = path.join(HERE, 'scenes.json');
const TIMINGS_JSON = path.join(OUT, 'timings.json');
const SEED_JS = path.join(HERE, 'seed.js');
const OVERLAY_JS = path.join(HERE, 'overlay.js');
const OUTRO_HTML = path.join(HERE, 'scripts', 'outro.html');
const LOG_FILE = path.join(OUT, 'render.log');

const DEFAULT_BASE = 'http://localhost:8080';
const MIN_VIDEO_SEC = 115;
const MAX_VIDEO_SEC = 125;

async function main() {
  const dwell = JSON.parse(await fs.readFile(DWELL_JSON, 'utf8'));
  const scenesConfig = JSON.parse(await fs.readFile(SCENES_JSON, 'utf8'));
  const base = process.env.FLO_DEMO_BASE_URL || dwell.base || DEFAULT_BASE;
  const seed = await fs.readFile(SEED_JS, 'utf8');
  const overlay = await fs.readFile(OVERLAY_JS, 'utf8');

  await fs.mkdir(OUT, { recursive: true });
  await appendLog(`\n=== walkthrough v3.1.2 @ ${new Date().toISOString()}`);
  await appendLog(`base=${base}`);

  const coords = scenesConfig.coords ?? {};
  const tabSettleMs = scenesConfig.tabSettleMs ?? 600;

  const paintSettleMs = scenesConfig.paintSettleMs ?? 600;
  const cursorAnimMs = scenesConfig.cursorAnimMs ?? 650;
  const clickRippleMs = scenesConfig.clickRippleMs ?? 350;
  const postClickMs = scenesConfig.postClickMs ?? 150;
  const holdSceneMs = scenesConfig.holdBeforeSceneTransitionMs ?? 2000;
  const holdInternalMs = scenesConfig.internalActionSettleMs ?? 800;
  const companionResponseWaitMs = scenesConfig.companionResponseWaitMs ?? 1200;
  const bootUrl = scenesConfig.bootUrl ?? '/discover?day=Day%201&sort=soonest';
  const viewport = scenesConfig.viewport ?? { width: 1920, height: 1080 };

  const browser = await chromium.launch({
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-dev-shm-usage',
      '--use-gl=swiftshader',
      '--enable-webgl',
      '--hide-scrollbars',
      '--mute-audio',
    ],
  });

  const scenes = dwell.scenes.map((s, i) => ({
    ...s,
    cfg: scenesConfig.scenes[i],
  }));

  const allUrls = buildPrefetchList(scenes, bootUrl);
  await prefetchAll(browser, base, seed, overlay, allUrls, viewport);

  const context = await browser.newContext({
    viewport,
    deviceScaleFactor: 1,
    recordVideo: { dir: OUT, size: viewport },
  });
  await context.addInitScript(seed);
  await context.addInitScript(overlay);
  const page = await context.newPage();

  const recordStartMs = Date.now();
  const timings = { videoSec: 0, scenes: [] };

  await bootFlutterOnce(page, base, bootUrl);

  const budgets = {
    recordStartMs,
    paintSettleMs,
    cursorAnimMs,
    clickRippleMs,
    postClickMs,
    holdSceneMs,
    holdInternalMs,
    companionResponseWaitMs,
    tabSettleMs,
    coords,
    base,
  };

  try {
    for (let i = 0; i < scenes.length; ) {
      const scene = scenes[i];
      const mergeNs = scene.cfg?.mergeDwellScenes;
      if (Array.isArray(mergeNs) && mergeNs.length > 1) {
        const mergedScenes = mergeNs.map((n) => scenes.find((s) => s.n === n)).filter(Boolean);
        const sceneTimings = await runMergedScene(page, mergedScenes, budgets);
        for (const t of sceneTimings) timings.scenes.push(t);
        i += mergedScenes.length;
      } else {
        const sceneTiming = await runScene(page, scene, budgets);
        timings.scenes.push(sceneTiming);
        i += 1;
      }
    }

    const elapsed = (Date.now() - recordStartMs) / 1000;
    if (elapsed < MIN_VIDEO_SEC) {
      const holdSec = Math.min(MIN_VIDEO_SEC + 2 - elapsed, 12);
      if (holdSec > 0.5) {
        console.log(`  outro auto-hold ${holdSec.toFixed(1)}s (elapsed ${elapsed.toFixed(1)}s < ${MIN_VIDEO_SEC}s)`);
        await appendLog(`outro_hold sec=${holdSec.toFixed(2)}`);
        await page.waitForTimeout(holdSec * 1000);
      }
    } else if (elapsed > MAX_VIDEO_SEC) {
      console.warn(`  WARN elapsed ${elapsed.toFixed(1)}s > ${MAX_VIDEO_SEC}s`);
      await appendLog(`WARN elapsed_over_max sec=${elapsed.toFixed(2)}`);
    }
  } finally {
    await page.close();
    await context.close();
    await browser.close();
  }

  timings.videoSec = Number(((Date.now() - recordStartMs) / 1000).toFixed(3));
  await fs.writeFile(TIMINGS_JSON, JSON.stringify(timings, null, 2));

  const rawVideo = await findLatestVideo(OUT);
  const target = path.join(OUT, 'scene-recording.webm');
  if (rawVideo && rawVideo !== target) {
    try {
      await fs.rename(rawVideo, target);
    } catch {
      await fs.copyFile(rawVideo, target);
      await fs.unlink(rawVideo).catch(() => {});
    }
  }
  await appendLog(`webm=${path.relative(HERE, target)} totalSec=${timings.videoSec}`);
  console.log(`\nwrote: ${path.relative(HERE, target)}`);
  console.log(`wrote: ${path.relative(HERE, TIMINGS_JSON)}  (videoSec=${timings.videoSec})`);
}

function buildPrefetchList(scenes, bootUrl) {
  const urls = new Set([bootUrl]);
  for (const s of scenes) {
    if (s.url && s.url !== 'file:outro') urls.add(s.url);
    if (s.secondary) urls.add(s.secondary);
    for (const stage of s.cfg?.stages ?? []) {
      const ba = stage.beforeAction;
      if (ba?.kind === 'navigate' && ba.url) urls.add(ba.url);
      if (ba?.navigateAfter) urls.add(ba.navigateAfter);
      const aa = stage.afterAction;
      if (aa?.navigateAfter) urls.add(aa.navigateAfter);
    }
  }
  return [...urls];
}

async function prefetchAll(browser, base, seed, overlay, urls, viewport) {
  console.log('  phase A: prefetching routes');
  const ctx = await browser.newContext({ viewport });
  await ctx.addInitScript(seed);
  await ctx.addInitScript(overlay);
  const page = await ctx.newPage();
  try {
    await warmOnce(page, buildUrl(base, '/'));
    for (const url of urls) {
      if (url === 'file:outro') continue;
      try {
        const started = Date.now();
        await page.goto(buildUrl(base, url), { waitUntil: 'domcontentloaded', timeout: 45_000 });
        await page.waitForLoadState('networkidle', { timeout: 15_000 }).catch(() => {});
        await page.waitForTimeout(600);
        console.log(`    warm ${url} (${Date.now() - started}ms)`);
      } catch (err) {
        console.warn(`    warm ${url} failed: ${err.message}`);
      }
    }
  } finally {
    await page.close();
    await ctx.close();
  }
}

async function warmOnce(page, url) {
  try {
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60_000 });
    await page.waitForLoadState('networkidle', { timeout: 30_000 }).catch(() => {});
    await page.waitForTimeout(1200);
  } catch (err) {
    console.warn('  warmup failed:', err.message);
  }
}

async function runMergedScene(page, mergedScenes, budgets) {
  const primary = mergedScenes[0];
  const cfg = primary.cfg;
  const stages = cfg?.stages ?? [];
  const stageNarrSecs = splitNarrationByWeights(
    mergedScenes.map((s) => s.narrationSec),
    stages.length,
    cfg?.stageNarrationWeights,
  );

  console.log(
    `  merged scenes ${mergedScenes.map((s) => s.n).join('+')}: ` +
    `${stages.length} stage(s), ${stageNarrSecs.reduce((a, b) => a + b, 0).toFixed(2)}s`,
  );

  const isOutro = primary.url === 'file:outro';
  const sceneTimings = mergedScenes.map((s) => ({
    n: s.n,
    url: s.url,
    narrationSec: Number(s.narrationSec.toFixed(3)),
    stages: [],
  }));

  // Navigate once to the shared URL
  if (!isOutro && primary.url !== 'file:outro') {
    await navigate(page, buildUrl(budgets.base, primary.url));
  }

  let stageIdx = 0;
  for (let si = 0; si < stages.length; si++) {
    const stage = stages[si];
    const stageNarrSec = stageNarrSecs[si];
    const dwellIdx = cfg?.stageDwellScene?.[si] ?? findDwellIndexForStage(mergedScenes, si, stages.length);
    const dwellScene = mergedScenes[Math.min(dwellIdx, mergedScenes.length - 1)];
    const label = `scene=${dwellScene.n} mergedStage=${si + 1}/${stages.length}`;

    const stageTiming = await runStage(page, {
      label,
      stage,
      stageIndex: si,
      isOutro,
      narrationSec: stageNarrSec,
      specialWait: si === stages.length - 1 ? (cfg?.specialWait ?? null) : null,
      skipInitialNav: true,
      ...budgets,
    });

    sceneTimings[dwellIdx].stages.push(stageTiming);
    stageIdx += 1;
  }

  return sceneTimings;
}

function findDwellIndexForStage(mergedScenes, stageIndex, totalStages) {
  const perScene = Math.ceil(totalStages / mergedScenes.length);
  return Math.min(mergedScenes.length - 1, Math.floor(stageIndex / perScene));
}

function splitNarrationByWeights(narrationSecs, stageCount, weights) {
  if (stageCount <= 0) return [];
  if (stageCount === 1) return [narrationSecs.reduce((a, b) => a + b, 0)];
  if (Array.isArray(weights) && weights.length === stageCount) {
    const total = weights.reduce((a, b) => a + b, 0);
    const sumNarr = narrationSecs.reduce((a, b) => a + b, 0);
    return weights.map((w) => (w / total) * sumNarr);
  }
  const sumNarr = narrationSecs.reduce((a, b) => a + b, 0);
  const each = sumNarr / stageCount;
  return Array.from({ length: stageCount }, () => each);
}

async function runScene(page, scene, budgets) {
  const cfg = scene.cfg;
  const stages = cfg?.stages ?? [{
    beforeAction: { kind: 'none' },
    hoverAt: cfg?.highlight ?? null,
    afterAction: cfg?.nextClick
      ? { kind: 'sceneTransition', ...cfg.nextClick, holdMs: budgets.holdSceneMs }
      : { kind: 'none' },
  }];

  const stageNarrationSecs = splitNarration(scene.narrationSec, stages.length);
  const isOutro = scene.url === 'file:outro';
  const sceneTiming = {
    n: scene.n,
    url: scene.url,
    narrationSec: Number(scene.narrationSec.toFixed(3)),
    stages: [],
  };

  console.log(`  scene ${scene.n}: ${scene.url} (${scene.narrationSec.toFixed(2)}s, ${stages.length} stage(s))`);

  for (let i = 0; i < stages.length; i++) {
    const stage = stages[i];
    const stageNarrSec = stageNarrationSecs[i];
    const label = `scene=${scene.n} stage=${i + 1}/${stages.length}`;
    let navigateSkipped = false;

    if (i === 0 && !isOutro && scene.url !== 'file:outro') {
      const ba = stage.beforeAction;
      if (!ba || ba.kind === 'none') {
        const result = await navigate(page, buildUrl(budgets.base, scene.url));
        navigateSkipped = result.skipped;
      }

      const expectIdx = cfg?.expectTabIndex ?? 0;
      const fallback = resolveActionCoords(cfg?.tabClickIfStale, budgets.coords);
      if (navigateSkipped && expectIdx > 0 && fallback) {
        await appendLog(
          `${label} tab_click_retry x=${fallback.x} y=${fallback.y} tab=${expectIdx}`,
        );
        try {
          await clickFlutterAt(page, fallback.x, fallback.y, { hideCursor: true });
          await page.waitForTimeout(budgets.tabSettleMs ?? 600);
        } catch { /* no-op */ }
      }
    }

    const stageTiming = await runStage(page, {
      label,
      stage,
      stageIndex: i,
      isOutro,
      narrationSec: stageNarrSec,
      specialWait: i === stages.length - 1 ? (cfg?.specialWait ?? null) : null,
      ...budgets,
    });
    sceneTiming.stages.push(stageTiming);
  }

  return sceneTiming;
}

function splitNarration(totalSec, count) {
  if (count <= 1) return [totalSec];
  const each = totalSec / count;
  return Array.from({ length: count }, () => each);
}

async function runStage(page, opts) {
  const {
    label, stage, narrationSec, specialWait, recordStartMs,
    paintSettleMs, cursorAnimMs, clickRippleMs, postClickMs,
    holdSceneMs, holdInternalMs, companionResponseWaitMs, tabSettleMs,
    coords, base, isOutro, skipInitialNav,
  } = opts;

  const stageStart = Date.now();

  try {
    await page.evaluate(() => window.__floDemo?.clearLabel?.());
  } catch { /* no-op */ }

  await performBeforeAction(page, base, stage.beforeAction, paintSettleMs, { coords, tabSettleMs });

  if (isOutro) {
    await navigate(page, buildUrl(base, 'file:outro'));
    await page.waitForTimeout(paintSettleMs);
    const audioStart = Number(((Date.now() - recordStartMs) / 1000).toFixed(3));
    await page.waitForTimeout(Math.max(0, narrationSec * 1000));
    await appendLog(`${label} outro audioStart=${audioStart.toFixed(3)}`);
    return { audioStartAtVideoSec: audioStart, narrationSec: Number(narrationSec.toFixed(3)) };
  }

  await waitForPaint(page, paintSettleMs);
  await ensureOverlayReady(page);
  await page.evaluate(() => window.__floDemo?.showCursor?.());

  if (stage.hoverAt) {
    const h = resolveActionCoords(stage.hoverAt, opts.coords ?? {});
    if (h.x != null && h.y != null) {
      await page.evaluate(
        ({ x, y, ms, lbl }) => window.__floDemo?.moveCursorTo?.({ x, y, durationMs: ms, label: lbl }),
        { x: h.x, y: h.y, ms: 400, lbl: h.label ?? '' },
      );
      await page.waitForTimeout(200);
    }
  }

  const audioStartAtVideoSec = Number(((Date.now() - recordStartMs) / 1000).toFixed(3));
  await appendLog(`${label} audioStartAtVideoSec=${audioStartAtVideoSec.toFixed(3)}`);

  let extraWaitMs = 0;
  if (specialWait === 'companion-response') {
    extraWaitMs = companionResponseWaitMs;
  }

  const totalWaitMs = Math.max(0, narrationSec * 1000 + extraWaitMs);
  const midNarrations = normalizeMidNarrations(stage.midNarration);
  if (midNarrations.length > 0 && totalWaitMs > 0) {
    await waitWithMidNarration(page, base, midNarrations, totalWaitMs, {
      paintSettleMs, holdInternalMs, tabSettleMs, coords, label,
    });
  } else {
    await page.waitForTimeout(totalWaitMs);
  }

  await performAfterAction(page, base, stage.afterAction, {
    cursorAnimMs, clickRippleMs, postClickMs, holdSceneMs, holdInternalMs,
    tabSettleMs, coords,
  });

  await appendLog(`${label} elapsed=${((Date.now() - stageStart) / 1000).toFixed(2)}s`);
  return {
    audioStartAtVideoSec,
    narrationSec: Number(narrationSec.toFixed(3)),
  };
}

function normalizeMidNarrations(field) {
  if (!field) return [];
  const list = Array.isArray(field) ? field : [field];
  return list.filter((a) => a && a.kind && a.kind !== 'none');
}

async function waitWithMidNarration(page, base, actions, totalMs, opts) {
  const { paintSettleMs, holdInternalMs, tabSettleMs, coords, label } = opts;
  const sorted = [...actions].sort(
    (a, b) => (a.atRatio ?? 0.5) - (b.atRatio ?? 0.5),
  );
  let elapsed = 0;

  for (const action of sorted) {
    const ratio = clamp01(action.atRatio ?? 0.5);
    const targetMs = Math.round(totalMs * ratio);
    const waitChunk = Math.max(0, targetMs - elapsed);
    if (waitChunk > 0) {
      await page.waitForTimeout(waitChunk);
      elapsed += waitChunk;
    }
    await appendLog(
      `${label} midNarration atRatio=${ratio.toFixed(2)} kind=${action.kind}`,
    );
    const before = Date.now();
    await performMidNarrationAction(page, base, action, {
      paintSettleMs, holdInternalMs, tabSettleMs, coords,
    });
    elapsed += (Date.now() - before);
  }

  const remaining = Math.max(0, totalMs - elapsed);
  if (remaining > 0) await page.waitForTimeout(remaining);
}

function clamp01(v) {
  if (!Number.isFinite(v)) return 0.5;
  return Math.max(0, Math.min(1, v));
}

async function performMidNarrationAction(page, base, action, ctx) {
  const { paintSettleMs, holdInternalMs, tabSettleMs, coords } = ctx;
  const resolved = resolveActionCoords(action, coords);
  switch (resolved.kind) {
    case 'scroll':
      await scrollFlutter(page, resolved);
      break;
    case 'selectTabUrl':
      await selectTabViaUrl(page, base, resolved, { paintSettleMs, tabSettleMs, coords });
      break;
    case 'clickAt':
    case 'clickTab':
      await clickWithRipple(page, resolved, {
        holdMs: resolved.holdMs ?? 0,
        real: Boolean(resolved.real),
        tabIndex: resolved.tabIndex,
        holdInternalMs,
        tabSettleMs,
        coords,
      });
      if (resolved.navigateAfter) {
        await navigate(page, buildUrl(base, resolved.navigateAfter));
        await waitForPaint(page, paintSettleMs);
      }
      break;
    default:
      break;
  }
}

async function performBeforeAction(page, base, action, paintSettleMs, ctx = {}) {
  if (!action || action.kind === 'none') return;
  const { coords = {}, tabSettleMs = 600 } = ctx;
  const resolved = resolveActionCoords(action, coords);
  await appendLog(`beforeAction kind=${resolved.kind}`);

  switch (resolved.kind) {
    case 'navigate':
      if (resolved.forceReload) {
        await page.goto(buildUrl(base, resolved.url), { waitUntil: 'load', timeout: 30_000 });
        await page.waitForTimeout(paintSettleMs);
      } else {
        await navigate(page, buildUrl(base, resolved.url));
        await waitForPaint(page, paintSettleMs);
      }
      break;
    case 'scroll':
      await scrollFlutter(page, resolved);
      break;
    case 'selectTabUrl':
      await selectTabViaUrl(page, base, resolved, { paintSettleMs, tabSettleMs, coords });
      break;
    case 'clickAt':
    case 'clickTab':
      await clickWithRipple(page, resolved, {
        holdMs: resolved.holdMs ?? 800,
        real: true,
        tabSettleMs,
        coords,
      });
      if (resolved.navigateAfter) {
        await navigate(page, buildUrl(base, resolved.navigateAfter));
        await waitForPaint(page, paintSettleMs);
      }
      break;
    default:
      break;
  }
}

async function performAfterAction(page, base, action, anim) {
  if (!action || action.kind === 'none') return;

  const {
    cursorAnimMs, clickRippleMs, postClickMs, holdSceneMs, holdInternalMs,
    tabSettleMs, coords,
  } = anim;
  const resolved = resolveActionCoords(action, coords);

  switch (resolved.kind) {
    case 'scroll':
      await scrollFlutter(page, resolved);
      return;
    case 'selectTabUrl':
      await selectTabViaUrl(page, base, resolved, {
        paintSettleMs: 600, tabSettleMs, coords, holdMs: resolved.holdMs ?? 0,
        cursorAnimMs, clickRippleMs,
      });
      return;
    case 'clickAt':
    case 'clickTab':
    case 'sceneTransition': {
      const holdMs = resolved.holdMs
        ?? (resolved.kind === 'sceneTransition' ? holdSceneMs : holdInternalMs);
      await page.waitForTimeout(holdMs);
      await clickWithRipple(page, resolved, {
        holdMs: 0,
        real: Boolean(resolved.real),
        cursorAnimMs,
        clickRippleMs,
        postClickMs,
        tabIndex: resolved.tabIndex,
        holdInternalMs,
        tabSettleMs,
        coords,
      });
      if (resolved.navigateAfter) {
        if (resolved.forceReload) {
          await page.goto(buildUrl(base, resolved.navigateAfter), { waitUntil: 'load', timeout: 30_000 });
        } else {
          await navigate(page, buildUrl(base, resolved.navigateAfter));
        }
        await waitForPaint(page, 600);
      }
      return;
    }
    default:
      break;
  }
}

async function clickWithRipple(page, action, opts) {
  const resolved = resolveActionCoords(action, opts.coords ?? {});
  const { x = 960, y = 540, label = '' } = resolved;
  const {
    holdMs = 0, real = false,
    cursorAnimMs = 650, clickRippleMs = 350, postClickMs = 150,
    tabIndex, holdInternalMs = 500, tabSettleMs = 600,
  } = opts;

  if (holdMs > 0) await page.waitForTimeout(holdMs);

  await page.evaluate(
    ({ cx, cy, ms, lbl }) => window.__floDemo?.moveCursorTo?.({ x: cx, y: cy, durationMs: ms, label: lbl }),
    { cx: x, cy: y, ms: cursorAnimMs, lbl: label },
  );
  await page.waitForTimeout(cursorAnimMs);
  await page.evaluate(
    ({ cx, cy, ms }) => window.__floDemo?.clickRipple?.({ x: cx, y: cy, durationMs: ms }),
    { cx: x, cy: y, ms: clickRippleMs },
  );
  await page.waitForTimeout(clickRippleMs);

  if (real) {
    await clickFlutterAt(page, x, y, { hideCursor: true });
    await page.waitForTimeout(postClickMs);
    await appendLog(`canvas_click x=${x} y=${y} label=${label}`);

    const shouldRetry = (resolved.kind === 'clickTab')
      && (typeof tabIndex === 'number' ? tabIndex > 0 : true)
      && (resolved.retry !== false);
    if (shouldRetry) {
      await page.waitForTimeout(200);
      const retryY = y + (resolved.retryOffsetY ?? 2);
      try {
        await clickFlutterAt(page, x, retryY, { hideCursor: true });
        await page.waitForTimeout(postClickMs);
        await appendLog(`canvas_click_retry x=${x} y=${retryY} label=${label}`);
      } catch { /* no-op */ }
    }

    if (resolved.kind === 'clickTab' && tabSettleMs > 0) {
      await page.waitForTimeout(tabSettleMs);
      await appendLog(`tab_settle ms=${tabSettleMs}`);
    }
  }
}

function resolveActionCoords(action, coords) {
  if (!action) return action;
  const out = { ...action };
  if (action.coord && coords) {
    const key = action.coord;
    const tabYKeys = {
      sessionOverview: 'sessionTabBarY',
      sessionLogistics: 'sessionTabBarY',
      sessionQa: 'sessionTabBarY',
      profileYou: 'profileTabBarY',
      profileProgress: 'profileTabBarY',
      profileSettings: 'profileTabBarY',
      shellAskFlo: 'shellTabY',
      shellMyPlan: 'shellTabY',
      shellProfile: 'shellTabY',
    };
    const xMap = {
      sessionOverview: 'sessionOverviewX',
      sessionLogistics: 'sessionLogisticsX',
      sessionQa: 'sessionQaX',
      profileYou: 'profileYouX',
      profileProgress: 'profileProgressX',
      profileSettings: 'profileSettingsX',
      shellAskFlo: 'shellAskFloX',
      shellMyPlan: 'shellMyPlanX',
      shellProfile: 'shellProfileX',
      mapButton: 'mapButtonX',
      addToPlan: 'addToPlanX',
    };
    const xKey = xMap[key] ?? `${key}X`;
    const yKey = key === 'mapButton' ? 'mapButtonY'
      : key === 'addToPlan' ? 'addToPlanY'
      : tabYKeys[key] ?? `${key}Y`;
    if (coords[xKey] != null) out.x = coords[xKey];
    if (coords[yKey] != null) out.y = coords[yKey];
  }
  return out;
}

async function selectTabViaUrl(page, base, action, ctx) {
  const {
    paintSettleMs = 300, tabSettleMs = 450, coords = {},
    holdMs = 0, cursorAnimMs = 350, clickRippleMs = 200,
  } = ctx;
  const resolved = resolveActionCoords(action, coords);
  const { x = 960, y = 88, label = '', url } = resolved;
  if (!url) throw new Error('selectTabUrl requires url');

  if (holdMs > 0) await page.waitForTimeout(holdMs);

  await page.evaluate(
    ({ cx, cy, ms, lbl }) => window.__floDemo?.moveCursorTo?.({ x: cx, y: cy, durationMs: ms, label: lbl }),
    { cx: x, cy: y, ms: cursorAnimMs, lbl: label },
  );
  await page.waitForTimeout(cursorAnimMs);
  await page.evaluate(
    ({ cx, cy, ms }) => window.__floDemo?.clickRipple?.({ x: cx, y: cy, durationMs: ms }),
    { cx: x, cy: y, ms: clickRippleMs },
  );
  await page.waitForTimeout(clickRippleMs);

  await page.goto(buildUrl(base, url), { waitUntil: 'load', timeout: 30_000 });
  await waitForPaint(page, paintSettleMs);
  if (tabSettleMs > 0) await page.waitForTimeout(tabSettleMs);
  await appendLog(`selectTabUrl url=${url} label=${label}`);
}

async function clickFlutterAt(page, x, y, opts = {}) {
  const { hideCursor = false } = opts;
  const debug = process.env.FLO_DEMO_DEBUG === '1';

  if (hideCursor) {
    try {
      await page.evaluate(() => window.__floDemo?.hideCursor?.());
    } catch { /* no-op */ }
  }

  const canvas = page.locator('flt-glass-pane >> canvas').first();
  const hasCanvas = await canvas.count() > 0;
  if (hasCanvas) {
    await canvas.click({ position: { x, y }, force: true });
    if (debug) await appendLog(`debug canvas_click x=${x} y=${y}`);
  } else {
    await page.mouse.move(x, y);
    await page.mouse.down();
    await page.mouse.up();
    if (debug) await appendLog(`debug fallback_mouse x=${x} y=${y}`);
  }

  if (hideCursor) {
    try {
      await page.evaluate(() => window.__floDemo?.showCursor?.());
    } catch { /* no-op */ }
  }
}

async function ensureOverlayReady(page) {
  try {
    await page.waitForFunction(
      () => window.__floDemo && window.__floDemo.__ready === true,
      null,
      { timeout: 1200 },
    );
  } catch {
    try {
      await page.addScriptTag({ path: OVERLAY_JS });
    } catch { /* no-op */ }
  }
}

async function waitForPaint(page, paintSettleMs) {
  await page.waitForLoadState('load', { timeout: 3000 }).catch(() => {});
  await page.waitForTimeout(paintSettleMs);
}

// Compare current page URL to target URL by pathname+search+hash on the same
// host so we don't fire a redundant history.pushState — that rebuilds the
// route and resets TabController state (bug fix for scenes 3/4/9).
function isSameLocation(currentUrl, targetUrl) {
  try {
    const cur = new URL(currentUrl);
    const tgt = new URL(targetUrl);
    if (cur.host !== tgt.host) return false;
    const curPath = cur.pathname + cur.search + cur.hash;
    const tgtPath = tgt.pathname + tgt.search + tgt.hash;
    return curPath === tgtPath;
  } catch {
    return false;
  }
}

async function navigate(page, url) {
  if (url.startsWith('file://') || url.startsWith('data:')) {
    await page.goto(url, { waitUntil: 'load', timeout: 8_000 }).catch(() => {});
    return { skipped: false };
  }
  if (isSameLocation(page.url(), url)) {
    await appendLog(`skip_nav url=${url}`);
    return { skipped: true };
  }
  try {
    await page.evaluate((u) => {
      const target = new URL(u, window.location.href);
      const path = target.pathname + target.search + target.hash;
      window.history.pushState(null, '', path);
      window.dispatchEvent(new PopStateEvent('popstate'));
    }, url);
  } catch {
    await page.goto(url, { waitUntil: 'commit', timeout: 12_000 }).catch(() => {});
  }
  return { skipped: false };
}

// Flutter web ignores window.scrollTo — the app paints inside a fixed <canvas>
// and reads pointer wheel events instead. scrollFlutter parks the mouse over
// the canvas centre, ticks wheel events in small steps so easing feels
// natural, and optionally falls back to PageDown keys if a scene refused to
// scroll (last-resort escape hatch called out in the click/scroll fix plan).
async function scrollFlutter(page, opts = {}) {
  const dy = opts.dy ?? 600;
  const cx = opts.cx ?? 960;
  const cy = opts.cy ?? 540;
  const stepCount = Math.max(1, opts.steps ?? Math.max(4, Math.round(Math.abs(dy) / 140)));
  const perStep = dy / stepCount;
  const settleMs = opts.settleMs ?? 400;
  const stepDelayMs = opts.stepDelayMs ?? 55;
  const pageDownFallback = Boolean(opts.pageDownFallback);
  const pageDownCount = opts.pageDownCount ?? 2;

  try {
    await page.mouse.move(cx, cy);
    await page.waitForTimeout(40);
    for (let i = 0; i < stepCount; i++) {
      await page.mouse.wheel(0, perStep);
      await page.waitForTimeout(stepDelayMs);
    }
  } catch {
    try {
      await page.evaluate((d) => window.scrollBy(0, d), dy);
    } catch { /* no-op */ }
  }

  if (pageDownFallback) {
    for (let i = 0; i < pageDownCount; i++) {
      try {
        await page.keyboard.press('PageDown');
      } catch { /* no-op */ }
      await page.waitForTimeout(140);
    }
  }

  await page.waitForTimeout(settleMs);
  await appendLog(
    `scroll dy=${dy} steps=${stepCount} settle=${settleMs}` +
    (pageDownFallback ? ` pageDown=${pageDownCount}` : ''),
  );
}

async function bootFlutterOnce(page, base, bootUrl) {
  console.log(`  booting Flutter -> ${bootUrl}`);
  const started = Date.now();
  try {
    await page.goto(buildUrl(base, bootUrl), { waitUntil: 'load', timeout: 30_000 });
    await page.waitForLoadState('load', { timeout: 5_000 }).catch(() => {});
  } catch (err) {
    console.warn(`  boot failed: ${err.message}`);
  }
  await page.waitForTimeout(2000);
  console.log(`  boot ok (${Date.now() - started}ms)`);
  await appendLog(`boot_url=${bootUrl} ms=${Date.now() - started}`);
}

function buildUrl(base, target) {
  if (target === 'file:outro') return pathToFileURL(OUTRO_HTML).href;
  if (target.startsWith('http') || target.startsWith('file://')) return target;
  return base.replace(/\/$/, '') + target;
}

async function findLatestVideo(dir) {
  const entries = await fs.readdir(dir).catch(() => []);
  const webms = entries.filter((f) => f.endsWith('.webm'));
  if (webms.length === 0) return null;
  const stats = await Promise.all(
    webms.map(async (f) => ({ f, mtime: (await fs.stat(path.join(dir, f))).mtimeMs })),
  );
  stats.sort((a, b) => b.mtime - a.mtime);
  return path.join(dir, stats[0].f);
}

async function appendLog(line) {
  try {
    await fs.mkdir(OUT, { recursive: true });
    await fs.appendFile(LOG_FILE, line + '\n');
  } catch { /* best-effort */ }
}

main().catch(async (err) => {
  console.error(err);
  await appendLog(`ERROR ${err.message}`);
  process.exitCode = 1;
});
