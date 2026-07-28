#!/usr/bin/env node
// run-tts.mjs - per-scene edge-tts render (v3.1 companion tour).
//
// v3.1: scenes.json drives URLs; one mp3 per [SCENE N] block. Multi-stage
// scenes (1, 4, 6, 9) are split downstream by build-audio-track.mjs using
// per-stage audioStartAtVideoSec from walkthrough timings.json.

import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawn } from 'node:child_process';

import { EdgeTTS } from 'node-edge-tts';
import ffprobeStatic from 'ffprobe-static';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, '..');
const OUT = path.join(ROOT, 'output');
const NARRATION_TXT = path.join(ROOT, 'narration.txt');
const SCENES_JSON = path.join(ROOT, 'scenes.json');
const DWELL_JSON = path.join(OUT, 'dwell.json');
const CAPTIONS_SRT = path.join(OUT, 'captions.srt');
const LOG_FILE = path.join(OUT, 'render.log');

const VOICE = process.env.FLO_TTS_VOICE || 'en-IN-PrabhatNeural';
// v3 default is +40%: at +10% the 241-word script measured 116s and blew
// past the 125s ceiling once paint/cursor budget was added. +40% lands the
// per-scene renders at 92-95s total narration, and the video at ~120s.
const RATE = process.env.FLO_TTS_RATE || '+58%';
const PAD = Number.parseFloat(process.env.FLO_TTS_PAD ?? '0.3');
const BASE_URL = process.env.FLO_DEMO_BASE_URL || 'http://localhost:8080';

const FFPROBE = ffprobeStatic.path;

async function main() {
  await fs.mkdir(OUT, { recursive: true });
  await appendLog(`\n=== TTS render @ ${new Date().toISOString()} ===`);
  await appendLog(`voice=${VOICE} rate=${RATE} pad=${PAD} base=${BASE_URL}`);

  const raw = await fs.readFile(NARRATION_TXT, 'utf8');
  const scenes = parseScenes(raw);
  if (scenes.length !== 10) {
    throw new Error(`Expected 10 [SCENE N] markers, found ${scenes.length}.`);
  }

  const scenesConfig = JSON.parse(await fs.readFile(SCENES_JSON, 'utf8'));
  if (!Array.isArray(scenesConfig.scenes) || scenesConfig.scenes.length !== 10) {
    throw new Error(`scenes.json must define 10 scenes; found ${scenesConfig.scenes?.length ?? 0}`);
  }

  const tts = new EdgeTTS({
    voice: VOICE,
    lang: VOICE.split('-').slice(0, 2).join('-'),
    outputFormat: 'audio-24khz-48kbitrate-mono-mp3',
    rate: RATE,
    pitch: 'default',
    volume: 'default',
    timeout: 60000,
  });

  for (const scene of scenes) {
    const audioPath = path.join(OUT, `scene-${String(scene.n).padStart(2, '0')}.mp3`);
    process.stdout.write(`  scene ${scene.n} (${scene.text.split(/\s+/).length} words) ... `);
    await renderScene(tts, scene.text, audioPath);
    scene.duration = await probeDuration(audioPath);
    process.stdout.write(`${scene.duration.toFixed(2)}s\n`);
  }

  const totalNarration = scenes.reduce((a, s) => a + s.duration, 0);

  let cursor = 0;
  const dwell = scenes.map((s, i) => {
    const cfg = scenesConfig.scenes[i];
    if (!cfg || cfg.n !== s.n) {
      throw new Error(`scenes.json scene ${i + 1} (n=${cfg?.n}) does not match narration scene ${s.n}`);
    }
    const dwellSec = s.duration + PAD;
    const entry = {
      n: s.n,
      url: cfg.url,
      secondary: cfg.secondary || null,
      narrationSec: Number(s.duration.toFixed(3)),
      dwellSec: Number(dwellSec.toFixed(3)),
      startSec: Number(cursor.toFixed(3)),
      text: s.text,
    };
    cursor += dwellSec;
    return entry;
  });

  const totalDwell = Number(cursor.toFixed(3));
  const payload = {
    voice: VOICE,
    rate: RATE,
    base: BASE_URL,
    totalNarrationSec: Number(totalNarration.toFixed(3)),
    totalDwellSec: totalDwell,
    padSec: PAD,
    scenes: dwell,
  };
  await fs.writeFile(DWELL_JSON, JSON.stringify(payload, null, 2));
  await writeCaptions(dwell, CAPTIONS_SRT);

  console.log(`\n  total narration: ${totalNarration.toFixed(2)}s`);
  console.log(`  total dwell:     ${totalDwell.toFixed(2)}s (pre-gapped; final video ~+30s from paint/cursor budget)`);
  console.log(`  wrote: ${path.relative(ROOT, DWELL_JSON)}`);
  console.log(`  wrote: ${path.relative(ROOT, CAPTIONS_SRT)}`);
  console.log(`  wrote: 10 x scene-NN.mp3 (build-audio-track.mjs assembles the gapped narration.mp3)`);
  await appendLog(`total_narration=${totalNarration.toFixed(3)}s total_dwell=${totalDwell.toFixed(3)}s`);
}

function parseScenes(raw) {
  const scenes = [];
  const lines = raw.split(/\r?\n/);
  let current = null;
  const marker = /^\[SCENE\s+(\d+)\]\s*$/i;
  for (const line of lines) {
    const m = marker.exec(line);
    if (m) {
      if (current) scenes.push(current);
      current = { n: Number(m[1]), text: '' };
      continue;
    }
    if (!current) continue;
    current.text += (current.text ? ' ' : '') + line.trim();
  }
  if (current) scenes.push(current);
  return scenes
    .map((s) => ({ ...s, text: s.text.replace(/\s+/g, ' ').trim() }))
    .filter((s) => s.text.length > 0);
}

async function renderScene(tts, text, outPath) {
  await tts.ttsPromise(text, outPath);
  await fs.access(outPath);
}

function probeDuration(mp3Path) {
  return new Promise((resolve, reject) => {
    const p = spawn(FFPROBE, [
      '-v', 'error',
      '-show_entries', 'format=duration',
      '-of', 'default=noprint_wrappers=1:nokey=1',
      mp3Path,
    ]);
    let out = '';
    let err = '';
    p.stdout.on('data', (b) => (out += b.toString()));
    p.stderr.on('data', (b) => (err += b.toString()));
    p.on('close', (code) => {
      if (code !== 0) return reject(new Error(`ffprobe exit ${code}: ${err}`));
      const n = Number.parseFloat(out.trim());
      if (Number.isNaN(n)) return reject(new Error(`ffprobe parse failed: ${out}`));
      resolve(n);
    });
  });
}

async function writeCaptions(scenes, outPath) {
  // Initial captions are timed against the pre-gapped narration timeline
  // (startSec = sum of prior narrationSec + PAD). build-audio-track.mjs will
  // re-emit this file offset by the per-scene paint/cursor budget.
  const cues = [];
  let cueIndex = 1;
  for (const scene of scenes) {
    const sentences = splitSentences(scene.text);
    if (sentences.length === 0) continue;
    const budget = scene.narrationSec;
    const totalChars = sentences.reduce((a, s) => a + s.length, 0);
    let localCursor = scene.startSec;
    for (let i = 0; i < sentences.length; i++) {
      const sentence = sentences[i];
      const share = sentence.length / Math.max(totalChars, 1);
      const isLast = i === sentences.length - 1;
      const naturalEnd = isLast
        ? scene.startSec + scene.narrationSec
        : localCursor + budget * share;
      const start = localCursor;
      let end = naturalEnd;
      if (end - start < 0.5) end = start + 0.5;
      cues.push({ n: cueIndex++, start, end, text: sentence, sceneN: scene.n });
      localCursor = end;
    }
  }
  const body = cues.map((c) => {
    return `${c.n}\n${formatSrt(c.start)} --> ${formatSrt(c.end)}\n${c.text}`;
  }).join('\n\n') + '\n';
  await fs.writeFile(outPath, body);
}

function splitSentences(text) {
  return text
    .replace(/\s+/g, ' ')
    .split(/(?<=[.!?])\s+(?=[A-Z])/)
    .map((s) => s.trim())
    .filter(Boolean);
}

function formatSrt(seconds) {
  const clamp = Math.max(0, seconds);
  const h = Math.floor(clamp / 3600);
  const m = Math.floor((clamp % 3600) / 60);
  const s = Math.floor(clamp % 60);
  const ms = Math.round((clamp - Math.floor(clamp)) * 1000);
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')},${String(ms).padStart(3, '0')}`;
}

async function appendLog(line) {
  try {
    await fs.mkdir(OUT, { recursive: true });
    await fs.appendFile(LOG_FILE, line + '\n');
  } catch {
    // logging is best-effort
  }
}

main().catch(async (err) => {
  console.error(err);
  await appendLog(`ERROR ${err.message}`);
  process.exitCode = 1;
});
