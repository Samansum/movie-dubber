import 'dart:io';

import '../../models/dub_models.dart';
import '../../models/srt_models.dart';
import 'ffmpeg_dubbing_service.dart';
import 'gemini_translation_service.dart';
import 'tts_segment_service.dart';

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
  Future<DubbingResult> run({
    required String videoPath,
    required String workDir,
    required VoiceProfile voice,
    required String apiKey,
    required String modelDisplayName,
    double pitchHz = 0.0,
    double speedMultiplier = 1.0,
    double duckingPercent = -25.0,
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

    // ---- Stage 1: Extract audio ------------------------------------------
    onProgress?.call(const DubbingProgress(
      stageIndex: 0,
      fraction: 0.05,
      message: 'Extracting 48kHz audio track',
    ));
    await _ffmpeg.extractAudio(videoPath, audioPath);

    // ---- Stage 2: Transcribe and translate -------------------------------
    onProgress?.call(DubbingProgress(
      stageIndex: 1,
      fraction: 0.2,
      message: 'Transcribing and translating via $modelDisplayName',
    ));

    final entries = await _gemini.transcribeAndTranslateToEntries(
      audioPath: audioPath,
      apiKey: apiKey,
      modelDisplayName: modelDisplayName,
    );

    // Persist the cleaned SRT so it can be inspected and reused.
    final srtContent = _toSrtDocument(entries);
    await File(srtPath).writeAsString(srtContent, flush: true);

    onProgress?.call(DubbingProgress(
      stageIndex: 1,
      fraction: 0.45,
      message: 'Gemini returned ${entries.length} Khmer subtitle cues',
    ));

    // ---- Stage 3: Generate audio -----------------------------------------
    final segments = await _tts.synthesizeSegments(
      entries: entries,
      selectedVoice: voice,
      outputDir: segmentsDir,
      durationProbe: _ffmpeg.probeDuration,
      pitchHz: pitchHz,
      speedMultiplier: speedMultiplier,
      onProgress: (completed, total) {
        // Stage 3 owns the 0.5 – 0.85 slice of the overall bar.
        onProgress?.call(DubbingProgress(
          stageIndex: 2,
          fraction: 0.5 + 0.35 * (completed / total),
          message: 'Synthesized $completed/$total lines with Edge TTS',
        ));
      },
    );

    // ---- Stage 4: Build video --------------------------------------------
    onProgress?.call(const DubbingProgress(
      stageIndex: 3,
      fraction: 0.9,
      message: 'Remuxing dubbed audio onto the source timeline',
    ));

    await _ffmpeg.mixAndDubVideo(
      originalVideoPath: videoPath,
      segments: segments,
      outputVideoPath: outputPath,
      keepBackgroundAudio: true,
      duckingGainDb: duckingPercent,
    );

    onProgress?.call(const DubbingProgress(
      stageIndex: 3,
      fraction: 1.0,
      message: 'Dubbed video ready',
    ));

    return DubbingResult(
      outputVideoPath: outputPath,
      srtContent: srtContent,
      entries: entries,
    );
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
