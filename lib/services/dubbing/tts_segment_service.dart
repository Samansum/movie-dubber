import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/dub_models.dart';
import '../../models/srt_models.dart';
import '../edge_tts_service.dart';

/// Measures a rendered audio file. Returns the duration in seconds, or `null`
/// when it cannot be determined.
typedef AudioDurationProbe = Future<double?> Function(String path);

/// STEP 3 — Renders every SRT cue into its own MP3 with Edge TTS.
///
/// Reuses [EdgeTtsService.synthesize] so the dubbing output uses exactly the
/// same neural voices as the voice previews on the New Dub screen.
class TtsSegmentService {
  final EdgeTtsService _tts;

  // Not `const`: `EdgeTtsService()` is a singleton factory, which is not a
  // valid constant expression.
  TtsSegmentService({EdgeTtsService? tts}) : _tts = tts ?? EdgeTtsService();

  /// Khmer neural voices used when a line has no explicit gender tag.
  static final String maleVoiceId = VoiceProfile.pisethNeural.id;
  static final String femaleVoiceId = VoiceProfile.sreymomNeural.id;

  /// Picks the Edge voice for [entry] based on the voice mode and the
  /// `[M]`/`[F]` tag Gemini detected.
  ///
  /// With a single (non-auto-cast) voice selected, that voice is always used —
  /// it is an explicit user choice. Auto-cast maps male lines to Piseth and
  /// female lines to Sreymom, falling back to the male voice for untagged
  /// lines.
  static String resolveVoiceId({
    required VoiceProfile selectedVoice,
    required SpeakerGender gender,
  }) {
    if (selectedVoice.type != VoiceType.autoCast) {
      return selectedVoice.id;
    }
    return gender == SpeakerGender.female ? femaleVoiceId : maleVoiceId;
  }

  /// Synthesizes every entry and writes one MP3 per cue into [outputDir].
  ///
  /// [onProgress] receives `(completed, total)` so the UI can show progress.
  /// Returns the segments in the same order as [entries].
  Future<List<DubbingSegment>> synthesizeSegments({
    required List<SrtEntry> entries,
    required VoiceProfile selectedVoice,
    required String outputDir,
    required AudioDurationProbe durationProbe,
    double pitchHz = 0.0,
    double speedMultiplier = 1.0,
    void Function(int completed, int total)? onProgress,
  }) async {
    final dir = Directory(outputDir);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    // The cadence slider shapes how the voice reads; `atempo` later only
    // stretches the result to fit the subtitle slot.
    final rate = formatEdgeRate(speedMultiplier);
    final pitch = formatPitch(pitchHz);

    final segments = <DubbingSegment>[];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final voiceId =
          resolveVoiceId(selectedVoice: selectedVoice, gender: entry.gender);

      final audioPath = '${dir.path}/line_${entry.index}.mp3';

      // EdgeTtsService only caches preview samples, so each line is written
      // to its own file here.
      final bytes = await _tts.synthesize(
        text: entry.text,
        voice: voiceId,
        rate: rate,
        pitch: pitch,
      );
      await File(audioPath).writeAsBytes(bytes, flush: true);

      // Measure the real rendered duration so `atempo` can fit it to the slot.
      final duration = await durationProbe(audioPath);

      segments.add(
        DubbingSegment(
          audioPath: audioPath,
          startSeconds: entry.startSeconds,
          durationSeconds: duration ?? entry.slotDuration,
          targetSlotDuration: entry.slotDuration,
          gender: entry.gender,
        ),
      );

      onProgress?.call(i + 1, entries.length);
    }

    debugPrint(
      '[TtsSegmentService] Synthesized ${segments.length} segments at '
      '${speedMultiplier}x cadence into $outputDir',
    );
    return segments;
  }

  /// Converts a Hertz offset into the Edge TTS `+12Hz` / `-3Hz` notation.
  static String formatPitch(double hz) {
    if (hz == 0) return '+0Hz';
    final rounded = hz.round();
    final sign = rounded > 0 ? '+' : '-';
    return '$sign${rounded.abs()}Hz';
  }

  /// Converts a cadence multiplier (e.g. `1.05`) into Edge's `+5%` notation.
  ///
  /// Edge only accepts a percentage delta, so the multiplier is expressed as a
  /// signed integer percentage.
  static String formatEdgeRate(double speedMultiplier) {
    final percent = ((speedMultiplier - 1.0) * 100).round();
    // Edge expects an explicit sign, including for a zero delta ('+0%').
    final sign = percent < 0 ? '-' : '+';
    return '$sign${percent.abs()}%';
  }
}
