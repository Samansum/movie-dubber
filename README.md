# CineDub AI — Khmer Video Dubber Studio (Flutter Mobile App)

A mobile Flutter application engineered from the Google Stitch design (**Khmer Video Dubber Studio**, Project ID `14402980809088841728`). Built with the **Obsidian Cinema AI** design system.

---

## 🎨 Design System: Obsidian Cinema AI

* **Canvas Base**: `#0B0F17` (Deep Obsidian)
* **Surface Containers**:
  * Lowest: `#0A0E16`
  * Low: `#181C24`
  * Default: `#1C2028`
  * High: `#262A33`
  * Highest: `#31353E`
* **Signal Palette**:
  * **Electric Violet** (`#7C3AED` / `#D2BBFF`): Core AI actions, Gemini compute pipelines.
  * **Cyber Cyan** (`#06B6D4` / `#4CD7F6`): Acoustic waveforms, audio scrubbers, telemetry.
  * **Hyper Emerald** (`#10B981` / `#4EDEA3`): Quota status, verification checkmarks, completed outputs.
* **Typography**:
  * Headlines: **Plus Jakarta Sans** (tight geometric posture, `-0.02em` tracking)
  * Telemetry & Monospace: **Inter** (tabular figures `tnum`, all-caps micro-badges)
* **Pill Geometry**: `rounded-full` controls and pill badges.

---

## 📱 Implemented Screens & Workflows

### 1. New Dub (Pick Video & Voice)
* **16:9 Cinematic Video Viewport**: Displays selected video thumbnail, resolution badge (`1080p • 60 FPS`), duration timer (`02:45`), file specs (`48.2 MB • H.264 / AAC`), interactive play/pause preview, and a **Replace** modal to switch source clips.
* **Voice Mode Selection**:
  * **Smart Multi-Speaker (Auto-Cast)**: Automated dynamic cast detection for male and female characters.
  * **Piseth Neural (Male)**: `km-KH-PisethNeural` with interactive animated audio waveform frequency bars, audio sample playback, and Khmer sample text (*«សួស្តី! ខ្ញុំជាសំឡេងបកប្រែ»*).
  * **Sreymom Neural (Female)**: `km-KH-SreymomNeural` with sample player and Khmer text (*«សូមស្វាគមន៍មកកាន់ CineDub»*).
* **Audio Tuning Controls**: Sliders for Pitch offset (-10 to +10 Hz), Speech cadence (0.8x to 1.4x), and Background Ducking (-50% to -10%) with default reset button.
* **Shimmer Gradient CTA**: **Start AI Khmer Dubbing** button initiates the pipeline and routes to the Queue monitor.
* **Form Reset After Start**: once the job is handed over to the queue, the viewport is cleared back to its empty state and the preview player is released, so the user can immediately pick the next video without any leftover state.

### 2. Dubbing Queue (Video Processing)
* **Real Data Only**: the queue starts completely empty. Every job is created from the video and voice model the user actually selected on the New Dub screen — no sample/placeholder jobs.
* **Enqueue Behaviour**: tapping **Start AI Khmer Dubbing** pushes the job onto the queue. If the pipeline is idle it starts processing right away, otherwise the job is appended to the bottom of the queue and runs once the earlier jobs finish (FIFO).
* **Real 4-Stage Pipeline**: each job runs the actual dubbing pipeline (no dummy clock). Progress, the active stage and the console log are driven by real stage callbacks:
  1. *Extract audio* — `ffmpeg_kit_flutter_new` demuxes a 48kHz mono PCM WAV.
  2. *Transcribe and translate* — the audio is sent to the **Gemini model selected in Settings** (`google_generative_ai`) with the prompt in `lib/prompts/khmer_dubbing_prompt.dart`. The raw response is cleaned (`SrtParser`) then parsed into cues.
  3. *Generate audio* — every cue is synthesized with **Edge TTS** through the existing `EdgeTtsService`, one MP3 per line. Auto-cast maps the Gemini-detected `[M]`/`[F]` tag to Piseth/Sreymom; an explicitly selected voice overrides it.
  4. *Build video* — `atempo` time-stretches each line to fit its subtitle slot, `adelay` places it on the timeline, `amix` merges them and the result is muxed onto the source video with `-c:v copy`.
* **Failure Handling**: jobs without a source file or a Gemini API key fail fast with a readable reason, and the queue always promotes the next job so it never deadlocks.
* **Header & Live Pulse**: Real-time sync indicator (`SYNC LIVE`) with count summary pills for Active, Queued, and Completed jobs.
* **Active Processing Card** (only rendered while a job is running):
  * Gradient progress bar with live percentage.
  * **4-Stage AI Pipeline Progression Flow**:
    1. *Extract audio*: Demuxed 48kHz WAV audio stream (Completed).
    2. *Transcribe and translate*: Gemini Khmer translation (In Progress, animated spinner).
    3. *Generate audio*: Edge-TTS Khmer synthesis (Next Up).
    4. *Build video*: Remux & Lip-sync (Pending).
  * **Live Console**: Streaming event log with terminal styling.
  * **Terminate Process**: Action button with confirmation modal; aborting the current render promotes the next queued job.
* **Queued & Completed Cards**: **Queued Videos** and **Recently Completed** sections are hidden whenever they have no items, and an empty-state card is shown when there are no jobs at all.
* **Remove from Queue**: every queued card has a full-width **Remove from queue** action (with confirmation modal) so the user can drop a waiting video before it ever starts. Removing a job renumbers the remaining queue positions and never interrupts the running render.

### 3. Completed Dub (Player & Save to Gallery)
* **Status & Telemetry Banner**: Rendering & sync complete banner with file specs (`1080p 60fps • 48kHz • 54.2 MB`).
* **16:9 Video Player Viewport**:
  * Full video player frame with timecode overlays (`REC 01:14`).
  * Play / Pause floating glass button with glowing violet halo.
  * **Dual-Language Live Subtitles**: Real-time Khmer subtitles (*«យើងបានបញ្ចប់បេសកកម្មដោយជោគជ័យ!»*) with English reference and subtitle toggle (**KM SUB** / **SUB OFF**).
  * **Audio Track Switcher**: Instant switching between **Khmer AI** and **Original English**.
  * **Interactive Scrubber**: Seek bar with current time and total duration (`01:50`).
* **Dialogue Segments QC**: Timestamped list of translated lines.
* **Primary Save to Gallery Action**:
  * Multi-state CTA: **Save to Gallery (54MB)** ➔ **Saving to /DCIM...** ➔ **Saved in Photo Library!** (with emerald feedback).
  * Share video and New Dub shortcuts.

### 4. Dubbing Settings (Gemini API Keys & Config)
* **Gemini API Keys Pool**: Multi-key management to bypass RPM/TPM restrictions.
* **Key Cards**: Displays alias, masked token (`AIzaSyD••••••`), status (Active, Standby, Cooldown), RPM usage telemetry, and ping latency in milliseconds.
* **Add Gemini API Key Card**: Input fields for key description and token with visibility toggle, live validation, and **Verify & Save** action.
* **Model & Engine Config**: Choice chips for Gemini models (`1.5 Pro`, `1.5 Flash`, `2.0 Flash`), translation tones (`Cinematic`, `Natural Dialogues`, `Documentary Formal`), and key rotation strategies.

---

## 🚀 Running the App

### Prerequisites
* Flutter SDK (3.10.0 or higher)
* Dart SDK (3.0.0 or higher)
* Android Studio / Xcode / Chrome for testing

### Quick Start
```bash
# 1. Navigate to the project directory
cd khmer_dubber_mobile

# 2. Get dependencies
flutter pub get

# 3. Run on your connected device or emulator
flutter run
```
