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

/// Back-off schedule applied between TTS attempts for a single cue.
///
/// The first failure waits one second, the second two seconds, and so on —
/// capped at [maxTtsAttempts] retries before the stage is failed so the user
/// can decide whether to retry manually.
const List<Duration> ttsRetryDelays = [
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 3),
  Duration(seconds: 4),
  Duration(seconds: 5),
];

/// Number of tries per cue: the initial attempt plus every entry in
/// [ttsRetryDelays].
///
/// Declared as a literal so it stays a compile-time constant — Dart forbids
/// reading `List.length` inside a `const` expression.
const int maxTtsAttempts = 6;

/// Raised when a single cue could not be synthesized within the retry budget.
///
/// Identifies the offending line so the failure surfaced on the TTS stage card
/// tells the user *which* dialogue line is the problem.
class TtsEntryException implements Exception {
  final int cueIndex;
  final String text;
  final String voiceId;

  /// Total attempts made before giving up.
  final int attempts;

  /// The last underlying error from Edge TTS.
  final Object? cause;

  const TtsEntryException({
    required this.cueIndex,
    required this.text,
    required this.voiceId,
    required this.attempts,
    this.cause,
  });

  String get summary =>
      'Could not synthesize line $cueIndex after $attempts attempts '
      '(voice $voiceId)';

  /// Full raw text for the copy-to-clipboard diagnostic.
  String get details {
    final buffer = StringBuffer()
      ..writeln('Cue index: $cueIndex')
      ..writeln('Voice:     $voiceId')
      ..writeln('Attempts:  $attempts')
      ..writeln('Text:      $text')
      ..writeln('')
      ..writeln('Last error: ${cause ?? '(none recorded)'}');
    return buffer.toString();
  }

  @override
  String toString() => summary;
}

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
  ///
  /// When [reuseExisting] is true, cues whose MP3 is already on disk are
  /// measured and reused instead of being re-synthesized. This makes a manual
  /// "Retry stage" on the TTS stage cheap: only the lines that actually failed
  /// are rendered again.
  Future<List<DubbingSegment>> synthesizeSegments({
    required List<SrtEntry> entries,
    required VoiceProfile selectedVoice,
    required String outputDir,
    required AudioDurationProbe durationProbe,
    double pitchHz = 0.0,
    double speedMultiplier = 1.0,
    int concurrency = 10,
    bool reuseExisting = false,
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
            reuseExisting: reuseExisting,
            isCancelled: isCancelled,
          );
          onProgress?.call(++completed, entries.length);
        } on TtsEntryException catch (e, st) {
          failure ??= e;
          failureStack ??= st;
          return;
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

  /// The MP3 path a cue renders to, derived from its SRT index.
  static String pathForCue(String dirPath, int cueIndex) =>
      '$dirPath/line_$cueIndex.mp3';

  Future<DubbingSegment> _renderEntry({
    required SrtEntry entry,
    required VoiceProfile selectedVoice,
    required String dirPath,
    required String rate,
    required String pitch,
    required AudioDurationProbe durationProbe,
    required bool reuseExisting,
    bool Function()? isCancelled,
  }) async {
    final voiceId =
        resolveVoiceId(selectedVoice: selectedVoice, gender: entry.gender);
    final audioPath = pathForCue(dirPath, entry.index);

    // A retry of this stage should only re-render the lines that failed.
    if (reuseExisting && await _hasUsableAudio(audioPath)) {
      final reused = await durationProbe(audioPath);
      return _toSegment(
        entry: entry,
        audioPath: audioPath,
        durationSeconds: reused,
      );
    }

    final bytes = await _synthesizeWithRetry(
      entry: entry,
      voiceId: voiceId,
      rate: rate,
      pitch: pitch,
      isCancelled: isCancelled,
    );
    await File(audioPath).writeAsBytes(bytes, flush: true);

    final duration = await durationProbe(audioPath);
    return _toSegment(
      entry: entry,
      audioPath: audioPath,
      durationSeconds: duration,
    );
  }

  DubbingSegment _toSegment({
    required SrtEntry entry,
    required String audioPath,
    required double? durationSeconds,
  }) {
    return DubbingSegment(
      audioPath: audioPath,
      startSeconds: entry.startSeconds,
      durationSeconds: durationSeconds ?? entry.slotDuration,
      targetSlotDuration: entry.slotDuration,
      gender: entry.gender,
    );
  }

  /// True when [audioPath] exists and is not a zero-byte leftover.
  Future<bool> _hasUsableAudio(String audioPath) async {
    final file = File(audioPath);
    if (!file.existsSync()) return false;
    try {
      return await file.length() > 0;
    } catch (_) {
      return false;
    }
  }

  /// Synthesizes one cue, retrying with the [ttsRetryDelays] back-off.
  ///
  /// Throws [TtsEntryException] once every attempt is exhausted, so the stage
  /// fails with a message naming the cue that could not be rendered.
  Future<List<int>> _synthesizeWithRetry({
    required SrtEntry entry,
    required String voiceId,
    required String rate,
    required String pitch,
    bool Function()? isCancelled,
  }) async {
    Object? lastError;
    StackTrace? lastStack;

    for (var attempt = 0; attempt < maxTtsAttempts; attempt++) {
      if (isCancelled?.call() ?? false) {
        throw const FfmpegCancelledException();
      }
      try {
        final bytes = await _tts.synthesize(
          text: entry.text,
          voice: voiceId,
          rate: rate,
          pitch: pitch,
        );
        if (bytes.isEmpty) {
          throw StateError('Edge TTS returned no audio');
        }
        return bytes;
      } catch (e, st) {
        // A user-terminated job must not be reported as a synthesis failure.
        if (e is FfmpegCancelledException) rethrow;
        lastError = e;
        lastStack = st;

        final isLastAttempt = attempt == maxTtsAttempts - 1;
        if (isLastAttempt) break;
        await Future.delayed(ttsRetryDelays[attempt], () {
          return isCancelled?.call() ?? false;
        });
      }
    }

    Error.throwWithStackTrace(
      TtsEntryException(
        cueIndex: entry.index,
        text: entry.text,
        voiceId: voiceId,
        attempts: maxTtsAttempts,
        cause: lastError,
      ),
      lastStack ?? StackTrace.current,
    );
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
