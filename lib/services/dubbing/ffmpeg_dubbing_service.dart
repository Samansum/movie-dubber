import 'dart:async';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/session.dart';

import '../../models/srt_models.dart';

/// Raised when an FFmpeg command exits with a non-success return code.
class FfmpegException implements Exception {
  final String command;
  final String? logs;

  const FfmpegException(this.command, this.logs);

  @override
  String toString() {
    final tail = logs == null || logs!.isEmpty ? '' : '\n$logs';
    return 'FFmpeg command failed: $command$tail';
  }
}

/// Raised when a running FFmpeg session is cancelled (user terminated the job).
class FfmpegCancelledException implements Exception {
  const FfmpegCancelledException();

  @override
  String toString() => 'FFmpeg execution cancelled';
}

/// Wrapper around `ffmpeg_kit_flutter_new` for the dubbing pipeline.
///
/// Every command runs through [_run] so cancellation and return-code checking
/// are handled in one place.
class FfmpegDubbingService {
  /// Session of the command currently running, so it can be cancelled when the
  /// user terminates the job from the Queue screen.
  Session? _activeSession;
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  /// Cancels the in-flight command, if any. Safe to call when idle.
  Future<void> cancel() async {
    _cancelled = true;
    final session = _activeSession;
    _activeSession = null;
    if (session != null) {
      await session.cancel();
    }
  }

  /// Runs [command] and throws unless FFmpeg reports success.
  Future<void> _run(String command) async {
    if (_cancelled) throw const FfmpegCancelledException();

    final done = Completer<Session>();
    final session = await FFmpegKit.executeAsync(
      command,
          (finished) {
        if (!done.isCompleted) done.complete(finished);
      },
    );
    _activeSession = session;

    final finished = await done.future;
    _activeSession = null;

    final returnCode = await finished.getReturnCode();

    if (_cancelled || ReturnCode.isCancel(returnCode)) {
      throw const FfmpegCancelledException();
    }
    if (returnCode == null || !ReturnCode.isSuccess(returnCode)) {
      final logs = await finished.getAllLogsAsString();
      throw FfmpegException(command, logs);
    }
  }

  /// STEP 1 — Extracts the audio track from [videoPath] as a 48kHz mono WAV.
  ///
  /// Gemini ingests this file, and WAV/PCM keeps transcription accurate for
  /// quiet dialogue.
  Future<String> extractAudio(String videoPath, String outputPath) async {
    final command =
        '-y -i "$videoPath" -vn -ac 1 -ar 48000 -c:a pcm_s16le "$outputPath"';
    await _run(command);
    return outputPath;
  }

  /// Returns the duration of [filePath] in seconds, or `null` when FFprobe
  /// cannot read it.
  Future<double?> probeDuration(String filePath) async {
    final session = await FFprobeKit.getMediaInformation(filePath);
    final raw = session.getMediaInformation()?.getDuration();
    if (raw == null || raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  /// STEP 4 — Renders the dubbed timeline and muxes it with the source video.
  ///
  /// Each segment is time-stretched with `atempo` so the speech fits its
  /// subtitle slot, delayed to its cue start with `adelay`, then merged with
  /// `amix`. The original video stream is copied untouched (`-c:v copy`).
  Future<void> mixAndDubVideo({
    required String originalVideoPath,
    required List<DubbingSegment> segments,
    required String outputVideoPath,
    bool keepBackgroundAudio = false,
    double duckingGainDb = -15,
  }) async {
    if (segments.isEmpty) {
      throw ArgumentError('segments must not be empty');
    }

    final inputs = StringBuffer()..write('-i "$originalVideoPath" ');
    for (final segment in segments) {
      inputs.write('-i "${segment.audioPath}" ');
    }

    final filterComplex = StringBuffer();
    final mixLabels = <String>[];

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final inputIndex = i + 1;
      final label = 'a$inputIndex';

      final speed = segment.calculatedSpeed.clamp(1.0, 2.0);
      final delayMs = (segment.startSeconds * 1000).round().clamp(0, 1 << 31);

      filterComplex.write(
        '[$inputIndex:a]atempo=$speed,adelay=$delayMs|$delayMs[$label]; ',
      );
      mixLabels.add('[$label]');
    }

    filterComplex.write(
      '${mixLabels.join()}'
      'amix=inputs=${mixLabels.length}:duration=longest:dropout_transition=0'
      '[dubbed_audio]',
    );

    var audioMap = '[dubbed_audio]';

    if (keepBackgroundAudio) {
      // High-pass the original track so the ducked bed keeps ambience and music
      // but stops competing with the dubbed voice.
      filterComplex.write(
        '; [0:a]highpass=f=1000,equalizer=g=$duckingGainDb[bg_ducked]; '
        '[dubbed_audio][bg_ducked]amix=inputs=2:duration=first:'
        'weights=1 0.3[final_mix]',
      );
      audioMap = '[final_mix]';
    }

    final command = '$inputs-filter_complex "${filterComplex.toString()}" '
        '-map 0:v -map "$audioMap" -c:v copy -c:a aac -b:a 192k '
        '"$outputVideoPath"';

    await _run(command);
  }
}
