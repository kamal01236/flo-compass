#!/usr/bin/env bash
# enhance_personally_recorded.sh - clean and master
#   hackathon-docs/PersonallyRecorded.mp4
# to broadcast quality (single-pass loudnorm) while preserving the VP9 video
# stream losslessly.
#
# Filter chain (voice, in order):
#   highpass f=80              kill rumble below voice fundamentals
#   afftdn   nr=12 nf=-25      FFT spectral denoise, moderate strength
#   equalizer 200 Hz  -2 dB    cut boxy/muddy character
#   equalizer 3 kHz   +2 dB    presence lift, crisper consonants
#   equalizer 8 kHz   +1.5 dB  air/brightness for broadcast polish
#   acompressor 3:1 thr -20dB  even out loud vs quiet passages
#   loudnorm I=-16 TP=-1.5     EBU R128 / streaming standard
#     LRA=11
#
# Video: -c:v copy (VP9 preserved, zero re-encode)
# Audio: AAC 192 kbps, 48 kHz stereo
# Container: MP4 with +faststart for web streaming
#
# Usage:
#   bash tools/demo/enhance_personally_recorded.sh              # single-pass (default)
#   bash tools/demo/enhance_personally_recorded.sh --two-pass   # two-pass loudnorm (~1 dB tighter)
#   bash tools/demo/enhance_personally_recorded.sh --help
#
# Runs entirely inside WSL2 per .cursor/rules/wsl2-development.mdc using the
# pinned ffmpeg-static binary in tools/demo/node_modules — no host ffmpeg
# dependency and no external services.
set -euo pipefail

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$TOOLS_DIR/output"
REPO_ROOT="$(cd "$TOOLS_DIR/../.." && pwd)"

TWO_PASS=0
for arg in "$@"; do
  case "$arg" in
    --two-pass)
      TWO_PASS=1
      ;;
    -h|--help)
      grep -E '^# ' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "error: unknown arg '$arg' (see --help)" >&2
      exit 2
      ;;
  esac
done

if ! command -v node >/dev/null 2>&1; then
  echo "error: node is required (install Node 18+ and rerun)" >&2
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

SRC="$REPO_ROOT/hackathon-docs/PersonallyRecorded.mp4"
OUT="$REPO_ROOT/hackathon-docs/PersonallyRecorded.enhanced.mp4"
LOG="$OUTPUT_DIR/render.log"

if [[ ! -f "$SRC" ]]; then
  echo "error: missing source $SRC" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

AUDIO_CHAIN="highpass=f=80,afftdn=nr=12:nf=-25,equalizer=f=200:width_type=q:width=1:g=-2,equalizer=f=3000:width_type=q:width=1:g=2,equalizer=f=8000:width_type=q:width=1:g=1.5,acompressor=threshold=-20dB:ratio=3:attack=5:release=50:makeup=2"

STDERR_LOG="$OUTPUT_DIR/enhance-ffmpeg.stderr.log"
PASS1_LOG="$OUTPUT_DIR/enhance-pass1.stderr.log"
: > "$STDERR_LOG"

{
  echo ""
  echo "=== enhance_personally_recorded @ $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "src=$SRC"
  echo "out=$OUT"
  echo "two_pass=$TWO_PASS"
  echo "audio_chain=${AUDIO_CHAIN},loudnorm=I=-16:TP=-1.5:LRA=11"
} >> "$LOG"

extract_json_value() {
  local key="$1"
  local file="$2"
  grep -oE "\"${key}\" *: *\"[^\"]+\"" "$file" | tail -1 | sed -E 's/.*: *"([^"]+)".*/\1/'
}

if (( TWO_PASS == 1 )); then
  echo "  pass 1: measuring loudness ..."
  : > "$PASS1_LOG"
  set +e
  "$FFMPEG_BIN" -y -hide_banner -nostats \
    -i "$SRC" \
    -map 0:a:0 \
    -af "${AUDIO_CHAIN},loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json" \
    -f null - 2>"$PASS1_LOG"
  P1_STATUS=$?
  set -e
  if (( P1_STATUS != 0 )); then
    cat "$PASS1_LOG" >&2
    echo "error: pass 1 ffmpeg exited $P1_STATUS" >&2
    exit "$P1_STATUS"
  fi

  P1_I=$(extract_json_value input_i "$PASS1_LOG")
  P1_TP=$(extract_json_value input_tp "$PASS1_LOG")
  P1_LRA=$(extract_json_value input_lra "$PASS1_LOG")
  P1_THRESH=$(extract_json_value input_thresh "$PASS1_LOG")
  P1_OFFSET=$(extract_json_value target_offset "$PASS1_LOG")

  if [[ -z "$P1_I" || -z "$P1_TP" || -z "$P1_LRA" || -z "$P1_THRESH" || -z "$P1_OFFSET" ]]; then
    echo "error: pass 1 did not emit expected loudnorm JSON; see $PASS1_LOG" >&2
    exit 1
  fi

  echo "  pass 1 measured I=${P1_I} TP=${P1_TP} LRA=${P1_LRA} thresh=${P1_THRESH} offset=${P1_OFFSET}"
  LOUDNORM_FILTER="loudnorm=I=-16:TP=-1.5:LRA=11:measured_I=${P1_I}:measured_TP=${P1_TP}:measured_LRA=${P1_LRA}:measured_thresh=${P1_THRESH}:offset=${P1_OFFSET}:linear=true:print_format=json"
else
  LOUDNORM_FILTER="loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json"
fi

echo "  encoding enhanced output ..."
set +e
"$FFMPEG_BIN" -y -hide_banner \
  -i "$SRC" \
  -map 0:v:0 -map 0:a:0 \
  -c:v copy \
  -af "${AUDIO_CHAIN},${LOUDNORM_FILTER}" \
  -c:a aac -b:a 192k -ar 48000 -ac 2 \
  -movflags +faststart \
  "$OUT" 2>&1 | tee "$STDERR_LOG"
FF_STATUS="${PIPESTATUS[0]}"
set -e

if (( FF_STATUS != 0 )); then
  echo "error: ffmpeg exited $FF_STATUS; see $STDERR_LOG" >&2
  exit "$FF_STATUS"
fi

MEAS_INPUT_I=$(extract_json_value input_i "$STDERR_LOG")
MEAS_INPUT_TP=$(extract_json_value input_tp "$STDERR_LOG")
MEAS_INPUT_LRA=$(extract_json_value input_lra "$STDERR_LOG")
MEAS_OUTPUT_I=$(extract_json_value output_i "$STDERR_LOG")
MEAS_OUTPUT_TP=$(extract_json_value output_tp "$STDERR_LOG")
MEAS_OUTPUT_LRA=$(extract_json_value output_lra "$STDERR_LOG")

DURATION="$("$FFPROBE_BIN" -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUT")"
V_CODEC="$("$FFPROBE_BIN" -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$OUT")"
A_CODEC="$("$FFPROBE_BIN" -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$OUT")"
A_SR="$("$FFPROBE_BIN" -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$OUT")"
A_CH="$("$FFPROBE_BIN" -v error -select_streams a:0 -show_entries stream=channels -of default=noprint_wrappers=1:nokey=1 "$OUT")"
A_BR="$("$FFPROBE_BIN" -v error -select_streams a:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$OUT")"
FASTSTART="$("$FFPROBE_BIN" -v error -show_entries format_tags=major_brand,minor_version,compatible_brands -show_entries format=format_name -of default=noprint_wrappers=1:nokey=1 "$OUT")"

echo ""
echo "wrote: $OUT"
echo "duration: ${DURATION}s"
echo "video codec: ${V_CODEC}"
echo "audio: ${A_CODEC} ${A_SR}Hz ${A_CH}ch ${A_BR}bps"
echo "loudnorm input : I=${MEAS_INPUT_I} LUFS  TP=${MEAS_INPUT_TP} dBTP  LRA=${MEAS_INPUT_LRA}"
echo "loudnorm output: I=${MEAS_OUTPUT_I} LUFS  TP=${MEAS_OUTPUT_TP} dBTP  LRA=${MEAS_OUTPUT_LRA}"

{
  echo "duration=${DURATION}s"
  echo "video_codec=${V_CODEC}"
  echo "audio_codec=${A_CODEC}"
  echo "audio_sample_rate=${A_SR}"
  echo "audio_channels=${A_CH}"
  echo "audio_bit_rate=${A_BR}"
  echo "format_probe=${FASTSTART}"
  echo "loudnorm_measured_input_i=${MEAS_INPUT_I}"
  echo "loudnorm_measured_input_tp=${MEAS_INPUT_TP}"
  echo "loudnorm_measured_input_lra=${MEAS_INPUT_LRA}"
  echo "loudnorm_measured_output_i=${MEAS_OUTPUT_I}"
  echo "loudnorm_measured_output_tp=${MEAS_OUTPUT_TP}"
  echo "loudnorm_measured_output_lra=${MEAS_OUTPUT_LRA}"
} >> "$LOG"
