#!/usr/bin/env bash
# generate-video-srt.sh - extract audio from submission video and transcribe
# with openai-whisper (small.en) to hackathon-docs/video.srt.
#
# Usage:
#   bash tools/demo/scripts/generate-video-srt.sh [input.mp4]
#
# Requires: node, npm install in tools/demo, whisper CLI in PATH (pip install --user openai-whisper)
# Runs in WSL per .cursor/rules/wsl2-development.mdc using pinned ffmpeg-static.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$TOOLS_DIR/../.." && pwd)"
OUTPUT_DIR="$TOOLS_DIR/output"
LOG="$OUTPUT_DIR/render.log"

INPUT="${1:-$REPO_ROOT/hackathon-docs/video.mp4}"
WAV="$OUTPUT_DIR/video-whisper.wav"
WHISPER_OUT_DIR="$OUTPUT_DIR/whisper-srt"
SRT_DEST="$REPO_ROOT/hackathon-docs/video.srt"
CAPTIONS_COPY="$OUTPUT_DIR/captions.srt"

if [[ ! -f "$INPUT" ]]; then
  echo "error: missing input $INPUT" >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "error: node is required (install Node 18+ and rerun)" >&2
  exit 1
fi

WHISPER_BIN=""
export PATH="${HOME}/.local/bin:${PATH}"
if command -v whisper >/dev/null 2>&1; then
  WHISPER_BIN="$(command -v whisper)"
elif [[ -x "$TOOLS_DIR/.venv-whisper/bin/whisper" ]]; then
  WHISPER_BIN="$TOOLS_DIR/.venv-whisper/bin/whisper"
elif [[ -x "${HOME}/.local/bin/whisper" ]]; then
  WHISPER_BIN="${HOME}/.local/bin/whisper"
fi
if [[ -z "$WHISPER_BIN" ]]; then
  echo "error: whisper CLI not found. Install in WSL:" >&2
  echo "  python3 /tmp/get-pip.py --user --break-system-packages" >&2
  echo "  python3 -m pip install --user --break-system-packages openai-whisper" >&2
  exit 1
fi

FFMPEG_BIN="$(cd "$TOOLS_DIR" && node -e "process.stdout.write(require('ffmpeg-static'))" 2>/dev/null || true)"
FFPROBE_BIN="$(cd "$TOOLS_DIR" && node -e "process.stdout.write(require('ffprobe-static').path)" 2>/dev/null || true)"

if [[ -z "${FFMPEG_BIN}" || ! -x "${FFMPEG_BIN}" ]]; then
  echo "error: ffmpeg-static binary not found. Run 'npm install' in tools/demo first." >&2
  exit 1
fi
if [[ -z "${FFPROBE_BIN}" || ! -x "${FFPROBE_BIN}" ]]; then
  echo "error: ffprobe-static binary not found. Run 'npm install' in tools/demo first." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR" "$WHISPER_OUT_DIR"

VIDEO_DURATION="$("$FFPROBE_BIN" -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT")"

echo "extracting 16 kHz mono WAV from $INPUT ..."
"$FFMPEG_BIN" -y -hide_banner -loglevel error \
  -i "$INPUT" \
  -vn -ar 16000 -ac 1 \
  "$WAV"

echo "running whisper (small.en) ..."
export PATH="$(dirname "$FFMPEG_BIN"):$PATH"
"$WHISPER_BIN" "$WAV" \
  --model small.en \
  --language en \
  --output_format srt \
  --output_dir "$WHISPER_OUT_DIR"

WAV_BASENAME="$(basename "$WAV" .wav)"
GENERATED_SRT="$WHISPER_OUT_DIR/${WAV_BASENAME}.srt"

if [[ ! -f "$GENERATED_SRT" ]]; then
  echo "error: whisper did not produce $GENERATED_SRT" >&2
  exit 1
fi

# Light glossary fixes for product terms Whisper commonly mishears
sed -i \
  -e 's/Flo compass/Flo Compass/g' \
  -e 's/flo compass/Flo Compass/g' \
  -e 's/AI Avengers/ai-avengers/g' \
  -e 's/Ai Avengers/ai-avengers/g' \
  -e 's/Accel events/Accelevents/g' \
  -e 's/accel events/Accelevents/g' \
  -e 's/Gen AI/GenAI/g' \
  -e 's/gen ai/GenAI/g' \
  -e 's/Q and A/Q\&A/g' \
  -e 's/q and a/Q\&A/g' \
  "$GENERATED_SRT"

cp "$GENERATED_SRT" "$SRT_DEST"
cp "$GENERATED_SRT" "$CAPTIONS_COPY"

CUE_COUNT="$(grep -cE '^[0-9]+$' "$SRT_DEST" || true)"
LAST_TS="$(grep -E '^[0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3} -->' "$SRT_DEST" | tail -1 | sed -E 's/.*--> ([0-9:,]+).*/\1/')"

# Convert last timestamp to seconds for validation
LAST_SEC="$(python3 -c "
import sys
ts = sys.argv[1]
h, m, rest = ts.split(':')
s, ms = rest.split(',')
print(int(h)*3600 + int(m)*60 + int(s) + int(ms)/1000)
" "$LAST_TS" 2>/dev/null || echo "0")"

{
  echo ""
  echo "=== generate-video-srt @ $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "input=$INPUT"
  echo "video_duration=${VIDEO_DURATION}s"
  echo "wav=$WAV"
  echo "srt=$SRT_DEST"
  echo "captions_copy=$CAPTIONS_COPY"
  echo "whisper_model=small.en"
  echo "cue_count=$CUE_COUNT"
  echo "last_cue_end=$LAST_TS (${LAST_SEC}s)"
} >> "$LOG"

echo ""
echo "wrote: $SRT_DEST"
echo "copy:  $CAPTIONS_COPY"
echo "cues:  $CUE_COUNT"
echo "last cue end: $LAST_TS (${LAST_SEC}s)"
echo "video duration: ${VIDEO_DURATION}s"
