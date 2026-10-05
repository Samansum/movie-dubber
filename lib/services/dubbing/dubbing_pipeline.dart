import 'dart:io';

import '../../models/dub_models.dart';
import '../../models/srt_models.dart';
import 'ffmpeg_dubbing_service.dart';
import 'gemini_translation_service.dart';
import 'srt_parser.dart';
import 'tts_segment_service.dart';

/// Back-off applied between Gemini attempts on the same key.
const List<Duration> geminiRetryDelays = [
  Duration(seconds: 2),
  Duration(seconds: 4),
  Duration(seconds: 8),
];

/// Three *retries* after the initial attempt, for transient 5xx/503 blips.
///
/// Kept as a literal because Dart forbids reading `List.length` inside a `const`
/// expression; a unit test pins it to `geminiRetryDelays.length + 1`.
const int maxGeminiAttempts = 5;

/// Progress of a running [DubbingPipeline] job.
class DubbingProgress {
  /// Index of the stage currently running (0-based).
  final int stageIndex;

  /// Overall completion between `0.0` and `1.0`.
  final double fraction;

  /// Human readable status for the console log.
  final String message;

  const DubbingProgress({
    required this.stageIndex,
    required this.fraction,
    required this.message,
  });
}

/// Everything the pipeline produced for one job.
class DubbingResult {
  /// Absolute path of the rendered, dubbed video.
  final String outputVideoPath;

  /// The cleaned SRT document Gemini produced.
  final String srtContent;

  /// Parsed cues, in timeline order.
  final List<SrtEntry> entries;

  const DubbingResult({
    required this.outputVideoPath,
    required this.srtContent,
    required this.entries,
  });
}

/// Raised when a job cannot run — for example when no Gemini API key is saved.
class DubbingConfigurationException implements Exception {
  final String message;

  const DubbingConfigurationException(this.message);

  @override
  String toString() => message;
}

/// Raised when a pipeline stage fails.
///
/// Wraps whatever the underlying service threw so the orchestrator always knows
/// *which* stage stopped the job, and keeps the raw error text intact for the
/// copy-to-clipboard diagnostic shown to technical users.
class DubbingStageException implements Exception {
  /// Zero-based index of the stage that failed (0 = extract audio).
  final int stageIndex;

  /// The original exception, untouched.
  final Object cause;

  final StackTrace stackTrace;

  const DubbingStageException({
    required this.stageIndex,
    required this.cause,
    required this.stackTrace,
  });

  @override
  String toString() =>
      'Stage ${stageIndex + 1} (${DubbingStageCatalog.titleFor(stageIndex)}) '
      'failed: $cause';
}

/// Runs the four dubbing stages for a single video.
///
/// 1. Extract audio with FFmpeg.
/// 2. Transcribe + translate to Khmer SRT with Gemini.
/// 3. Synthesize each cue with Edge TTS.
/// 4. `atempo`/`amix` the speech and mux it back onto the source video.
///
/// The instance is single-use: [cancel] aborts the running FFmpeg command so
/// the Queue screen can terminate a job.
class DubbingPipeline {
  final FfmpegDubbingService _ffmpeg;
  final GeminiTranslationService _gemini;
  final TtsSegmentService _tts;

  DubbingPipeline({
    FfmpegDubbingService? ffmpeg,
    GeminiTranslationService gemini = const GeminiTranslationService(),
    TtsSegmentService? tts,
  })  : _ffmpeg = ffmpeg ?? FfmpegDubbingService(),
        _gemini = gemini,
        _tts = tts ?? TtsSegmentService();

  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  /// Cancels the running FFmpeg command. The next [run] call resets the flag.
  Future<void> cancel() async {
    _cancelled = true;
    await _ffmpeg.cancel();
  }

  /// Executes the full pipeline and returns the rendered video path.
  ///
  /// Set [startStage] to resume from a previously failed stage: every earlier
  /// stage is skipped and its artifacts are reused from [workDir]. This is what
  /// powers the "Retry stage" button on a failed job — re-running the TTS stage
  /// does not re-extract audio or re-bill Gemini.
  Future<DubbingResult> run({
    required String videoPath,
    required String workDir,
    required VoiceProfile voice,
    required String apiKey,
    required String modelDisplayName,
    double pitchHz = 0.0,
    double speedMultiplier = 1.0,
    double duckingPercent = 0.25,
    int startStage = 0,
    String? Function()? onRateLimited,
    void Function(DubbingProgress progress)? onProgress,
  }) async {
    _cancelled = false;

    final source = File(videoPath);
    if (!source.existsSync()) {
      throw DubbingConfigurationException(
        'The source video no longer exists:\n$videoPath',
      );
    }
    if (apiKey.isEmpty) {
      throw const DubbingConfigurationException(
        'No Gemini API key available.\nAdd one in the Settings tab first.',
      );
    }

    final work = Directory(workDir);
    if (!work.existsSync()) {
      await work.create(recursive: true);
    }

    final baseName = _baseName(videoPath);
    final audioPath = '${work.path}/$baseName.audio.wav';
    final srtPath = '${work.path}/$baseName.khmer.srt';
    final segmentsDir = '${work.path}/${baseName}_segments';
    final outputPath = '${work.path}/${baseName}_dubbed.mp4';

    // Resuming reuses artifacts from the previous attempt.
    final resuming = startStage > 0;

    // ---- Stage 1: Extract audio ------------------------------------------
    if (startStage <= 0) {
      onProgress?.call(const DubbingProgress(
        stageIndex: 0,
        fraction: 0.05,
        message: 'Extracting 48kHz audio track',
      ));

      await _runStage(
        stageIndex: 0,
        body: () => _ffmpeg.extractAudio(videoPath, audioPath),
      );
    }

    // ---- Stage 2: Transcribe and translate -------------------------------
    late final List<SrtEntry> entries;

    if (startStage <= 1) {
      onProgress?.call(DubbingProgress(
        stageIndex: 1,
        fraction: 0.2,
        message: 'Transcribing and translating via $modelDisplayName',
      ));

      entries = await _runStage(
        stageIndex: 1,
        body: () => _transcribeWithRetry(
          audioPath: audioPath,
          apiKey: apiKey,
          modelDisplayName: modelDisplayName,
          onRateLimited: onRateLimited,
          onProgress: onProgress,
        ),
      );

      // Persist the cleaned SRT so it can be inspected and reused. A later
      // "Retry stage" re-parses this file instead of paying for Gemini again.
      await File(srtPath).writeAsString(_toSrtDocument(entries), flush: true);

      onProgress?.call(DubbingProgress(
        stageIndex: 1,
        fraction: 0.45,
        message: 'Gemini returned ${entries.length} Khmer subtitle cues',
      ));
    } else {
      // Resuming past Gemini: rebuild the cue list from the saved SRT.
      entries = _loadEntriesFromSrt(srtPath);
    }

    // ---- Stage 3: Generate audio -----------------------------------------
    final segments = await _runStage(
      stageIndex: 2,
      body: () => _tts.synthesizeSegments(
        entries: entries,
        selectedVoice: voice,
        outputDir: segmentsDir,
        durationProbe: _ffmpeg.probeDuration,
        pitchHz: pitchHz,
        speedMultiplier: speedMultiplier,
        // On a resume, cues already rendered by the previous attempt are
        // measured and reused, so only the failed lines are synthesized again.
        reuseExisting: resuming,
        // Lets the worker pool bail out between lines when the user terminates
        // the job, instead of rendering every remaining cue.
        isCancelled: () => _cancelled,
        onProgress: (completed, total) {
          // Stage 3 owns the 0.5 – 0.85 slice of the overall bar.
          onProgress?.call(DubbingProgress(
            stageIndex: 2,
            fraction: 0.5 + 0.35 * (completed / total),
            message: 'Synthesized $completed/$total lines with Edge TTS',
          ));
        },
      ),
    );

    // ---- Stage 4: Build video --------------------------------------------
    if (startStage <= 3) {
      onProgress?.call(const DubbingProgress(
        stageIndex: 3,
        fraction: 0.9,
        message: 'Remuxing dubbed audio onto the source timeline',
      ));

      await _runStage(
        stageIndex: 3,
        body: () => _ffmpeg.mixAndDubVideo(
          originalVideoPath: videoPath,
          segments: segments,
          outputVideoPath: outputPath,
          keepBackgroundAudio: false,
          backgroundGain: duckingPercent,
          workDir: workDir,
        ),
      );

      onProgress?.call(const DubbingProgress(
        stageIndex: 3,
        fraction: 1.0,
        message: 'Dubbed video ready',
      ));
    }

    return DubbingResult(
      outputVideoPath: outputPath,
      srtContent: _srtContentOf(srtPath, entries),
      entries: entries,
    );
  }

  /// Runs stage 2 with a bounded retry budget.
  ///
  /// Transient failures (5xx/503, network blips) are retried on the *same* key
  /// with a growing back-off. A rate limit or a rejected key asks
  /// [onRateLimited] for a different key and immediately retries with it — if
  /// no alternative key exists the error is rethrown so the job fails loudly
  /// instead of looping.
  Future<List<SrtEntry>> _transcribeWithRetry({
    required String audioPath,
    required String apiKey,
    required String modelDisplayName,
    String? Function()? onRateLimited,
    void Function(DubbingProgress progress)? onProgress,
  }) async {
    var currentKey = apiKey;
    // Counts only same-key retries. A key rotation starts a fresh budget,
    // because the next key has not been tried yet.
    var transientAttempts = 0;

    while (true) {
      if (_cancelled) throw const FfmpegCancelledException();

      try {
        return await _gemini.transcribeAndTranslateToEntries(
          audioPath: audioPath,
          apiKey: currentKey,
          modelDisplayName: modelDisplayName,
        );
      } on FfmpegCancelledException {
        rethrow;
      } catch (e) {
        final geminiError = e is GeminiTranslationException ? e : null;

        // Rate limited / key rejected: swap keys and retry right away.
        if (geminiError != null &&
            (geminiError.isRateLimited || geminiError.isInvalidKey)) {
          final nextKey = onRateLimited?.call();
          onProgress?.call(DubbingProgress(
            stageIndex: 1,
            fraction: 0.2,
            message: geminiError.isInvalidKey
                ? 'Gemini key rejected — switching to the next key'
                : 'Gemini rate limit reached — switching to the next key',
          ));

          if (nextKey == null || nextKey == currentKey) {
            // Pool exhausted: surface the real reason rather than retrying a
            // key we know is throttled.
            Error.throwWithStackTrace(
              GeminiTranslationException(
                nextKey == null
                    ? '${geminiError.message} '
                        '(no further API key available in the pool)'
                    : geminiError.message,
                details: geminiError.details,
                kind: geminiError.kind,
              ),
              StackTrace.current,
            );
          }

          currentKey = nextKey;
          // A brand new key deserves the full retry budget again.
          transientAttempts = 0;
          continue;
        }

        // Fatal error (bad region, malformed audio, empty response) or the
        // budget is spent: retrying cannot help.
        if (geminiError == null ||
            !geminiError.isRetryable ||
            transientAttempts >= maxGeminiAttempts - 1) {
          rethrow;
        }

        // Transient server error: wait, then retry the same key.
        final delay = geminiRetryDelays[transientAttempts];
        onProgress?.call(DubbingProgress(
          stageIndex: 1,
          fraction: 0.2,
          message: 'Gemini unavailable — retrying in ${delay.inSeconds}s '
              '(retry ${transientAttempts + 1}/${maxGeminiAttempts - 1})',
        ));

        await Future.delayed(delay, () => _cancelled);
        if (_cancelled) throw const FfmpegCancelledException();
        transientAttempts++;
      }
    }
  }

  /// Re-parses the persisted SRT so a stage retry can skip Gemini entirely.
  List<SrtEntry> _loadEntriesFromSrt(String srtPath) {
    final file = File(srtPath);
    if (!file.existsSync()) {
      throw DubbingConfigurationException(
        'Cannot resume: the saved subtitle file is missing.\n$srtPath',
      );
    }

    final entries = SrtParser.parse(file.readAsStringSync());
    if (entries.isEmpty) {
      throw DubbingConfigurationException(
        'Cannot resume: the saved subtitle file contained no usable cues.\n'
        '$srtPath',
      );
    }
    return entries;
  }

  /// Reads the SRT back from disk, falling back to a freshly rendered document.
  String _srtContentOf(String srtPath, List<SrtEntry> entries) {
    final file = File(srtPath);
    if (file.existsSync()) {
      try {
        return file.readAsStringSync();
      } catch (_) {
        // Fall through to the in-memory rebuild.
      }
    }
    return _toSrtDocument(entries);
  }

  /// Runs one stage and tags any failure with its stage index.
  ///
  /// Cancellation is rethrown untouched so [FfmpegCancelledException] still
  /// reaches the orchestrator's cancellation handler instead of being reported
  /// as a pipeline error.
  Future<T> _runStage<T>({
    required int stageIndex,
    required Future<T> Function() body,
  }) async {
    try {
      return await body();
    } on FfmpegCancelledException {
      rethrow;
    } on DubbingStageException {
      rethrow;
    } catch (error, stackTrace) {
      throw DubbingStageException(
        stageIndex: stageIndex,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Rebuilds a canonical SRT document from parsed cues, dropping the `[M]`/`[F]`
  /// tags that only exist to drive voice selection.
  String _toSrtDocument(List<SrtEntry> entries) {
    final buffer = StringBuffer();
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      buffer
        ..writeln('${i + 1}')
        ..writeln(_formatTimestamp(entry.startSeconds))
        ..write(' --> ')
        ..writeln(_formatTimestamp(entry.endSeconds))
        ..writeln(entry.text)
        ..writeln();
    }
    return buffer.toString().trimRight();
  }

  String _formatTimestamp(double seconds) {
    final safe = seconds < 0 ? 0.0 : seconds;
    final totalMs = (safe * 1000).round();
    final ms = totalMs % 1000;
    final totalSeconds = totalMs ~/ 1000;
    final ss = totalSeconds % 60;
    final mm = (totalSeconds ~/ 60) % 60;
    final hh = totalSeconds ~/ 3600;
    return '${hh.toString().padLeft(2, '0')}:'
        '${mm.toString().padLeft(2, '0')}:'
        '${ss.toString().padLeft(2, '0')},'
        '${ms.toString().padLeft(3, '0')}';
  }

  String _baseName(String path) {
    final fileName = path.split('/').last;
    final dotIndex = fileName.lastIndexOf('.');
    final base = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
    // Keep the name filesystem-safe on every platform.
    return base.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }
}
