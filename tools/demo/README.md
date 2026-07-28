# Flo Compass demo video pipeline (v3.1.2 tab click calibration)

Automated 10-scene walkthrough of Flo Compass, recorded off **local Tier 2 Docker/nginx** on `http://localhost:8080`. Playwright drives headless Chromium at 1920×1080 with a **cursor-only companion tour** (no highlight rings), **canvas-relative clicks** via `flt-glass-pane` for tab switches and Add-to-My-Plan, and a **1.5 s hold** before each scene-transition ripple. edge-tts renders narration; ffmpeg muxes WebM + gapped voice-over to `hackathon-docs/video.mp4`.

Duration target: **115–125 s**.

## What v3.1.2 changed vs v3.1.1

- **`clickFlutterAt(page, x, y)`** — taps the Flutter canvas through `flt-glass-pane` bounding box instead of raw viewport `page.mouse.click`, which never reached Tab widgets reliably.
- **`coords` block in `scenes.json`** — single source of truth for session TabBar (y≈88), profile TabBar (y≈128, scrollable/left-aligned), shell tabs, Map button, Add to My Plan. Actions reference `"coord": "sessionQa"` keys.
- **`mergeDwellScenes`** — session scenes 2+3+4 and profile 8+9 run as one continuous URL visit with multiple stages; eliminates fragile tab handoffs at scene boundaries while keeping 10 TTS mp3s unchanged.
- **`tabSettleMs: 450`** — wait after each `clickTab` for Material tab ink animation.
- **`scripts/calibrate-clicks.mjs`** — headed sweep (`npm run calibrate`) writes PNG proofs to `output/calib/` and `suggested-coords.json`.

## What v3.1.1 changed vs v3.1 (click/scroll fix)

- **`navigate()` is now navigateIfNeeded** — session detail scenes 3 and 4 both point at `/session/s-001` and profile scene 9 points at `/profile`. A redundant `history.pushState` rebuilt the route and reset the `TabController` back to Overview / You, so the tab the previous scene clicked was lost. `walkthrough.mjs::navigate()` now skips the pushState when the current URL already matches the target and logs `skip_nav url=…`.
- **`scrollFlutter` helper** — Flutter web paints inside a `<canvas>`; `window.scrollTo` silently no-ops. `scrollFlutter` parks the mouse at (960, 540), ticks small `mouse.wheel` events (auto-sized from `dy`) with short delays so Flutter's scroll physics can breathe, and optionally falls back to two `keyboard.press('PageDown')` calls when a stubborn scene refuses to move.
- **`midNarration` stage kind** — each stage can now declare `midNarration: {kind: "scroll", atRatio: 0.5, dy: 480, …}`. `runStage` splits the narration wait around the action so Happening Now / Q&A list / Logistics buttons / venue amenities / Day 2-3 / passports / a11y all reveal themselves **while** the narrator is describing them (used to be a jarring post-narration scroll).
- **Cursor / click alignment** — `overlay.js` now subtracts the actual SVG arrow tip offset (2, 2) from `translate3d` instead of (4, 4), and `clickWithRipple` fires real clicks as `mouse.move + mouse.down/up` so the browser cursor position matches the visible synthetic cursor tip.
- **Tab-click retry** — `clickWithRipple` retries a `clickTab` real click at `y + 2` (200 ms later) to catch the case where Flutter's `TabBar` swallowed the first click by a hair. Scenes 3, 4 and 9 additionally declare `expectTabIndex` + `tabClickIfStale` so `runScene` re-asserts the correct tab immediately after a same-URL `skip_nav`.

## What v3.1 changed vs v3

- **Opens on Discover** — no onboarding frame (`bootUrl` in `scenes.json`).
- **No highlight rings** — cursor + optional label chip only; `showRing` is never called.
- **Real UI clicks** — Session Detail tabs (Overview → Q&A → Logistics), Map button, Add to My Plan, Profile tabs (You → Progress → Settings).
- **Multi-stage scenes** — scenes 1, 4, 6, and 9 use `stages[]` in `scenes.json`; `walkthrough.mjs` emits per-stage `audioStartAtVideoSec`; `build-audio-track.mjs` N-slices each scene mp3.
- **2 s pre-click hold** on scene transitions; ~500 ms on internal tab clicks.
- **New tour flow** — Discover → Session (3 tabs) → Venue Map → Ask Flo (2 queries) → My Plan → Profile (3 tabs) → Outro.

## What v3 changed vs v2

- **Paint-gated narration.** Each scene's audio only starts after the target page has painted + settled (~1.2s), so the voice-over never talks about scene N while scene N-1 is still on screen. Timings are captured in `output/timings.json` and re-assembled into `output/narration.mp3` with per-scene silence gaps by `scripts/build-audio-track.mjs`.
- **On-screen highlights.** Every scene has a pulsing ring drawn on the widget being described (announcement banner, session card, sticky actions, conflict card, notes, etc). Coordinates live in [`scenes.json`](scenes.json) so recalibrating the UI is a one-file diff.
- **Synthetic cursor + click ripples.** From scene 2 onward a soft arrow tracks the narrator's focus. At the end of each scene it animates to the *next* interaction and drops a click ripple, so viewers see where navigation is going before it happens.
- **Live demo data.** [`seed.js`](seed.js) now writes:
  - a filled `NetworkingCard` inside `flo_compass_profile` (scene 8 shows real fields + QR),
  - 3 bookmarked sessions in `flo_compass_plan` (fixes a v2 key typo that silently blanked My Plan; 2 sessions overlap so `ConflictCard` renders),
  - `notesBySessionId` inside `flo_compass_engagement` (My Plan Notes section shows 2 excerpts),
  - one published `flo_organizer_announcements` entry (Discover shows a live banner).
- **Expanded narration.** ~241 words across 10 scenes (was ~180). Scene 5 in particular calls out the bookmarked sessions, conflict, and private notes.
- **Duration gate.** `build_video.sh` warns when the MP4 is outside 115-125s; `walkthrough.mjs` auto-holds the outro slate when the walk finishes short.

## Requirements

- Node 18+ (already available inside WSL2 Ubuntu 24.04)
- Playwright's bundled Chromium (installed via `npx playwright install`)
- Local Tier 2 Docker/nginx on `:8080` (`bash scripts/wsl_deploy.sh` in WSL)
- Network access to Microsoft's edge-tts endpoint

The pipeline runs equally well from WSL or Windows PowerShell as long as Node is on `PATH`. All commands below use WSL-style paths.

## Prerequisite: start the local Tier 2 stack

Run once (in WSL) before invoking the pipeline:

```bash
bash scripts/wsl_deploy.sh
# or manually: docker compose up --build
# Verify: curl http://localhost:8080/health -> {"status":"ok"}
```

## Install

```bash
cd tools/demo
npm install
npx playwright install --with-deps chromium
```

## Run

```bash
npm run calibrate   # optional: headed tab-row sweep -> output/calib/*.png
npm run check-server   # verify localhost:8080/health is up
npm run tts            # per-scene mp3s + dwell.json + captions.srt (NO narration.mp3 yet)
npm run record         # Playwright walkthrough -> scene-recording.webm + timings.json
npm run build          # build-audio-track (gapped narration + re-timed srt) -> ffmpeg mux
```

Or in one shot:

```bash
npm run all
```

Sanity-check the output:

```bash
node -e "console.log(require('ffprobe-static').path)" \
  | xargs -I {} {} -v error -show_entries format=duration \
      -of default=noprint_wrappers=1:nokey=1 ../../hackathon-docs/video.mp4
```

## Overrides

| Variable | Default | Used by | Notes |
|---|---|---|---|
| `FLO_TTS_VOICE` | `en-IN-PrabhatNeural` | `run-tts.mjs` | Male Indian English neural voice. Try `en-GB-RyanNeural`, `en-US-DavisNeural`, or `en-US-GuyNeural` for alternatives. |
| `FLO_TTS_RATE` | `+58%` | `run-tts.mjs` | v3.1 companion tour lands ~76s narration + ~48s overhead at 124s MP4. Bump to `+65%` if you extend script. |
| `FLO_TTS_PAD` | `0.3` | `run-tts.mjs` | Seconds of scene-tail padding (kept for compatibility; gapping is now done by `build-audio-track`). |
| `FLO_DEMO_BASE_URL` | `http://localhost:8080` | all scripts | Point at Tier 1 (`:3000`), Azure, or any preview. |
| `FLO_BURN_CAPTIONS` | `0` | `build_video.sh` | `1` = burn captions into the picture (no soft track). |

Example duration retry:

```bash
FLO_TTS_RATE=+15% npm run tts
npm run record
npm run build
```

`output/render.log` accumulates every render invocation with per-scene durations, overlay events, warnings, and the final MP4 size - useful when triaging.

## Files

```
tools/demo/
  package.json              # devDependencies only; no runtime output artifacts
  narration.txt             # 10 [SCENE N] blocks, ~241 words
  transcript.md             # human-readable scene / URL / highlight / narration table
  scenes.json               # NEW - viewport, per-scene URL + highlight rings + nextClick coords
  seed.js                   # localStorage seeds injected via addInitScript (v3: plan+notes+card+announcement)
  overlay.js                # NEW - window.__floDemo helpers (rings, cursor, ripples)
  walkthrough.mjs           # Playwright driver (paint-gated state machine; emits timings.json)
  build_video.sh            # ffmpeg mux; calls build-audio-track.mjs first
  scripts/
    calibrate-clicks.mjs   # NEW v3.1.2 — headed tab coord sweep + suggested-coords.json
    check-server.mjs        # curl /health, fail fast with instructions
    run-tts.mjs             # edge-tts render + ffprobe timing + captions.srt
    build-audio-track.mjs   # NEW - assemble gapped narration.mp3 from timings.json + re-time SRT
    outro.html              # scene 10 title slate loaded via file://
  output/                   # .gitignored - mp3s, WebM, MP4 intermediates, timings.json, render.log
```

## What the seed writes (v3)

`seed.js` runs before Flutter's `main()` and populates:

| localStorage key | Value | Why |
|---|---|---|
| `flutter.flo_consent_version` | `"2026-07-11"` (JSON string) | Matches `kPrivacyPolicyVersion`; skips `/consent` redirect |
| `flutter.flo_consent_accepted_at` | epoch millis | Matches `LocalUserStore` int format |
| `flutter.flo_compass_profile` | double-JSON `UserProfile` incl. `networkingCard` | Engineer + genai/cursor/leadership, `onboardingComplete: true`; Connect edit/share show sample card |
| `flutter.flo_compass_app_settings` | double-JSON `AppSettings` | `tourLastSeenVersion: 1` skips the product tour overlay |
| `flutter.flo_compass_plan` | JSON list `["s-001","s-011","s-025"]` (setStringList) | 3 bookmarked Day-1 sessions; s-001 vs s-011 overlap -> `ConflictCard` renders |
| `flutter.flo_compass_engagement` | double-JSON `EngagementSnapshot` incl. `notesBySessionId` | My Plan Notes section shows 2 excerpts; session detail Notes preview populated |
| `flutter.flo_organizer_announcements` | double-JSON list of one `OrganizerAnnouncement` (status=published) | Discover shows the `PublishedAnnouncementBanner` |
| `flutter.flo_tour_seen_v1` | `true` | Legacy sentinel; harmless if the app ignores it |

## Scene → URL map (v3.1.1 companion tour)

Tab click x-coords come from the DOM order in [`lib/features/session_detail/session_detail_screen.dart`](../../lib/features/session_detail/session_detail_screen.dart) L208-231 (Overview=620, Logistics=960, Q&A=1320, all at y=106) and [`lib/features/profile/profile_screen.dart`](../../lib/features/profile/profile_screen.dart) L218-232 (You=380, Progress=620, Settings=900, all at y=106). Scenes marked *no-nav* rely on `navigate()`'s same-URL skip to preserve the prior scene's tab.

| # | URL | Real click | midNarration scroll | Cursor focus |
|---|---|---|---|---|
| 1 | `/discover?day=Day%201&sort=soonest` | Session card (960, 580) | dy=650 (reveal Happening Now) | Announcement → Learning Paths |
| 2 | `/session/s-001` Overview | Q&A tab (1320, 106) | — | Abstract, tags, notes |
| 3 | `/session/s-001` Q&A (*no-nav*) | Logistics tab (960, 106) | dy=480 (reveal Q&A list) | Q&A prompts |
| 4a | `/session/s-001` Logistics (*no-nav*) | Map button (820, 780) | dy=420 (reveal buttons) | Logistics actions |
| 4b | `/map?room=ven-G01` | — | dy=380 (reveal amenities) | Venue map + amenities |
| 5 | `/companion?q=What's%20happening%20now%3F` | — | — | Citation cards |
| 6 | `/companion?q=Plan%20my%20Day%201` (force reload) | Add to My Plan (420, 820) | — | Plan draft |
| 7 | `/my-plan` | — | dy=520 (reveal Day 2/3) | Bookmarks, conflicts, notes |
| 8 | `/profile` You | Progress tab (620, 106) | — | Interests, QR card |
| 9a | `/profile` Progress (*no-nav*) | Settings tab (900, 106) | dy=400 (reveal passports) | XP → passports |
| 9b | `/profile` Settings (*no-nav*) | — | dy=380 (reveal a11y) | Appearance, a11y, notifications |
| 10 | `scripts/outro.html` | — | — | Outro slate |

## Scene → URL map (v3 legacy — superseded)

## Captions modes

| `FLO_BURN_CAPTIONS` | Video picture | Soft track in MP4 | Sidecar `.srt` |
|---|---|---|---|
| unset / `0` (**default**) | Clean, no overlay | Yes (`mov_text`, off by default in players) | Yes (`hackathon-docs/video.srt`) |
| `1` | Captions burned in | No (already visible) | Yes (`hackathon-docs/video.srt`) |

## Guardrails observed

- No new pub deps; nothing touches `pubspec.yaml`, `docker/**`, `web/**`, `assets/data/**`, `.gitlab-ci.yml`.
- No secrets: edge-tts needs no API key, Playwright hits a local Docker instance.
- `tools/demo/output/` and `tools/demo/node_modules/` are gitignored.
- All coordinates in `scenes.json` are CSS pixels in the recording viewport (1920x1080); recalibrate there without touching the driver.
