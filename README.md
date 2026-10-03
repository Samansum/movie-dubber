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

### 2. Dubbing Queue (Video Processing)
* **Header & Live Pulse**: Real-time sync indicator (`SYNC LIVE`) with count summary pills for Active, Queued, and Completed jobs.
* **Active Processing Card**:
  * Gradient progress bar with live percentage (`64%`).
  * **4-Stage AI Pipeline Progression Flow**:
    1. *Extract audio*: Demuxed 48kHz WAV audio stream (Completed).
    2. *Transcribe and translate*: Gemini 1.5 Khmer translation (In Progress, animated spinner).
    3. *Generate audio*: Edge-TTS Khmer synthesis (Next Up).
    4. *Build video*: Remux & Lip-sync (Pending).
  * **Live Console**: Streaming event log with terminal styling.
  * **Terminate Process**: Action button with confirmation modal.
* **Queued & Completed Cards**: Displays queued jobs and recently completed videos with one-tap access to the player.

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
