import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/session.dart';
import 'package:gal/gal.dart';

class SilenceGap {
  final double startTime;
  final double endTime;
  const SilenceGap({required this.startTime, required this.endTime});
  double get duration => endTime - startTime;
  double get midpoint => (startTime + endTime) / 2;
}

enum ChunkState { idle, extractingAudio, detectingSilence, findingCutPoint, cuttingVideo, completed, failed }

class ChunkResult {
  final List<String> chunkPaths;
  final double totalDuration;
  const ChunkResult({required this.chunkPaths, required this.totalDuration});
}

class ChunkingException implements Exception {
  final String message;
  final String? detail;
  const ChunkingException(this.message, {this.detail});
  @override
  String toString() => 'Chunking failed: $message${detail != null ? '\n$detail' : ''}';
}

class VideoChunkingService {
  ChunkState _state = ChunkState.idle;
  ChunkState get state => _state;
  double _progress = 0.0;
  double get progress => _progress;
  String _statusLog = '';
  String get statusLog => _statusLog;
  bool _cancelled = false;
  Session? _activeSession;
  bool get isCancelled => _cancelled;

  Future<void> cancel() async {
    _cancelled = true; _activeSession?.cancel(); _activeSession = null;
    _state = ChunkState.idle; _statusLog = 'Cancelled.';
  }

  Future<ChunkResult> chunkVideo({
    required String videoPath,
    required String outputDir,
    required String videoName,
    VoidCallback? onCancelled,
  }) async {
    _resetState();
    try {
      // Request gallery access once at start
      try {
        if (!await Gal.hasAccess(toAlbum: true)) {
          await Gal.requestAccess(toAlbum: true);
        }
      } catch (_) {
        // Ignore — gallery is optional for chunking to succeed
      }

      final baseDir = '$outputDir/chunk_${DateTime.now().millisecondsSinceEpoch}';
      await Directory(baseDir).create(recursive: true);
      final outDir = '$baseDir/chunks';
      await Directory(outDir).create(recursive: true);
      _setState(ChunkState.extractingAudio, 'Extracting audio...'); _setProgress(0.1);
      await _runFfmpeg('-y -i "$videoPath" -vn -ac 1 -ar 16000 -c:a pcm_s16le "$baseDir/a.wav"');
      if (_cancelled) { onCancelled?.call(); return const ChunkResult(chunkPaths: [], totalDuration: 0); }
      _setState(ChunkState.detectingSilence, 'Detecting silence gaps...'); _setProgress(0.3);
      final gaps = await _detectSilence('$baseDir/a.wav');
      final dur = await _probeDur(videoPath) ?? 420.0;
      _setState(ChunkState.findingCutPoint, 'Finding cut points...'); _setProgress(0.6);
      final cuts = await _findCuts(gaps: gaps, totalDur: dur);
      if (_cancelled) { onCancelled?.call(); return const ChunkResult(chunkPaths: [], totalDuration: 0); }
      _setState(ChunkState.cuttingVideo, 'Splitting video...'); _setProgress(0.8);
      final paths = await _splitVideo(source: videoPath, cuts: cuts, dir: outDir);
      if (_cancelled) { onCancelled?.call(); return const ChunkResult(chunkPaths: [], totalDuration: 0); }

      // Copy chunks to final output directory with Part_NN naming & export directly to Gallery
      final finalDir = outputDir;
      await Directory(finalDir).create(recursive: true);
      final finalPaths = <String>[];
      for (var i = 0; i < paths.length; i++) {
        final partNum = (i + 1).toString().padLeft(2, '0');
        final finalPath = '$finalDir/Part_$partNum.mp4';
        await File(paths[i]).copy(finalPath);
        // Export directly to Gallery album named after the video
        try {
          await Gal.putVideo(finalPath, album: videoName);
        } catch (e) {
          log('Gallery export failed for $finalPath: $e');
        }
        // Clean up temp chunk file
        await File(paths[i]).delete();
        finalPaths.add(finalPath);
      }

      // Clean up entire temp directory (audio file + intermediate chunk files)
      try {
        final baseDirObj = Directory(baseDir);
        if (baseDirObj.existsSync()) {
          await baseDirObj.delete(recursive: true);
        }
      } catch (e) {
        log('Failed to clean temp dir $baseDir: $e');
      }

      _setState(ChunkState.completed, 'Done!'); _setProgress(1.0);
      return ChunkResult(chunkPaths: finalPaths, totalDuration: dur);
    } catch (e) {
      if (!_cancelled) _setState(ChunkState.failed, e.toString());
      rethrow;
    }
  }

  void _resetState() { _state = ChunkState.idle; _progress = 0; _statusLog = ''; _cancelled = false; }
  void _setState(ChunkState s, String l) { _state = s; _statusLog = l; }
  void _setProgress(double v) { _progress = v.clamp(0.0, 1.0); }

  Future<void> _runFfmpeg(String cmd) async {
    final c = Completer<Session>();
    final sess = await FFmpegKit.executeAsync(cmd, (f) { if (!c.isCompleted) c.complete(f); });
    _activeSession = sess; final f = await c.future; _activeSession = null;
    final rc = await f.getReturnCode();
    if (_cancelled || ReturnCode.isCancel(rc)) { _cancelled = true; return; }
    if (rc == null || !ReturnCode.isSuccess(rc)) throw ChunkingException('FFmpeg err', detail: await f.getAllLogsAsString());
  }

  Future<List<SilenceGap>> _detectSilence(String wav) async {
    final done = Completer<Session>();
    await FFmpegKit.executeAsync('-i "$wav" -af "silencedetect=noise=-0.01dB:d=0.5" -f null -', (f) { if (!done.isCompleted) done.complete(f); });
    final f = await done.future; final logs = await f.getAllLogsAsString() ?? '';
    final gaps = <SilenceGap>[]; double? start;
    for (final line in logs.split('\n')) {
      if (line.contains('silence_start:')) { final m = RegExp(r'silence_start:\s*([\d.]+)').firstMatch(line); if (m != null) start = double.parse(m.group(1)!); }
      else if (line.contains('silence_end:')) { final m = RegExp(r'silence_end:\s*([\d.]+)').firstMatch(line); if (m != null) { final e = double.parse(m.group(1)!); if (start != null) { gaps.add(SilenceGap(startTime: start!, endTime: e)); start = null; } } }
    }
    return gaps;
  }

  Future<List<double>> _findCuts({required List<SilenceGap> gaps, required double totalDur}) async {
    final cuts = <double>[]; var target = 420.0;
    while (target < totalDur - 60) {
      double? best; double bd = double.infinity;
      for (final g in gaps) { final mid = g.midpoint; if (mid >= target - 180 && mid <= target + 180) { final d = (mid - target).abs(); if (d < bd) { bd = d; best = mid; } } }
      cuts.add(best ?? (() { for (final g in gaps) if ((g.startTime - target).abs() < 120) return (g.startTime - target).abs() < (g.endTime - target).abs() ? g.startTime : g.endTime; return target; })());
      target += 420.0;
    }
    return cuts;
  }

  Future<List<String>> _splitVideo({required String source, required List<double> cuts, required String dir}) async {
    final paths = <String>[]; var off = 0.0;
    for (var i = 0; i < cuts.length; i++) {
      if (_cancelled) break;
      _updateProg(i, cuts.length, off, cuts[i]);
      final p = '$dir/chunk_${i + 1}.mp4';
      await _runFfmpeg('-y -ss $off -i "$source" -t ${cuts[i] - off} -c copy "$p"');
      paths.add(p); off = cuts[i];
    }
    if (!_cancelled) { final lp = '$dir/chunk_${paths.length + 1}.mp4'; await _runFfmpeg('-y -ss $off -i "$source" -c copy "$lp"'); paths.add(lp); }
    return paths;
  }

  void _updateProg(int c, int t, double s, double e) { _progress = 0.8 + 0.15 * c / t; _statusLog = 'Cutting ${c + 1}/$t (${s.toStringAsFixed(0)}s-${formatTime(e)})'; }
  Future<double?> _probeDur(String path) async {
    final s = await FFprobeKit.getMediaInformation(path); final r = s.getMediaInformation()?.getDuration();
    return r == null || r.isEmpty ? null : double.tryParse(r);
  }
  static String formatTime(double s) {
    return '${(s ~/ 3600).toString().padLeft(2, "0")}:${((s % 3600) ~/ 60).toString().padLeft(2, "0")}:${(s % 60).toStringAsFixed(0).padLeft(2, "0")}';
  }
}