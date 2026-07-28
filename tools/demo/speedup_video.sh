#!/usr/bin/env bash
# speedup_video.sh - re-encode hackathon-docs/video.mp4 at 1.10x speed
# (setpts=PTS/1.10 video, atempo=1.10 audio) while preserving faststart,
# stereo AAC 192k / 48 kHz, and the source visual profile.
#
# Filter chain:
#   Video: -filter:v setpts=PTS/1.10
#   Audio: -filter:a atempo=1.10
#
# Video codec strategy:
#   1) Attempt libvpx-vp9 at ~589 kbps (matches current source bitrate).
#   2) On failure, fall back to libx264 -crf 20 -preset medium.
#   The chosen codec is recorded in tools/demo/output/render.log.
#
# Audio codec: AAC 192 kbps, 48 kHz, stereo. NO loudnorm re-application
# (the source PersonallyRecorded.enhanced.mp4 audio is already broadcast-mastered).
#
# Container: MP4 with +faststart. Verified via ffprobe box order (moov < mdat).
#
# Duration gate: fail hard (do NOT overwrite the destination) if the produced
# output duration falls outside [118.000, 120.000] seconds.
#
# Safety:
#   - Backs up hackathon-docs/video.mp4 -> tools/demo/output/video.pre-speedup.mp4
#     BEFORE writing the new file. Existing backup is not clobbered.
#   - Writes to a temp path first; only moves into place after all gates pass.
#
# Usage:
#   bash tools/demo/speedup_video.sh              # normal run
#   bash tools/demo/speedup_video.sh --force-x264 # skip VP9 attempt, use x264 directly
#   bash tools/demo/speedup_video.sh --help
#
# Runs entirely inside WSL2 per .cursor/rules/wsl2-development.mdc using the
# pinned ffmpeg-static / ffprobe-static binaries in tools/demo/node_modules -
# no host ffmpeg dependency.
set -euo pipefail

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$TOOLS_DIR/output"
REPO_ROOT="$(cd "$TOOLS_DIR/../.." && pwd)"

FORCE_X264=0
for arg in "$@"; do
  case "$arg" in
    --force-x264)
      FORCE_X264=1
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

SRC="$REPO_ROOT/hackathon-docs/video.mp4"
DST="$REPO_ROOT/hackathon-docs/video.mp4"
BACKUP="$OUTPUT_DIR/video.pre-speedup.mp4"
LOG="$OUTPUT_DIR/render.log"

if [[ ! -f "$SRC" ]]; then
  echo "error: missing source $SRC" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

TMP_DIR="$(mktemp -d "$OUTPUT_DIR/speedup.XXXXXX")"
TMP_VP9="$TMP_DIR/video.vp9.mp4"
TMP_X264="$TMP_DIR/video.x264.mp4"
STDERR_VP9="$TMP_DIR/vp9.stderr.log"
STDERR_X264="$TMP_DIR/x264.stderr.log"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "=== speedup_video @ $(date -u +'%Y-%m-%dT%H:%M:%SZ') ===" >> "$LOG"
echo "src=$SRC" >> "$LOG"
echo "dst=$DST" >> "$LOG"
echo "backup=$BACKUP" >> "$LOG"
echo "force_x264=$FORCE_X264" >> "$LOG"

echo "  probing source ..."
SRC_DURATION="$("$FFPROBE_BIN" -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$SRC")"
SRC_V_CODEC="$("$FFPROBE_BIN" -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$SRC")"
SRC_A_CODEC="$("$FFPROBE_BIN" -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$SRC")"
SRC_V_BR="$("$FFPROBE_BIN" -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$SRC")"
SRC_A_BR="$("$FFPROBE_BIN" -v error -select_streams a:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$SRC")"
SRC_W="$("$FFPROBE_BIN" -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$SRC")"
SRC_H="$("$FFPROBE_BIN" -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$SRC")"
SRC_FPS="$("$FFPROBE_BIN" -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$SRC")"

echo "    source: ${SRC_DURATION}s ${SRC_V_CODEC} ${SRC_W}x${SRC_H}@${SRC_FPS} v=${SRC_V_BR}bps a=${SRC_A_CODEC}@${SRC_A_BR}bps"
{
  echo "src_duration=${SRC_DURATION}"
  echo "src_video_codec=${SRC_V_CODEC}"
  echo "src_audio_codec=${SRC_A_CODEC}"
  echo "src_video_bitrate=${SRC_V_BR}"
  echo "src_audio_bitrate=${SRC_A_BR}"
  echo "src_dim=${SRC_W}x${SRC_H}@${SRC_FPS}"
} >> "$LOG"

# VP9 target bitrate matches source (~589 kbps).
VP9_BR="589k"
CHOSEN_CODEC=""
CHOSEN_CMD=""
TMP_OUT=""

encode_vp9() {
  echo "  attempting libvpx-vp9 encode (target ${VP9_BR}) ..."
  local cmd=(
    "$FFMPEG_BIN" -y -hide_banner -nostats
    -i "$SRC"
    -map 0:v:0 -map 0:a:0
    -filter:v "setpts=PTS/1.10"
    -filter:a "atempo=1.10"
    -c:v libvpx-vp9 -b:v "$VP9_BR" -deadline good -cpu-used 2 -row-mt 1
    -c:a aac -b:a 192k -ar 48000 -ac 2
    -movflags +faststart
    "$TMP_VP9"
  )
  echo "    cmd: ${cmd[*]}"
  echo "vp9_cmd=${cmd[*]}" >> "$LOG"
  set +e
  "${cmd[@]}" 2>"$STDERR_VP9"
  local status=$?
  set -e
  if (( status != 0 )); then
    echo "    VP9 encode failed (status $status). Tail:"
    tail -n 5 "$STDERR_VP9" | sed 's/^/      /'
    echo "vp9_status=$status (falling back)" >> "$LOG"
    return 1
  fi
  if [[ ! -s "$TMP_VP9" ]]; then
    echo "    VP9 encode produced empty file"
    echo "vp9_status=empty_output (falling back)" >> "$LOG"
    return 1
  fi
  CHOSEN_CODEC="libvpx-vp9"
  CHOSEN_CMD="${cmd[*]}"
  TMP_OUT="$TMP_VP9"
  echo "vp9_status=ok" >> "$LOG"
  return 0
}

encode_x264() {
  echo "  encoding libx264 -crf 20 -preset medium ..."
  local cmd=(
    "$FFMPEG_BIN" -y -hide_banner -nostats
    -i "$SRC"
    -map 0:v:0 -map 0:a:0
    -filter:v "setpts=PTS/1.10"
    -filter:a "atempo=1.10"
    -c:v libx264 -crf 20 -preset medium -pix_fmt yuv420p
    -c:a aac -b:a 192k -ar 48000 -ac 2
    -movflags +faststart
    "$TMP_X264"
  )
  echo "    cmd: ${cmd[*]}"
  echo "x264_cmd=${cmd[*]}" >> "$LOG"
  set +e
  "${cmd[@]}" 2>"$STDERR_X264"
  local status=$?
  set -e
  if (( status != 0 )); then
    cat "$STDERR_X264" >&2
    echo "error: libx264 fallback failed (status $status); see $STDERR_X264" >&2
    echo "x264_status=$status" >> "$LOG"
    return "$status"
  fi
  CHOSEN_CODEC="libx264"
  CHOSEN_CMD="${cmd[*]}"
  TMP_OUT="$TMP_X264"
  echo "x264_status=ok" >> "$LOG"
  return 0
}

if (( FORCE_X264 == 1 )); then
  echo "  --force-x264: skipping VP9 attempt"
  echo "codec_strategy=force_x264" >> "$LOG"
  encode_x264
else
  echo "codec_strategy=vp9_first" >> "$LOG"
  if ! encode_vp9; then
    encode_x264
  fi
fi

if [[ -z "$TMP_OUT" || ! -s "$TMP_OUT" ]]; then
  echo "error: no encoded output produced" >&2
  exit 1
fi

echo "  probing produced output ..."
OUT_DURATION="$("$FFPROBE_BIN" -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$TMP_OUT")"
OUT_V_CODEC="$("$FFPROBE_BIN" -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$TMP_OUT")"
OUT_A_CODEC="$("$FFPROBE_BIN" -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$TMP_OUT")"
OUT_A_SR="$("$FFPROBE_BIN" -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$TMP_OUT")"
OUT_A_CH="$("$FFPROBE_BIN" -v error -select_streams a:0 -show_entries stream=channels -of default=noprint_wrappers=1:nokey=1 "$TMP_OUT")"
OUT_A_BR="$("$FFPROBE_BIN" -v error -select_streams a:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$TMP_OUT")"
OUT_V_BR="$("$FFPROBE_BIN" -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$TMP_OUT")"

echo "    output: ${OUT_DURATION}s v=${OUT_V_CODEC}@${OUT_V_BR}bps a=${OUT_A_CODEC} ${OUT_A_SR}Hz ${OUT_A_CH}ch ${OUT_A_BR}bps"

# Duration gate (hard fail; do NOT overwrite destination).
awk_dur_ok="$(awk -v d="$OUT_DURATION" 'BEGIN{ if (d+0 >= 118.000 && d+0 <= 120.000) print "yes"; else print "no" }')"
if [[ "$awk_dur_ok" != "yes" ]]; then
  echo "error: produced duration ${OUT_DURATION}s falls outside [118.000, 120.000]s gate" >&2
  echo "duration_gate=fail actual=${OUT_DURATION}" >> "$LOG"
  exit 1
fi
echo "duration_gate=ok actual=${OUT_DURATION}" >> "$LOG"

# Faststart gate: verify box order (ftyp, moov, mdat) with moov before mdat.
BOX_ORDER="$("$FFPROBE_BIN" -v trace "$TMP_OUT" 2>&1 | grep -oE "type:.(moov|mdat|ftyp)" | tr '\n' ' ' || true)"
echo "    box order: $BOX_ORDER"
MOOV_POS="$(echo "$BOX_ORDER" | tr ' ' '\n' | grep -n "moov" | head -1 | cut -d: -f1 || true)"
MDAT_POS="$(echo "$BOX_ORDER" | tr ' ' '\n' | grep -n "mdat" | head -1 | cut -d: -f1 || true)"
if [[ -z "$MOOV_POS" || -z "$MDAT_POS" ]]; then
  echo "error: faststart check could not locate moov/mdat boxes; produced file may be malformed" >&2
  echo "faststart_gate=fail no_boxes" >> "$LOG"
  exit 1
fi
if (( MOOV_POS >= MDAT_POS )); then
  echo "error: faststart NOT set (moov@${MOOV_POS} not before mdat@${MDAT_POS})" >&2
  echo "faststart_gate=fail moov=${MOOV_POS} mdat=${MDAT_POS}" >> "$LOG"
  exit 1
fi
echo "faststart_gate=ok moov=${MOOV_POS} mdat=${MDAT_POS}" >> "$LOG"

# Backup destination BEFORE overwrite (do not clobber existing backup).
if [[ -f "$DST" ]]; then
  if [[ -f "$BACKUP" ]]; then
    echo "  backup already exists: $BACKUP (leaving untouched)"
  else
    cp -p "$DST" "$BACKUP"
    echo "  backed up: $BACKUP"
  fi
else
  echo "  no existing destination to back up"
fi
echo "backup=$BACKUP" >> "$LOG"

# Atomic promote.
mv -f "$TMP_OUT" "$DST"
echo "  wrote: $DST"

{
  echo "chosen_codec=${CHOSEN_CODEC}"
  echo "chosen_cmd=${CHOSEN_CMD}"
  echo "duration=${OUT_DURATION}"
  echo "video_codec=${OUT_V_CODEC}"
  echo "video_bitrate=${OUT_V_BR}"
  echo "audio_codec=${OUT_A_CODEC}"
  echo "audio_sample_rate=${OUT_A_SR}"
  echo "audio_channels=${OUT_A_CH}"
  echo "audio_bit_rate=${OUT_A_BR}"
  echo "faststart=ok"
} >> "$LOG"

echo ""
echo "duration: ${OUT_DURATION}s"
echo "video codec: ${OUT_V_CODEC} @ ${OUT_V_BR}bps"
echo "audio: ${OUT_A_CODEC} ${OUT_A_SR}Hz ${OUT_A_CH}ch ${OUT_A_BR}bps"
echo "faststart: yes"
echo "backup: $BACKUP"
echo "chosen_codec: $CHOSEN_CODEC"
echo "ffmpeg_cmd: $CHOSEN_CMD"
