import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../models/dub_models.dart';
import '../../models/srt_models.dart';
import '../edge_tts_service.dart';
import 'ffmpeg_dubbing_service.dart';

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
    int concurrency = 10,
    bool Function()? isCancelled,
    void Function(int completed, int total)? onProgress,
  }) async {
    final dir = Directory(outputDir);
    if (!dir.existsSync()) await dir.create(recursive: true);

    final rate = formatEdgeRate(speedMultiplier);
    final pitch = formatPitch(pitchHz);

    final results = List<DubbingSegment?>.filled(entries.length, null);
    var next = 0;
    var completed = 0;
    Object? failure;
    StackTrace? failureStack;

    Future<void> worker() async {
      while (failure == null && !(isCancelled?.call() ?? false)) {
        final i = next++;
        if (i >= entries.length) return;
        try {
          results[i] = await _renderEntry(
            entry: entries[i],
            selectedVoice: selectedVoice,
            dirPath: dir.path,
            rate: rate,
            pitch: pitch,
            durationProbe: durationProbe,
          );
          onProgress?.call(++completed, entries.length);
        } catch (e, st) {
          failure ??= e;
          failureStack ??= st;
          return;
        }
      }
    }

    final workers = math.min(concurrency, entries.length);
    await Future.wait(List.generate(workers, (_) => worker()));

    if (failure != null) Error.throwWithStackTrace(failure!, failureStack!);
    if (isCancelled?.call() ?? false) throw const FfmpegCancelledException();

    return results.cast<DubbingSegment>(); // same order as entries
  }

  Future<DubbingSegment> _renderEntry({
    required SrtEntry entry,
    required VoiceProfile selectedVoice,
    required String dirPath,
    required String rate,
    required String pitch,
    required AudioDurationProbe durationProbe,
  }) async {
    final voiceId =
    resolveVoiceId(selectedVoice: selectedVoice, gender: entry.gender);
    final audioPath = '$dirPath/line_${entry.index}.mp3';

    final bytes = await _withRetry(() async {
      final b = await _tts.synthesize(
          text: entry.text, voice: voiceId, rate: rate, pitch: pitch);
      if (b.isEmpty) throw StateError('Empty TTS audio for cue ${entry.index}');
      return b;
    });
    await File(audioPath).writeAsBytes(bytes, flush: true);

    final duration = await durationProbe(audioPath);
    return DubbingSegment(
      audioPath: audioPath,
      startSeconds: entry.startSeconds,
      durationSeconds: duration ?? entry.slotDuration,
      targetSlotDuration: entry.slotDuration,
      gender: entry.gender,
    );
  }

  Future<T> _withRetry<T>(Future<T> Function() fn, {int attempts = 3}) async {
    for (var attempt = 1;; attempt++) {
      try {
        return await fn();
      } catch (_) {
        if (attempt >= attempts) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * attempt * attempt));
      }
    }
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
