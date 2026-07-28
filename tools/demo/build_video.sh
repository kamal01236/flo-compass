#!/usr/bin/env bash
# build_video.sh - mux Playwright WebM + gapped edge-tts narration to MP4 (v3).
#
# v3 audio pipeline:
#   1. build-audio-track.mjs reads output/timings.json (from walkthrough.mjs)
#      and per-scene mp3s (from run-tts.mjs), assembles output/narration.mp3
#      with paint-aligned silence gaps, and re-times output/captions.srt so
#      each cue lines up with the gapped voice-over.
#   2. ffmpeg muxes scene-recording.webm + narration.mp3 (+ optional captions).
#
# Captions strategy (unchanged from v2):
#   FLO_BURN_CAPTIONS=0 (default) -> clean picture, soft mov_text track + sidecar.
#   FLO_BURN_CAPTIONS=1           -> captions burned into the picture.
#
# Outputs to hackathon-docs/video.mp4, H.264 + AAC, 115-125s target.
set -euo pipefail

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$TOOLS_DIR/output"
REPO_ROOT="$(cd "$TOOLS_DIR/../.." && pwd)"

if ! command -v node >/dev/null 2>&1; then
  echo "error: node is required (install Node 18+ and rerun)" >&2
  exit 1
fi

FFMPEG_BIN="$(node -e "process.stdout.write(require('ffmpeg-static'))" 2>/dev/null || true)"
FFPROBE_BIN="$(node -e "process.stdout.write(require('ffprobe-static').path)" 2>/dev/null || true)"

if [[ -z "${FFMPEG_BIN}" || ! -x "${FFMPEG_BIN}" ]]; then
  echo "error: ffmpeg-static binary not found. Run 'npm install' in tools/demo first." >&2
  exit 1
fi
if [[ -z "${FFPROBE_BIN}" || ! -x "${FFPROBE_BIN}" ]]; then
  echo "error: ffprobe-static binary not found. Run 'npm install' in tools/demo first." >&2
  exit 1
fi

WEBM="$OUTPUT_DIR/scene-recording.webm"
TIMINGS="$OUTPUT_DIR/timings.json"
NARRATION="$OUTPUT_DIR/narration.mp3"
CAPTIONS="$OUTPUT_DIR/captions.srt"
OUT="$REPO_ROOT/hackathon-docs/video.mp4"
SIDECAR_SRT="$REPO_ROOT/hackathon-docs/video.srt"
LOG="$OUTPUT_DIR/render.log"

# Required inputs from prior stages.
for f in "$WEBM" "$TIMINGS" "$OUTPUT_DIR/dwell.json"; do
  if [[ ! -f "$f" ]]; then
    echo "error: missing input $f" >&2
    exit 1
  fi
done

mkdir -p "$(dirname "$OUT")"

BURN_CAPTIONS="${FLO_BURN_CAPTIONS:-0}"

{
  echo ""
  echo "=== build_video @ $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "webm=$WEBM"
  echo "timings=$TIMINGS"
  echo "burn_captions=$BURN_CAPTIONS"
} >> "$LOG"

echo "  building gapped narration + captions ..."
node "$TOOLS_DIR/scripts/build-audio-track.mjs"

# Sanity check the assembled inputs exist after build-audio-track.
for f in "$NARRATION" "$CAPTIONS"; do
  if [[ ! -f "$f" ]]; then
    echo "error: build-audio-track did not produce $f" >&2
    exit 1
  fi
done

# Stage a copy of the SRT under a filter-safe name (subtitle filter escaping
# is picky on Windows paths piped through WSL).
STAGED_SRT="$OUTPUT_DIR/captions.staged.srt"
cp "$CAPTIONS" "$STAGED_SRT"

if [[ "$BURN_CAPTIONS" == "1" ]]; then
  SUBTITLES_FILTER="subtitles=$STAGED_SRT:force_style='FontName=DejaVu Sans,FontSize=22,PrimaryColour=&H00FFFFFF,OutlineColour=&H80000000,BackColour=&H80000000,BorderStyle=3,Outline=2,Shadow=0,MarginV=80,Alignment=2'"
  VF="$SUBTITLES_FILTER,fps=30,format=yuv420p"
  MAP_ARGS=(-map 0:v:0 -map 1:a:0)
  SUB_INPUT_ARGS=()
  SUB_CODEC_ARGS=()
else
  VF="fps=30,format=yuv420p"
  MAP_ARGS=(-map 0:v:0 -map 1:a:0 -map 2:s:0)
  SUB_INPUT_ARGS=(-i "$CAPTIONS")
  SUB_CODEC_ARGS=(-c:s mov_text -disposition:s:0 0 -metadata:s:s:0 language=eng)
fi

set -x
"$FFMPEG_BIN" -y \
  -i "$WEBM" \
  -i "$NARRATION" \
  "${SUB_INPUT_ARGS[@]}" \
  -vf "$VF" \
  "${MAP_ARGS[@]}" \
  -c:v libx264 -preset veryfast -crf 22 -pix_fmt yuv420p \
  -c:a aac -b:a 128k -ar 48000 \
  "${SUB_CODEC_ARGS[@]}" \
  -movflags +faststart \
  "$OUT" 2>&1 | tee -a "$LOG"
set +x

cp "$CAPTIONS" "$SIDECAR_SRT"

DURATION="$("$FFPROBE_BIN" -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUT")"
WIDTH="$("$FFPROBE_BIN" -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$OUT")"
HEIGHT="$("$FFPROBE_BIN" -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$OUT")"

echo ""
echo "wrote: $OUT"
echo "wrote: $SIDECAR_SRT (sidecar captions)"
echo "duration: ${DURATION}s"
echo "size: ${WIDTH}x${HEIGHT}"
echo "burn_captions: $BURN_CAPTIONS"

# Duration gate (soft): warn if outside 115-125s. Exit 0 either way so the CI
# summary always writes; render.log has the numbers.
DURATION_INT="$(printf '%.0f' "$DURATION")"
if (( DURATION_INT < 115 )); then
  echo "WARN: duration ${DURATION}s below 115s floor; extend outro or narration."
elif (( DURATION_INT > 125 )); then
  echo "WARN: duration ${DURATION}s above 125s ceiling; trim narration or paintSettleMs."
fi

{
  echo "duration=${DURATION}s"
  echo "size=${WIDTH}x${HEIGHT}"
  echo "sidecar_srt=$SIDECAR_SRT"
} >> "$LOG"
