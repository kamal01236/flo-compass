**!!! ATTENTION – THIS IS IMPORTANT !!!**

Carefully read this file in its entirety! 

We will not accept deviations from the required deliverables or support you with project setup basics because "you missed it in the document".

# Required Deliverables 

Each team must submit the following deliverables, and all deliverables (including video, augmentation log, etc.) must be uploaded to your team’s repository by the submission deadline. This repo, filled with all artifacts relevant to your solution. 



Within this repo, under a folder called “hackathon-docs”, you **must** include the following items (this is **mandatory**, including using the **correct filenames**): 

* **hackathon-docs/HACKATHON-README.md** (Usage & Setup Guide) - We will provide a template HACKATHON-README.md in GitHub-style markdown in the root folder of the OurCode repository we provide for you. Fill it out to include this information: 
  * List of team name & team members 
  * Link to your OurCode repository 
  * A short summary describing your team’s “AI-first workflow” when tackling the hackathon’s missions 
* **hackathon-docs/augmentation-log.md** (AI Usage Documentation) - A dedicated document that captures how Cursor was used throughout the SDLC. This log should document: 
  * What you attempted to do using Cursor 
  * How Cursor responded 
  * What was accepted, modified, or rejected 
  * Any hallucinations or incorrect suggestions identified 
  * How participants corrected or steered the AI 
  * NOTE: The structure of the log is intentionally left flexible. Teams are encouraged to use Cursor itself to help create and refine this document. 
* **hackathon-docs/video.mp4** A Demo Video (2 Minutes – hard maximum!) - A short demo video, including a voice track, that: 
  * Shows and explains the approach 
  * Shows and explains the results 
  * Highlights key decisions or moments where Cursor materially influenced the outcome 
  * Briefly summarizes learnings from AI-assisted development 
  * Hint: Make sure that the video & speech are clear and easily understandable – speeding up the video & voice might it easier to stay within 2 minutes, but it will hurt your polish score 

# Starter Kit

Minimal starting point for hackathon teams — a Flutter (web) hello-world app.

## What's included

- `lib/main.dart` — hello-world Flutter app
- `web/` — Flutter web shell (`index.html`, `manifest.json`, icons)
- `pubspec.yaml` — app metadata & dependencies (requires Flutter 3.44.0 / Dart 3.10+)
- `docker/Dockerfile` — multi-stage build: compiles the Flutter web app, then serves `build/web` with nginx
- `.gitlab-ci.yml` — CI/CD pipeline (build → push → deploy to Azure Container Apps)

## Local development & testing (WSL2 only)

Develop and run **local** Tier 1/Tier 2 validation inside **Ubuntu 24.04 WSL2** with Flutter, Docker, and Docker Compose installed in WSL — not Docker Desktop on Windows.

**Production deployment is unchanged:** push to default branch → GitLab CI → ARM template → Azure Container Apps.

Open a WSL shell in the repo, then:

**Flutter dev server** (hot reload, port 3000):

```bash
flutter pub get
bash scripts/dev_wsl.sh
# Open http://localhost:3000 from Windows browser
```

**Local Docker smoke** (same `docker/Dockerfile` as CI, port 8080 — not ARM deploy):

```bash
docker compose up --build
# Open http://localhost:8080
```

## How deployment works

Every push to the default branch triggers the GitLab CI pipeline which:
1. Builds the Docker image
2. Pushes it to the container registry
3. Deploys to Azure Container Apps