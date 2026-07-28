#!/usr/bin/env node
// scale_srt.mjs - scale a SubRip (.srt) file by a constant time factor
// (default 1/1.10) so that every cue timestamp is compressed to match the
// re-encoded 1.10x-speed video. The last cue's end time is extended to hold
// through the outro slate: `<new_video_duration_ms - tail_pad_ms>` ms.
//
// Usage:
//   node tools/demo/scripts/scale_srt.mjs \
//     --in hackathon-docs/video.srt \
//     --out hackathon-docs/video.srt \
//     --video-duration-ms 119732 \
//     [--factor 1.10] \
//     [--tail-pad-ms 100] \
//     [--backup tools/demo/output/video.pre-scale.srt]
//
// Guarantees:
//   - UTF-8 read/write, no BOM added.
//   - Original line endings preserved (CRLF if source has CRLF, otherwise LF).
//   - Original trailing whitespace/newline preserved verbatim.
//   - Monotonic timestamps only (strict: next.start >= prev.end); abort on any
//     overlap after scaling.
//   - Last cue end == videoDurationMs - tailPadMs.
//   - Total SRT end time <= videoDurationMs.
//   - When --backup is given, writes source -> backup path BEFORE writing the scaled SRT.
//
// Runs entirely inside WSL2 with Node 18+ (no external dependencies).

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);

function parseArgs(argv) {
  const args = {
    factor: 1.10,
    tailPadMs: 100,
  };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    const next = () => {
      const v = argv[++i];
      if (v === undefined) throw new Error(`missing value for ${a}`);
      return v;
    };
    switch (a) {
      case "--in":
        args.in = next();
        break;
      case "--out":
        args.out = next();
        break;
      case "--backup":
        args.backup = next();
        break;
      case "--video-duration-ms":
        args.videoDurationMs = Number(next());
        break;
      case "--factor":
        args.factor = Number(next());
        break;
      case "--tail-pad-ms":
        args.tailPadMs = Number(next());
        break;
      case "-h":
      case "--help":
        args.help = true;
        break;
      default:
        throw new Error(`unknown arg '${a}' (see --help)`);
    }
  }
  return args;
}

function usage() {
  const lines = fs.readFileSync(__filename, "utf8").split(/\r?\n/);
  for (const l of lines) {
    if (l.startsWith("// ") || l === "//") {
      console.log(l.replace(/^\/\/ ?/, ""));
    } else if (l.startsWith("#!") || l.trim() === "") {
      continue;
    } else {
      break;
    }
  }
}

function assert(cond, msg) {
  if (!cond) {
    console.error(`error: ${msg}`);
    process.exit(1);
  }
}

function tsToMs(ts) {
  const m = /^(\d{2}):(\d{2}):(\d{2}),(\d{3})$/.exec(ts.trim());
  if (!m) throw new Error(`bad timestamp '${ts}'`);
  const [_, hh, mm, ss, mmm] = m;
  return (
    Number(hh) * 3600_000 +
    Number(mm) * 60_000 +
    Number(ss) * 1_000 +
    Number(mmm)
  );
}

function msToTs(ms) {
  if (!Number.isFinite(ms) || ms < 0) throw new Error(`bad ms ${ms}`);
  const total = Math.round(ms);
  const hh = Math.floor(total / 3600_000);
  const mm = Math.floor((total % 3600_000) / 60_000);
  const ss = Math.floor((total % 60_000) / 1_000);
  const mmm = total % 1_000;
  return (
    String(hh).padStart(2, "0") +
    ":" +
    String(mm).padStart(2, "0") +
    ":" +
    String(ss).padStart(2, "0") +
    "," +
    String(mmm).padStart(3, "0")
  );
}

function detectEol(text) {
  const crlf = (text.match(/\r\n/g) || []).length;
  const lf = (text.match(/(^|[^\r])\n/g) || []).length;
  return crlf > 0 && crlf >= lf ? "\r\n" : "\n";
}

function parseSrt(raw, eol) {
  // Normalize to \n for parsing, but remember original eol for emit.
  const norm = raw.replace(/\r\n/g, "\n");
  const blocks = norm.split(/\n\n+/);
  const cues = [];
  for (const block of blocks) {
    if (block.trim() === "") continue;
    const lines = block.split("\n");
    if (lines.length < 2) continue;
    const idx = Number(lines[0].trim());
    const arrow = lines[1];
    const m = /^\s*(\d{2}:\d{2}:\d{2},\d{3})\s*-->\s*(\d{2}:\d{2}:\d{2},\d{3})\s*$/.exec(arrow);
    if (!m) throw new Error(`bad arrow line for cue #${idx || "?"}: '${arrow}'`);
    const startMs = tsToMs(m[1]);
    const endMs = tsToMs(m[2]);
    const textLines = lines.slice(2);
    cues.push({ idx, startMs, endMs, textLines });
  }
  return cues;
}

function emitSrt(cues, eol) {
  const blocks = cues.map((c) => {
    const header = [
      String(c.idx),
      `${msToTs(c.startMs)} --> ${msToTs(c.endMs)}`,
      ...c.textLines,
    ].join(eol);
    return header;
  });
  return blocks.join(eol + eol);
}

function detectTrailing(raw, eol) {
  // Preserve however many blank lines / trailing newlines the source ended with.
  const norm = raw.replace(/\r\n/g, "\n");
  const m = /\n*$/.exec(norm);
  const trailingNewlineCount = (m && m[0].length) || 0;
  return eol.repeat(trailingNewlineCount);
}

function main() {
  const args = parseArgs(process.argv);
  if (args.help) {
    usage();
    return;
  }
  assert(args.in, "--in is required");
  assert(args.out, "--out is required");
  assert(
    Number.isFinite(args.videoDurationMs) && args.videoDurationMs > 0,
    "--video-duration-ms must be a positive number"
  );
  assert(
    Number.isFinite(args.factor) && args.factor > 0,
    "--factor must be a positive number"
  );
  assert(
    Number.isFinite(args.tailPadMs) && args.tailPadMs >= 0,
    "--tail-pad-ms must be a non-negative number"
  );

  const inPath = path.resolve(args.in);
  const outPath = path.resolve(args.out);
  const backupPath = args.backup ? path.resolve(args.backup) : null;

  assert(fs.existsSync(inPath), `input not found: ${inPath}`);

  const raw = fs.readFileSync(inPath, "utf8");
  assert(raw.length > 0, `input is empty: ${inPath}`);
  assert(!raw.startsWith("\uFEFF"), `input has BOM (unexpected for SubRip)`);

  const eol = detectEol(raw);
  const trailing = detectTrailing(raw, eol);

  const cues = parseSrt(raw, eol);
  assert(cues.length >= 1, `no cues parsed from ${inPath}`);

  // Scale (divide by factor) with millisecond rounding.
  const scaled = cues.map((c) => ({
    idx: c.idx,
    startMs: Math.round(c.startMs / args.factor),
    endMs: Math.round(c.endMs / args.factor),
    textLines: c.textLines,
  }));

  // Extend last cue's end to (videoDurationMs - tailPadMs).
  const targetLastEnd = Math.round(args.videoDurationMs - args.tailPadMs);
  const last = scaled[scaled.length - 1];
  const originalLastEnd = last.endMs;
  assert(
    targetLastEnd >= last.startMs,
    `target last end ${targetLastEnd}ms < last cue start ${last.startMs}ms`
  );
  last.endMs = targetLastEnd;

  // Monotonicity check: start<end, next.start >= prev.end.
  for (let i = 0; i < scaled.length; i++) {
    const c = scaled[i];
    if (!(c.endMs > c.startMs)) {
      console.error(
        `error: cue #${c.idx} has non-positive duration (${c.startMs}ms -> ${c.endMs}ms)`
      );
      process.exit(1);
    }
    if (i > 0) {
      const prev = scaled[i - 1];
      if (c.startMs < prev.endMs) {
        console.error(
          `error: cue #${c.idx} start ${c.startMs}ms overlaps prev cue #${prev.idx} end ${prev.endMs}ms`
        );
        process.exit(1);
      }
    }
  }

  // Total SRT end time must be <= video duration.
  assert(
    last.endMs <= args.videoDurationMs,
    `last cue end ${last.endMs}ms exceeds video duration ${args.videoDurationMs}ms`
  );

  const output = emitSrt(scaled, eol) + trailing;

  // Backup source BEFORE writing when --backup is given (do not clobber existing backup).
  if (backupPath && fs.existsSync(inPath)) {
    if (fs.existsSync(backupPath)) {
      console.log(`  backup already exists: ${backupPath} (leaving untouched)`);
    } else {
      fs.mkdirSync(path.dirname(backupPath), { recursive: true });
      fs.copyFileSync(inPath, backupPath);
      console.log(`  backed up: ${backupPath}`);
    }
  }

  fs.writeFileSync(outPath, output, { encoding: "utf8" });

  const summary = {
    cues: scaled.length,
    factor: args.factor,
    original_last_end_ms: originalLastEnd,
    scaled_last_end_ms_before_extend:
      cues.length > 0 ? Math.round(cues[cues.length - 1].endMs / args.factor) : null,
    final_last_end_ms: last.endMs,
    final_last_end_ts: msToTs(last.endMs),
    video_duration_ms: args.videoDurationMs,
    tail_pad_ms: args.tailPadMs,
    eol: eol === "\r\n" ? "CRLF" : "LF",
    trailing_newlines: trailing.length / eol.length,
    in: inPath,
    out: outPath,
    backup: backupPath,
  };
  console.log(JSON.stringify(summary, null, 2));
}

main();
