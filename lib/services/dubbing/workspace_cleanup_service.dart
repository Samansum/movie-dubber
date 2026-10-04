import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Outcome of a workspace sweep.
class WorkspaceCleanupReport {
  /// Absolute paths that were deleted.
  final List<String> removedPaths;

  /// Total bytes reclaimed.
  final int freedBytes;

  /// Non-fatal problems (a file locked by the decoder, permission denied, …).
  final List<String> warnings;

  const WorkspaceCleanupReport({
    this.removedPaths = const [],
    this.freedBytes = 0,
    this.warnings = const [],
  });

  bool get isEmpty => removedPaths.isEmpty;

  @override
  String toString() =>
      'WorkspaceCleanupReport(removed ${removedPaths.length}, '
      'freed $freedBytes bytes, ${warnings.length} warnings)';
}

/// Removes artifacts left behind by a previous app session.
///
/// The dubbing queue is held in memory only, so after a restart nothing can
/// still reference a render from last time. Without this sweep a long-lived
/// device accumulates every extracted WAV, SRT, per-cue MP3 and rendered MP4
/// the app ever produced, which can easily fill the user's storage.
///
/// Only the app-owned job folders are touched; nothing outside them is ever
/// deleted, and the folders themselves are recreated on demand.
class WorkspaceCleanupService {
  const WorkspaceCleanupService._();

  /// Name of the folder holding per-job intermediates and renders.
  static const String workDirName = 'dubbing_jobs';

  /// Prefix of the cached voice-preview files written by `EdgeTtsService`.
  static const String ttsCachePrefix = 'tts_cache_';

  /// Deletes stale job artifacts and cached voice samples.
  ///
  /// [workDirOverride] short-circuits the `path_provider` lookup so tests can
  /// point the sweep at a temp folder.
  static Future<WorkspaceCleanupReport> cleanPreviousRun({
    String? workDirOverride,
  }) async {
    final removed = <String>[];
    final warnings = <String>[];
    var freed = 0;

    try {
      Directory? docsDir;
      if (workDirOverride != null) {
        docsDir = Directory(workDirOverride);
      } else {
        docsDir = await getApplicationDocumentsDirectory();
      }

      // 1. Everything inside the per-job work dir: extracted WAV, SRT, the
      //    per-cue MP3 folders and the rendered MP4s.
      final workDir = Directory('${docsDir.path}/$workDirName');
      final jobResult = await _deleteContents(workDir);
      removed.addAll(jobResult.removed);
      warnings.addAll(jobResult.warnings);
      freed += jobResult.freed;

      // 2. Cached Edge TTS voice previews written next to the docs dir.
      await for (final entity in docsDir.list()) {
        final name = entity.uri.pathSegments
            .where((segment) => segment.isNotEmpty)
            .last;
        if (!name.startsWith(ttsCachePrefix)) continue;

        final result = await _delete(entity);
        if (result.error != null) {
          warnings.add('$name: ${result.error}');
        } else {
          removed.add(entity.path);
          freed += result.freed;
        }
      }
    } catch (e) {
      // A missing plugin channel or an unreadable directory must never stop
      // the app from starting.
      warnings.add('Cleanup skipped: $e');
    }

    return WorkspaceCleanupReport(
      removedPaths: removed,
      freedBytes: freed,
      warnings: warnings,
    );
  }

  /// Empties [dir] without deleting [dir] itself, so the next job can write
  /// into it immediately.
  static Future<_DeleteResult> _deleteContents(Directory dir) async {
    if (!dir.existsSync()) return const _DeleteResult();

    // Re-create the folder eagerly: `create` is a no-op when it still exists,
    // and guarantees the pipeline never has to handle a missing parent.
    await dir.create(recursive: true);

    final removed = <String>[];
    final warnings = <String>[];
    var freed = 0;

    await for (final entity in dir.list()) {
      final result = await _delete(entity);
      if (result.error != null) {
        warnings.add('${entity.path}: ${result.error}');
      } else {
        removed.add(entity.path);
        freed += result.freed;
      }
    }

    return _DeleteResult(removed: removed, freed: freed, warnings: warnings);
  }

  /// Deletes one file or directory tree, reporting the failure rather than
  /// throwing so one stubborn file cannot abort the whole sweep.
  static Future<_DeleteResult> _delete(FileSystemEntity entity) async {
    try {
      final size = await _sizeOf(entity);
      if (entity is Directory) {
        await entity.delete(recursive: true);
      } else {
        await entity.delete();
      }
      return _DeleteResult(freed: size);
    } catch (e) {
      return _DeleteResult(error: '$e');
    }
  }

  static Future<int> _sizeOf(FileSystemEntity entity) async {
    try {
      if (entity is File) return await entity.length();
      if (entity is Directory) {
        var total = 0;
        await for (final child in entity.list(recursive: true)) {
          if (child is File) total += await child.length();
        }
        return total;
      }
    } catch (_) {
      // Size is only used for reporting; ignore failures.
    }
    return 0;
  }
}

class _DeleteResult {
  final List<String> removed;
  final int freed;
  final List<String> warnings;
  final String? error;

  const _DeleteResult({
    this.removed = const [],
    this.freed = 0,
    this.warnings = const [],
    this.error,
  });
}
