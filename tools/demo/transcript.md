# Flo Compass demo video - transcript (personal recording, ~120 s (1.1x speedup))

Companion document for `hackathon-docs/video.mp4`. Submission assets are `hackathon-docs/video.mp4` + `hackathon-docs/video.srt` — the **personally recorded + broadcast-enhanced + 1.10x-time-scaled** track (~120 s), not the automated Playwright/TTS pipeline. Sidecar captions: `hackathon-docs/video.srt` (Whisper `small.en` auto-transcription, timestamps scaled by 1/1.10 to match the sped-up video). Regenerate base captions with `bash tools/demo/scripts/generate-video-srt.sh`; re-scale with `node tools/demo/scripts/scale_srt.mjs`; re-encode the sped-up MP4 with `bash tools/demo/speedup_video.sh` (optional pre-run backups under `tools/demo/output/`).

Historical note: earlier automated renders used edge-tts (`en-IN-PrabhatNeural`) and paint-gated narration (~115–125s target).

## v3.1.3 tab fix (URL-based)

CanvasKit **ignores Playwright tab clicks** (canvas is in shadow DOM; `flt-glass-pane` reports 0×0). Tab switches now use deep links:

| Screen | URL param | Tab |
|--------|-----------|-----|
| Session | `?focus=qa` | Q&A |
| Session | `?focus=logistics` | Logistics |
| Profile | `?tab=progress` | Progress |
| Profile | `?tab=settings` | Settings |

Walkthrough shows cursor ripple at tab coords, then `selectTabUrl` loads the deep link. Map / Add-to-Plan still use canvas clicks (`flt-glass-pane >> canvas`).

Full audio: personal recording (enhanced). Sidecar: `hackathon-docs/video.srt` (Whisper).

## Scenes

| # | URL | Action | Real click (coord key) | Narration |
|---|-----|--------|------------------------|-----------|
| 1 | `/discover?day=Day%201&sort=soonest` | Scroll dy=850 mid-narration → session card | Open session card | Welcome… live banner… Learning Paths… happening now. |
| 2–4 | `/session/s-001` → `/map?room=ven-G01` (merged) | Overview scroll → Q&A tab → Q&A scroll → Logistics tab → Logistics scroll → Map → venue scroll | `sessionQa`, `sessionLogistics`, `mapButton`, `shellAskFlo` | Session detail + Q&A + Logistics + venue map narration blocks |
| 5 | `/companion?q=What's%20happening%20now%3F` | Citation cards | — | Ask Flo… live cards with citations. |
| 6 | `/companion?q=Plan%20my%20Day%201` | Plan draft | `addToPlan` | Plan my Day one… add to my plan. |
| 7 | `/my-plan` | Scroll Day 2/3 | `shellProfile` | My Plan… Day one, two, and three. |
| 8–9 | `/profile` (merged) | You scroll → Progress tab → Progress scroll → Settings tab → Settings scroll | `profileProgress`, `profileSettings` | You tab + Progress + Settings narration blocks |
| 10 | `file://scripts/outro.html` | Outro slate | — | Flo Compass, built with Cursor… |

## Delivery notes

- Recording opens on Discover (no onboarding); seed sets `onboardingComplete: true`.
- **No highlight rings** — cursor label chips only.
- **Canvas clicks** logged as `canvas_click` in `output/render.log`.
- **1.5 s hold** before scene-transition ripples; internal tab clicks use ~400 ms.
- Target MP4 duration: **~120 s (1.1x speedup)** (personal recording + enhancement pass).
