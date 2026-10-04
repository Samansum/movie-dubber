# CineDub AI — Khmer Video Dubber Studio

A Flutter mobile app that turns an arbitrary video into a **Khmer-dubbed** video. Pick a clip, choose a voice model, and a real four-stage pipeline extracts the audio, asks **Gemini** to transcribe and translate it to natural spoken Khmer as SRT, synthesizes each line with **Edge TTS**, then time-aligns and muxes the result back onto the video with **FFmpeg**.

Built from the Google Stitch design *Khmer Video Dubber Studio* (Project ID `14402980809088841728`) on the **Obsidian Cinema AI** design system.

---

## 🧱 Pipeline Stack

The dubbing engine is composed of three external services and one media toolchain, each behind a thin Dart wrapper so the UI never talks to them directly.

| Stage | What it does | Library | Wrapper |
|---|---|---|---|
| **1. Extract audio** | Demux the source video to a 48kHz mono PCM WAV | `ffmpeg_kit_flutter_new` | `services/dubbing/ffmpeg_dubbing_service.dart` |
| **2. Transcribe & translate** | Audio ➜ Khmer SRT using the model + key chosen in Settings | `google_generative_ai` | `services/dubbing/gemini_translation_service.dart` |
| **3. Generate audio** | Synthesize every SRT cue to its own MP3 (Edge neural voices) | `edge_tts` (via `EdgeTtsService`) | `services/dubbing/tts_segment_service.dart` |
| **4. Build video** | `atempo` stretch ➜ `adelay` align ➜ `amix` merge ➜ mux with `-c:v copy` | `ffmpeg_kit_flutter_new` | `services/dubbing/ffmpeg_dubbing_service.dart` |

Supporting pieces:
* **Prompt** — `prompts/khmer_dubbing_prompt.dart` holds the Gemini system instruction (transcription, `[M]`/`[F]` speaker-gender tagging, and spoken-Khmer translation rules). Kept in its own file so it can be tuned without touching code.
* **SRT cleaner** — `services/dubbing/srt_parser.dart` is a Dart port of the Python helpers: it strips invisible unicode, normalizes/repairs timestamps (pysrt-style), collapses blank lines, removes markdown fences, and parses cues into `SrtEntry` models.
* **Orchestrator** — `services/dubbing/dubbing_pipeline.dart` runs the four stages, streams progress via `DubbingProgress`, supports cancellation, and writes intermediates (audio, `.srt`, per-line MP3s, final MP4) to a per-job folder. Each stage runs through `_runStage`, which tags any failure with its stage index (`DubbingStageException`) so the error can always be attributed to a specific step.
* **Gender-aware casting** — the `[M]`/`[F]` tag Gemini emits drives voice selection in **Auto-Cast** mode (Piseth ↔ Sreymom). Picking a single voice explicitly overrides it.

### Stage tracking & failure reporting

A job is tracked stage-by-stage and **stops at the first stage that throws**:

| Stage | Zero-based index | Failure attribution |
|---|---|---|
| Extract audio | 0 | `FfmpegException` (command + raw log) |
| Transcribe and translate | 1 | `GeminiTranslationException` |
| Generate audio | 2 | `Edge TTS` / `FileSystemException` |
| Build video | 3 | `FfmpegException` (command + raw log) |

* **Never reported as done** — a failed job is stored in `AppState.failedTasks`, kept separate from `completedTasks`, so the Queue screen's "Recently completed" list (and its "Done" pill) only ever contains successful renders. Failed jobs get their own **Failed Jobs** section.
* **Correct stage states** — stages before the failure are `completed`, the failing stage is `failed`, and every later stage drops back to `pending`. No stage is left spinning after the pipeline stops.
* **Raw error preserved** — `DubbingError` keeps the untruncated detail (for FFmpeg: both the failing command *and* the raw log) plus the Dart stack trace. `DubbingTask.errorReport` renders it as a monospaced technical report.
* **Copy to clipboard** — `widgets/pipeline_error_card.dart` shows the raw message in a scrollable, selectable panel and offers a **Copy error report** button (`Clipboard.setData`) for technical users.

> Pre-flight failures (missing source file, no usable Gemini key) are attributed to the stage that would have run and carry a `details` string explaining the check that failed.

### Key runtime dependencies

| Package | Version | Purpose |
|---|---|---|
| `ffmpeg_kit_flutter_new` | ^4.6.4 | Audio extraction, time-stretch, mix & mux |
| `google_generative_ai` | ^0.4.7 | Transcription + Khmer translation |
| `edge_tts` | ^0.1.0 | Khmer neural TTS synthesis |
| `audioplayers` | ^6.8.1 | Voice-sample playback |
| `video_player` | ^2.11.1 | Video preview & final playback |
| `file_picker` | ^8.1.7 | Source-video selection |
| `shared_preferences` | ^2.5.5 | Persist settings & API-key pool |
| `path_provider` | ^2.1.6 | App documents dir for job artifacts |

`http` is also declared (it backs the Gemini SDK and Edge TTS networking) but is not imported directly by app code.

---

## 🔐 Gemini API Keys

The Settings tab manages a **pool** of Gemini keys with rotation strategies (`Rate-Limit Balanced`, `Round-Robin`, `Failover Priority`) to get around RPM/TPM limits during full-length dubbing. The real token is stored locally and used only for requests — the UI always shows a masked form (`AIzaSyD••••••`). The model used for translation is the one selected in Settings (`Gemini 2.5 / 3.5 / 3.7 / 3.8 Flash`).

> **Note:** The Gemini API sends audio as base64 `inlineData`. There is a ~20MB request limit, so very long videos should be split into chunks (or use the Files API) before feeding a full-length track.

---

## 🎨 Design System: Obsidian Cinema AI

* **Canvas Base**: `#0B0F17` (Deep Obsidian)
* **Surface Containers**: Lowest `#0A0E16` • Low `#181C24` • Default `#1C2028` • High `#262A33` • Highest `#31353E`
* **Signal Palette**:
  * **Electric Violet** (`#7C3AED` / `#D2BBFF`): Core AI actions, Gemini compute pipelines.
  * **Cyber Cyan** (`#06B6D4` / `#4CD7F6`): Acoustic waveforms, audio scrubbers, telemetry.
  * **Hyper Emerald** (`#10B981` / `#4EDEA3`): Quota status, verification checkmarks, completed outputs.
* **Typography**: Headlines **Plus Jakarta Sans** (tight geometric, `-0.02em`); telemetry **Inter** (tabular figures, all-caps micro-badges).
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
* **Driven by the real pipeline**: progress, the highlighted stage and the console log all come from live `DubbingProgress` callbacks — see [Pipeline Stack](#-pipeline-stack).
* **Failure Handling**: jobs without a source file or a usable Gemini API key fail fast with a readable reason, and the queue always promotes the next job so it never deadlocks.
* **Header & Live Pulse**: Real-time sync indicator (`SYNC LIVE`) with count summary pills for Active, Queued, and Completed jobs.
* **Active Processing Card** (only rendered while a job is running):
  * Gradient progress bar with live percentage.
  * **4-Stage AI Pipeline Progression Flow**:
    1. *Extract audio*: Demuxed 48kHz WAV audio stream.
    2. *Transcribe and translate*: Gemini Khmer translation.
    3. *Generate audio*: Edge-TTS Khmer synthesis.
    4. *Build video*: Remux & lip-sync.
  * **Live Console**: Streaming event log with terminal styling.
  * **Terminate Process**: Action button with confirmation modal; aborting the current render cancels the FFmpeg session and promotes the next queued job.
* **Queued & Completed Cards**: **Queued Videos** and **Recently Completed** sections are hidden whenever they have no items, and an empty-state card is shown when there are no jobs at all.
* **Remove from Queue**: every queued card has a full-width **Remove from queue** action (with confirmation modal) so the user can drop a waiting video before it ever starts. Removing a job renumbers the remaining queue positions and never interrupts the running render.

### 3. Completed Dub (Player & Save to Gallery)
> **Status: UI mockup.** This screen is not yet wired to the rendered output — it still renders hard-coded telemetry (`54.2 MB`, `1080p 60fps`) and static segments. The pipeline already produces a real output path on each completed job (`DubbingTask.outputPath`), which is what this screen should consume next.

* **Status & Telemetry Banner**: Rendering & sync complete banner with file specs.
* **16:9 Video Player Viewport**:
  * Full video player frame with timecode overlays (`REC 01:14`).
  * Play / Pause floating glass button with glowing violet halo.
  * **Dual-Language Live Subtitles**: Real-time Khmer subtitles (*«យើងបានបញ្ចប់បេសកកម្មដោយជោគជ័យ!»*) with English reference and subtitle toggle (**KM SUB** / **SUB OFF**).
  * **Audio Track Switcher**: Instant switching between **Khmer AI** and **Original English**.
  * **Interactive Scrubber**: Seek bar with current time and total duration.
* **Dialogue Segments QC**: Timestamped list of translated lines — these can be fed directly from the parsed `SrtEntry` list the pipeline already returns.
* **Primary Save to Gallery Action**:
  * Multi-state CTA: **Save to Gallery** ➔ **Saving to /DCIM...** ➔ **Saved in Photo Library!** (with emerald feedback).
  * Share video and New Dub shortcuts.

### 4. Dubbing Settings (Gemini API Keys & Config)
* **Gemini API Keys Pool**: Multi-key management to bypass RPM/TPM restrictions during full-length dubbing.
* **Key Cards**: Displays alias, masked token (`AIzaSyD••••••`), status (Active, Standby, Cooldown), RPM usage telemetry, and ping latency in milliseconds.
* **Add Gemini API Key Card**: Input fields for key description and token with visibility toggle, live validation, and **Verify & Save** action.
* **Model & Engine Config**: Choice chips for the default Gemini model (`Gemini 2.5 Flash`, `3.5 Flash`, `3.7 Flash`, `3.8 Flash`), translation tones (`Cinematic Dynamic`, `Natural Dialogues`, `Documentary Formal`), and key rotation strategies (`Rate-Limit Balanced`, `Round-Robin`, `Failover Priority`). The selected model is the one the pipeline actually calls.

---

## 📂 Project Structure

```
lib/
├── main.dart                     # App entry + root MaterialApp
├── models/
│   ├── dub_models.dart           # VoiceProfile, VideoAsset, PipelineStage, DubbingTask, ApiKeyItem
│   └── srt_models.dart           # SrtEntry, SpeakerGender, DubbingSegment
├── prompts/
│   └── khmer_dubbing_prompt.dart # Gemini transcription + Khmer translation system prompt
├── screens/
│   ├── main_navigation_screen.dart
│   ├── new_dub_screen.dart       # Pick video, choose voice, start job
│   ├── queue_screen.dart         # Active / queued / completed + terminate & remove
│   ├── completed_player_screen.dart
│   └── settings_screen.dart      # Gemini keys, model & engine config
├── services/
│   ├── app_state.dart            # App state: settings, queue, pipeline orchestration
│   ├── edge_tts_service.dart     # Edge TTS synthesis + sample playback
│   └── dubbing/                  # The dubbing pipeline
│       ├── dubbing_pipeline.dart       # Orchestrates the 4 stages
│       ├── ffmpeg_dubbing_service.dart # FFmpeg: extract, atempo/adelay/amix, mux, cancel
│       ├── gemini_translation_service.dart # Gemini transcription + translation
│       ├── srt_parser.dart             # SRT clean/normalize/parse
│       └── tts_segment_service.dart    # Per-cue TTS + gender-based voice routing
├── theme/                        # Colors, typography, theme
└── widgets/                      # Shared UI widgets
    ├── pipeline_stage_tile.dart  # One stage row (completed/running/failed/pending)
    └── pipeline_error_card.dart  # Raw error report + copy-to-clipboard button
```

---

## 🧪 Testing

* `flutter test` runs the suite (58 tests in `app_state_queue_test.dart` + `srt_parser_test.dart`).
  * **Queue tests** drive the real `AppState` pipeline orchestration through an injectable fake pipeline (FIFO promotion, terminate/cancel, remove-from-queue, renumbering, fast-fail on missing source file / API key, key-pool rotation).
  * **Stage error-tracking tests** assert the failure contract: a failed stage is never recorded as a completed render, the failing stage is marked `failed` while earlier stages are `completed` and later ones `pending`, each of the four stage indices maps to the right failing step, the raw FFmpeg command + log survive verbatim into the copyable report, and a failed job still promotes the next queued job.
  * **SRT / parser tests** cover timestamp normalization, blank-line collapsing, invisible-character removal, `[M]`/`[F]` gender parsing, Gemini model-id mapping, voice routing, and `atempo` speed math — no network required.
* The bundled `widget_test.dart` smoke test loads Unsplash images that the Flutter test binding blocks (HTTP 400), so it fails independently of the pipeline; it can be removed or given mocked network images.

---

## ⚠️ Known Gaps / Next Steps

* **Completed Player is a mockup** — it is not yet bound to `DubbingTask.outputPath`; telemetry and segments are hard-coded (see screen 3 above).
* **Long-video limit** — Gemini receives audio as base64 `inlineData` capped at roughly 20MB. Full-length feature films need chunked audio (with cue timestamps offset per chunk) or the Gemini Files API.
* **`widget_test.dart` smoke test** fails independently of the pipeline because it loads remote Unsplash images that the Flutter test binding blocks.
* **`withOpacity` deprecation** — `flutter analyze` reports 86 `deprecated_member_use` infos for `Color.withOpacity` across the UI files (pre-existing, cosmetic; `withValues(alpha:)` is the replacement).
* **Retry/back-off** — a Gemini failure fails the job outright today; there is no automatic retry against the next key in the pool.

---

## 🚀 Running the App

### Prerequisites
* Flutter SDK (3.10.0 or higher — developed against 3.47.x / Dart 3.13)
* Dart SDK (3.0.0 or higher)
* Android Studio / Xcode / Chrome for testing
* **Android**: `ffmpeg_kit_flutter_new` ships prebuilt binaries and requires the NDK; the project's `build.gradle.kts` already pins `ndkVersion`, so a standard Flutter Android build works. iOS requires the usual ffmpeg-kit pod install.

### Setup
1. Add at least one **Gemini API key** in the Settings tab (the pipeline fails fast without one).
2. Pick the default Gemini model and voice/tuning options.

### Quick Start
```bash
# 1. Install dependencies
flutter pub get

# 2. Run on a connected device or emulator
flutter run
```

> The dubbing pipeline makes **live network calls** to the Gemini and Edge TTS endpoints, so it requires an internet connection and real API keys.
