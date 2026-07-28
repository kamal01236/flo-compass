#!/usr/bin/env node
// build-audio-track.mjs (v3.1) — assemble paint-aligned narration.mp3.
//
// Supports N-stage scenes (v3.1 companion tour) and legacy primary+secondary
// splits (v3). Reads output/timings.json stage entries, splits per-scene mp3s
// into equal chunks when needed, inserts silence gaps, re-times captions.srt.

import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawn } from 'node:child_process';

import ffmpegPath from 'ffmpeg-static';
import ffprobeStatic from 'ffprobe-static';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, '..');
const OUT = path.join(ROOT, 'output');
const DWELL_JSON = path.join(OUT, 'dwell.json');
const TIMINGS_JSON = path.join(OUT, 'timings.json');
const NARRATION_MP3 = path.join(OUT, 'narration.mp3');
const CAPTIONS_SRT = path.join(OUT, 'captions.srt');
const AUDIO_CONCAT_LIST = path.join(OUT, 'audio-concat.txt');
const LOG_FILE = path.join(OUT, 'render.log');

const FFPROBE = ffprobeStatic.path;
const SILENCE_MP3 = (n) => path.join(OUT, `silence-${String(n).padStart(2, '0')}.mp3`);
const SCENE_MP3 = (n) => path.join(OUT, `scene-${String(n).padStart(2, '0')}.mp3`);
const SCENE_SLICE_MP3 = (n, idx) =>
  path.join(OUT, `scene-${String(n).padStart(2, '0')}-s${String(idx + 1).padStart(2, '0')}.mp3`);

async function main() {
  await fs.mkdir(OUT, { recursive: true });
  const dwell = JSON.parse(await fs.readFile(DWELL_JSON, 'utf8'));
  const timings = JSON.parse(await fs.readFile(TIMINGS_JSON, 'utf8'));

  if (dwell.scenes.length !== timings.scenes.length) {
    throw new Error(
      `dwell.json has ${dwell.scenes.length} scenes but timings.json has ${timings.scenes.length}.`
    );
  }

  await appendLog(`\n=== build-audio-track v3.1 @ ${new Date().toISOString()}`);
  await appendLog(`videoSec=${timings.videoSec}`);

  const segments = [];
  const sliceMap = [];
  let audioCursor = 0;
  let silenceCount = 0;

  for (let i = 0; i < dwell.scenes.length; i++) {
    const scene = dwell.scenes[i];
    const timing = timings.scenes[i];
    const slices = resolveSlices(scene, timing);

    if (slices.length > 1) {
      await splitSceneAudio(scene.n, scene.narrationSec, slices);
    }

    for (let s = 0; s < slices.length; s++) {
      const slice = slices[s];
      const gap = Math.max(0, slice.audioStartAtVideoSec - audioCursor);
      if (gap > 0.01) {
        const idx = ++silenceCount;
        await generateSilence(SILENCE_MP3(idx), gap);
        segments.push(SILENCE_MP3(idx));
        audioCursor += gap;
        await appendLog(`silence #${idx} sec=${gap.toFixed(3)} scene=${scene.n} slice=${s + 1}`);
      }

      const audioFile = slices.length > 1
        ? SCENE_SLICE_MP3(scene.n, s)
        : SCENE_MP3(scene.n);

      segments.push(audioFile);
      sliceMap.push({
        sceneN: scene.n,
        sliceIndex: s,
        startSec: audioCursor,
        narrationSec: slice.narrationSec,
        text: scene.text,
        sliceCount: slices.length,
      });
      audioCursor += slice.narrationSec;
    }
  }

  await writeConcatList(AUDIO_CONCAT_LIST, segments);
  await runFfmpeg([
    '-y', '-f', 'concat', '-safe', '0',
    '-i', AUDIO_CONCAT_LIST,
    '-c', 'copy',
    NARRATION_MP3,
  ]);

  const finalDuration = await probeDuration(NARRATION_MP3);
  await appendLog(`narration_mp3_sec=${finalDuration.toFixed(3)} expected=${audioCursor.toFixed(3)}`);
  console.log(`  narration assembled: ${finalDuration.toFixed(2)}s (video ${timings.videoSec.toFixed(2)}s)`);

  await rewriteCaptions(dwell, sliceMap, CAPTIONS_SRT);
  console.log(`  captions re-timed: ${path.relative(ROOT, CAPTIONS_SRT)}`);
}

function resolveSlices(scene, timing) {
  // v3.1: per-stage timings from walkthrough
  if (Array.isArray(timing.stages) && timing.stages.length > 0) {
    return timing.stages.map((st) => ({
      audioStartAtVideoSec: st.audioStartAtVideoSec,
      narrationSec: st.narrationSec,
    }));
  }

  // v3 legacy: primary + optional secondary
  const slices = [{
    audioStartAtVideoSec: timing.audioStartAtVideoSec,
    narrationSec: timing.primaryNarrationSec ?? timing.narrationSec,
  }];
  if (timing.secondaryAudioStartAtVideoSec != null) {
    slices.push({
      audioStartAtVideoSec: timing.secondaryAudioStartAtVideoSec,
      narrationSec: timing.secondaryNarrationSec ?? timing.narrationSec / 2,
    });
  }
  return slices;
}

async function splitSceneAudio(sceneN, totalSec, slices) {
  let offset = 0;
  for (let i = 0; i < slices.length; i++) {
    const dur = slices[i].narrationSec;
    const out = SCENE_SLICE_MP3(sceneN, i);
    if (i === 0) {
      await runFfmpeg([
        '-y', '-i', SCENE_MP3(sceneN),
        '-t', String(dur),
        '-c', 'copy',
        out,
      ]);
    } else {
      await runFfmpeg([
        '-y', '-ss', String(offset),
        '-i', SCENE_MP3(sceneN),
        '-t', String(dur),
        '-c', 'copy',
        out,
      ]);
    }
    offset += dur;
  }
}

async function generateSilence(outPath, seconds) {
  await runFfmpeg([
    '-y', '-f', 'lavfi', '-i', 'anullsrc=r=24000:cl=mono',
    '-t', String(Math.max(0.02, seconds)),
    '-c:a', 'libmp3lame', '-q:a', '4',
    outPath,
  ]);
}

async function writeConcatList(listFile, files) {
  const body = files.map((p) => `file '${p.replace(/'/g, "'\\''")}'`).join('\n');
  await fs.writeFile(listFile, body);
}

function runFfmpeg(args) {
  return new Promise((resolve, reject) => {
    const p = spawn(ffmpegPath, args, { stdio: ['ignore', 'ignore', 'pipe'] });
    let err = '';
    p.stderr.on('data', (b) => (err += b.toString()));
    p.on('close', (code) => {
      if (code !== 0) return reject(new Error(`ffmpeg exit ${code}: ${err.slice(-500)}`));
      resolve();
    });
  });
}

function probeDuration(mp3Path) {
  return new Promise((resolve, reject) => {
    const p = spawn(FFPROBE, [
      '-v', 'error', '-show_entries', 'format=duration',
      '-of', 'default=noprint_wrappers=1:nokey=1', mp3Path,
    ]);
    let out = '';
    p.on('close', (code) => {
      if (code !== 0) return reject(new Error(`ffprobe exit ${code}`));
      resolve(Number.parseFloat(out.trim()));
    });
    p.stdout.on('data', (b) => (out += b.toString()));
  });
}

async function rewriteCaptions(dwell, sliceMap, outPath) {
  const cues = [];
  let cueIndex = 1;

  const perScene = new Map();
  for (const slice of sliceMap) {
    if (!perScene.has(slice.sceneN)) perScene.set(slice.sceneN, []);
    perScene.get(slice.sceneN).push(slice);
  }

  for (const scene of dwell.scenes) {
    const slices = perScene.get(scene.n) ?? [];
    if (slices.length === 0) continue;

    const sentences = splitSentences(scene.text);
    if (sentences.length === 0) continue;

    const totalChars = sentences.reduce((a, s) => a + s.length, 0);
    const boundaries = [];
    if (slices.length === 1) {
      boundaries.push(sentences.length);
    } else {
      let seen = 0;
      let splitIdx = sentences.length;
      for (let i = 0; i < sentences.length; i++) {
        seen += sentences[i].length;
        if (seen >= totalChars / slices.length) {
          splitIdx = i + 1;
          break;
        }
      }
      let cursor = 0;
      for (let s = 0; s < slices.length; s++) {
        const end = s === slices.length - 1
          ? sentences.length
          : Math.max(cursor + 1, splitIdx + s * 0);
        boundaries.push(s === 0 ? Math.max(1, splitIdx) : sentences.length);
      }
      // Distribute sentences evenly across slices
      const perSlice = Math.ceil(sentences.length / slices.length);
      boundaries.length = 0;
      for (let s = 0; s < slices.length; s++) {
        boundaries.push(Math.min(sentences.length, (s + 1) * perSlice));
      }
    }

    let sentStart = 0;
    for (let s = 0; s < slices.length; s++) {
      const slice = slices[s];
      const sentEnd = boundaries[s];
      const sliceSentences = sentences.slice(sentStart, sentEnd);
      sentStart = sentEnd;
      if (sliceSentences.length === 0) continue;

      const sliceChars = sliceSentences.reduce((a, t) => a + t.length, 0);
      let localCursor = slice.startSec;
      for (let i = 0; i < sliceSentences.length; i++) {
        const sentence = sliceSentences[i];
        const share = sentence.length / Math.max(sliceChars, 1);
        const isLast = i === sliceSentences.length - 1;
        const naturalEnd = isLast
          ? slice.startSec + slice.narrationSec
          : localCursor + slice.narrationSec * share;
        const startSec = localCursor;
        let endSec = naturalEnd;
        if (endSec - startSec < 0.4) endSec = startSec + 0.4;
        cues.push({ n: cueIndex++, start: startSec, end: endSec, text: sentence });
        localCursor = endSec;
      }
    }
  }

  const body = cues.map((c) =>
    `${c.n}\n${formatSrt(c.start)} --> ${formatSrt(c.end)}\n${c.text}`,
  ).join('\n\n') + '\n';
  await fs.writeFile(outPath, body);
}

function splitSentences(text) {
  return text.replace(/\s+/g, ' ').split(/(?<=[.!?])\s+(?=[A-Z])/).map((s) => s.trim()).filter(Boolean);
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
  } catch { /* best-effort */ }
}

main().catch(async (err) => {
  console.error(err);
  await appendLog(`ERROR ${err.message}`);
  process.exitCode = 1;
});
