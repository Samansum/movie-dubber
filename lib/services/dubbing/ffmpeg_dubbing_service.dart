import 'dart:async';
import 'dart:io';

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
    required String workDir,
    bool keepBackgroundAudio = false,
    double backgroundGain = 0.25, // linear volume of the background bed
  }) async {
    if (segments.isEmpty) throw ArgumentError('segments must not be empty');

    final args = <String>['-y', '-i', originalVideoPath];
    for (final s in segments) {
      args..add('-i')..add(s.audioPath);
    }

    final g = StringBuffer();
    final labels = <String>[];
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      final idx = i + 1;
      var speed = s.calculatedSpeed;
      if (!speed.isFinite) speed = 1.0;
      speed = speed.clamp(1.0, 2.0).toDouble();
      final delayMs = (s.startSeconds * 1000).round().clamp(0, 1 << 31);

      g.write('[$idx:a]aformat=sample_rates=48000:channel_layouts=mono,'
          'atempo=${speed.toStringAsFixed(4)},'
          'adelay=$delayMs:all=1[a$idx];');
      labels.add('[a$idx]');
    }

    g.write('${labels.join()}amix=inputs=${labels.length}:'
        'duration=longest:dropout_transition=0:normalize=0[dub];');

    if (keepBackgroundAudio) {
      g.write('[dub]asplit=2[dub_out][dub_key];'
          '[0:a]aformat=sample_rates=48000:channel_layouts=mono,'
          'volume=$backgroundGain[bg];'
          '[bg][dub_key]sidechaincompress=threshold=0.02:ratio=10:'
          'attack=10:release=300[bg_ducked];'
          '[dub_out][bg_ducked]amix=inputs=2:duration=longest:'
          'dropout_transition=0:normalize=0,apad[final]');
    } else {
      g.write('[dub]apad[final]');
    }

    final scriptPath = '$workDir/mix_graph.txt';
    await File(scriptPath).writeAsString(g.toString());

    args.addAll([
      '-filter_complex', g.toString(),
      '-map', '0:v:0',
      '-map', '[final]',
      '-c:v', 'copy',
      '-c:a', 'aac', '-b:a', '192k',
      '-shortest',
      '-movflags', '+faststart',
      outputVideoPath,
    ]);

    await _runArgs(args);
  }

  Future<void> _runArgs(List<String> args) async {
    if (_cancelled) throw const FfmpegCancelledException();
    final done = Completer<Session>();
    final session = await FFmpegKit.executeWithArgumentsAsync(
      args,
          (s) { if (!done.isCompleted) done.complete(s); },
    );
    _activeSession = session;
    final finished = await done.future;
    _activeSession = null;

    final rc = await finished.getReturnCode();
    if (_cancelled || ReturnCode.isCancel(rc)) {
      throw const FfmpegCancelledException();
    }
    if (rc == null || !ReturnCode.isSuccess(rc)) {
      final logs = await finished.getAllLogsAsString() ?? '';
      final lines = logs.split('\n');
      final tail = lines.skip(lines.length > 40 ? lines.length - 40 : 0).join('\n');
      throw FfmpegException(args.join(' '), tail); // tail = the actual error
    }
  }
}
