import 'package:flutter/material.dart';

import '../l10n/app_l10n.dart';

enum VoiceType {
  autoCast,
  male,
  female,
}

class VoiceProfile {
  final String id;
  final String name;
  final VoiceType type;
  final String imagePath;
  final String roleTag;
  final String badgeText;
  final String khmerSampleText;
  final String durationText;
  final String description;

  const VoiceProfile({
    required this.id,
    required this.name,
    required this.type,
    required this.imagePath,
    required this.roleTag,
    required this.badgeText,
    required this.khmerSampleText,
    required this.durationText,
    required this.description,
  });

  static const VoiceProfile autoCast = VoiceProfile(
    id: 'voice_auto',
    name: 'Smart Multi-Speaker',
    type: VoiceType.autoCast,
    imagePath: '',
    roleTag: 'Auto-Cast Engine',
    badgeText: 'Auto-Cast',
    khmerSampleText: 'កំណត់សំឡេងតួអង្គស្វ័យប្រវត្តិ',
    durationText: 'Auto',
    description:
        'Smart auto-detects male and female character voices automatically.',
  );

  static const VoiceProfile pisethNeural = VoiceProfile(
    id: 'km-KH-PisethNeural',
    name: 'Piseth Neural',
    type: VoiceType.male,
    imagePath: 'assets/images/piseth.jpg',
    roleTag: 'Cinematic Deep Narrator',
    badgeText: 'Ultra Low Latency',
    khmerSampleText: 'សូមស្វាគមន៍មកកាន់ អេអាយ សម្រាយរឿង។',
    durationText: '0:03',
    description:
        'Resonant, authoritative male narration for action & cinema trailers.',
  );

  static const VoiceProfile sreymomNeural = VoiceProfile(
    id: 'km-KH-SreymomNeural',
    name: 'Sreymon Neural',
    type: VoiceType.female,
    imagePath: 'assets/images/sreymom.jpg',
    roleTag: 'Warm & Natural Storyteller',
    badgeText: 'Optimal for Dialogues',
    khmerSampleText: 'សូមស្វាគមន៍មកកាន់ អេអាយ សម្រាយរឿង។',
    durationText: '0:03',
    description:
        'Expressive and clear female voice ideal for documentaries & dialogues.',
  );

  static const List<VoiceProfile> allProfiles = [
    autoCast,
    pisethNeural,
    sreymomNeural,
  ];
}

/// Real, on-device video metadata built after the user picks a source clip.
/// All values are derived from the selected file once it has been inspected
/// with the video player (no placeholder/sample data).
class VideoAsset {
  final String filePath;
  final String fileName;
  final Duration duration;
  final int width;
  final int height;
  final int sizeBytes;

  const VideoAsset({
    required this.filePath,
    required this.fileName,
    required this.duration,
    required this.width,
    required this.height,
    required this.sizeBytes,
  });

  double get sizeMb => sizeBytes / (1024 * 1024);

  /// Uppercase container extension (e.g. "MP4"), or "VIDEO" when unknown.
  String get fileExtension {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == fileName.length - 1) {
      return 'VIDEO';
    }
    return fileName.substring(dotIndex + 1).toUpperCase();
  }

  /// Short-side resolution label, e.g. 1920x1080 -> "1080p", 3840x2160 -> "4K".
  String get resolutionLabel {
    final shortSide = width < height ? width : height;
    if (shortSide <= 0) return 'Video';
    if (shortSide >= 2160) return '4K';
    if (shortSide >= 1440) return '2K';
    return '${shortSide}p';
  }

  String get resolutionText =>
      (width <= 0 || height <= 0) ? 'Unknown' : '$width × $height';

  /// `mm:ss` formatted playback length.
  String get durationText {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get fileSpecs =>
      '${sizeMb.toStringAsFixed(1)} MB • $fileExtension • $resolutionText';
}

/// Canonical definition of the four dubbing stages.
///
/// Titles/icons live here so the orchestrator and the queue UI can never drift
/// apart on what "stage 2" is called.
///
/// Titles are user-visible, so they are resolved against a [Locale] rather
/// than being a single fixed English list. English stays the default because
/// it is the template catalog and therefore always complete.
class DubbingStageCatalog {
  DubbingStageCatalog._();

  static const int stageCount = 4;

  static const List<String> titles = [
    '1. Extract audio',
    '2. Transcribe and translate',
    '3. Generate voice',
    '4. Build video',
  ];

  /// The four stage titles rendered in [locale].
  static List<String> titlesFor(Locale locale) {
    final l10n = stringsFor(locale);
    return [
      l10n.stageTitle1,
      l10n.stageTitle2,
      l10n.stageTitle3,
      l10n.stageTitle4,
    ];
  }

  /// Raw, unfiltered diagnostic captured when a stage throws.
  ///
  /// [message] is the short line shown to the user; [details] keeps the
  /// original exception text, FFmpeg command/log and Dart stack trace so a
  /// technical user can copy it verbatim into a bug report.
  static DubbingError errorForStage(
    int stageIndex, {
    required Object cause,
    StackTrace? stackTrace,
    String? message,
    String? details,
  }) {
    return DubbingError(
      stageIndex: stageIndex,
      stageTitle: titleFor(stageIndex),
      message: message ?? cause.toString(),
      details: details ?? cause.toString(),
      errorType: cause.runtimeType.toString(),
      stackTrace: stackTrace?.toString() ?? '',
      occurredAt: DateTime.now(),
    );
  }

  static String titleFor(int stageIndex, {Locale locale = const Locale('en')}) {
    if (stageIndex < 0 || stageIndex >= stageCount) {
      return stringsFor(locale).stageFallback(stageIndex + 1);
    }
    return titlesFor(locale)[stageIndex];
  }
}

/// A recorded pipeline failure, preserved verbatim for support/debugging.
class DubbingError {
  /// Zero-based index of the stage that failed.
  final int stageIndex;
  final String stageTitle;

  /// Short, human-readable summary rendered on the failure card.
  final String message;

  /// Full raw text: exception body, FFmpeg command + logs, stack trace.
  final String details;

  /// Runtime type of the thrown object, e.g. `FfmpegException`.
  final String errorType;
  final String stackTrace;
  final DateTime occurredAt;

  const DubbingError({
    required this.stageIndex,
    required this.stageTitle,
    required this.message,
    required this.details,
    required this.errorType,
    required this.stackTrace,
    required this.occurredAt,
  });

  /// Monospaced technical report — this is what the copy button yields.
  String reportFor(String videoTitle) {
    final buffer = StringBuffer()
      ..writeln('CineDub AI — Dubbing pipeline error report')
      ..writeln('Job:      $videoTitle')
      ..writeln('Stage:    $stageTitle (index $stageIndex)')
      ..writeln('Error:    $errorType')
      ..writeln('Time:     ${occurredAt.toIso8601String()}')
      ..writeln('')
      ..writeln('--- Summary ---')
      ..writeln(message)
      ..writeln('')
      ..writeln('--- Raw details ---')
      ..writeln(details);
    if (stackTrace.isNotEmpty) {
      buffer
        ..writeln('')
        ..writeln('--- Stack trace ---')
        ..writeln(stackTrace);
    }
    return buffer.toString().trimRight();
  }
}

enum StageStatus {
  completed,
  inProgress,
  nextUp,
  pending,
  failed,
}

class PipelineStage {
  final int stageNumber;
  final String title;
  final String description;
  final StageStatus status;
  final String badgeText;
  final IconData icon;

  const PipelineStage({
    required this.stageNumber,
    required this.title,
    required this.description,
    required this.status,
    required this.badgeText,
    required this.icon,
  });

  PipelineStage copyWith({
    StageStatus? status,
    String? description,
    String? badgeText,
  }) {
    return PipelineStage(
      stageNumber: stageNumber,
      title: title,
      description: description ?? this.description,
      status: status ?? this.status,
      badgeText: badgeText ?? this.badgeText,
      icon: icon,
    );
  }
}

class DubbingTask {
  final String id;
  final String videoTitle;

  /// Absolute path of the source clip on disk. `null` for placeholder tasks.
  final String? videoPath;

  /// Absolute path of the rendered, dubbed video once the job completes.
  final String? outputPath;

  final String duration;
  final String fileSpecs;
  final VoiceProfile voiceProfile;
  final double progress;
  final bool isProcessing;
  final bool isQueued;
  final bool isCompleted;
  final List<PipelineStage> stages;
  final String liveStatusLog;

  /// Raw diagnostic captured when the pipeline stopped on an error.
  /// `null` while the job is healthy (queued, running or completed).
  final DubbingError? error;

  /// Zero-based stage this job should (re)start from.
  ///
  /// `null`/0 for a fresh job. Set when the user taps "Retry stage" on a failed
  /// job so the pipeline resumes at the broken step instead of repeating the
  /// stages that already succeeded.
  final int? resumeFromStage;

  const DubbingTask({
    required this.id,
    required this.videoTitle,
    this.videoPath,
    this.outputPath,
    required this.duration,
    required this.fileSpecs,
    required this.voiceProfile,
    required this.progress,
    required this.isProcessing,
    required this.isQueued,
    required this.isCompleted,
    required this.stages,
    required this.liveStatusLog,
    this.error,
    this.resumeFromStage,
  });

  /// Whether this job stopped on an error. Used by the queue UI to keep failed
  /// renders out of the "Recently completed" list.
  bool get hasFailed => error != null;

  /// Zero-based index of the stage that failed, or `null` when there was no
  /// error.
  int? get failedStageIndex => error?.stageIndex;

  /// The full technical report a technical user copies to the clipboard.
  String get errorReport => error?.reportFor(videoTitle) ?? '';

  DubbingTask copyWith({
    double? progress,
    bool? isProcessing,
    bool? isQueued,
    bool? isCompleted,
    List<PipelineStage>? stages,
    String? liveStatusLog,
    String? outputPath,
    DubbingError? error,
    int? resumeFromStage,
  }) {
    return DubbingTask(
      id: id,
      videoTitle: videoTitle,
      videoPath: videoPath,
      outputPath: outputPath ?? this.outputPath,
      duration: duration,
      fileSpecs: fileSpecs,
      voiceProfile: voiceProfile,
      progress: progress ?? this.progress,
      isProcessing: isProcessing ?? this.isProcessing,
      isQueued: isQueued ?? this.isQueued,
      isCompleted: isCompleted ?? this.isCompleted,
      stages: stages ?? this.stages,
      liveStatusLog: liveStatusLog ?? this.liveStatusLog,
      error: error ?? this.error,
      resumeFromStage: resumeFromStage ?? this.resumeFromStage,
    );
  }
}

class ApiKeyItem {
  final String id;
  final String alias;

  /// Masked token shown in the UI (e.g. `AIzaSyD••••••`).
  final String maskedToken;

  /// The real, unmasked token. Required to call the Gemini API — the masked
  /// form is display-only and cannot be used for requests.
  final String token;

  final String model;
  final String status; // 'Active', 'Standby', 'Cooldown'
  final int rpmUsage;
  final int rpmMax;
  final int latencyMs;

  const ApiKeyItem({
    required this.id,
    required this.alias,
    required this.maskedToken,
    required this.token,
    required this.model,
    required this.status,
    required this.rpmUsage,
    required this.rpmMax,
    required this.latencyMs,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alias': alias,
      'maskedToken': maskedToken,
      'token': token,
      'model': model,
      'status': status,
      'rpmUsage': rpmUsage,
      'rpmMax': rpmMax,
      'latencyMs': latencyMs,
    };
  }

  factory ApiKeyItem.fromJson(Map<String, dynamic> json) {
    return ApiKeyItem(
      id: json['id'] as String? ?? '',
      alias: json['alias'] as String? ?? '',
      maskedToken: json['maskedToken'] as String? ?? '',
      // Older records (saved before raw tokens were persisted) fall back to an
      // empty token; `AppState.activeApiKey` filters those out.
      token: json['token'] as String? ?? '',
      model: json['model'] as String? ?? '',
      status: json['status'] as String? ?? 'Active',
      rpmUsage: json['rpmUsage'] as int? ?? 0,
      rpmMax: json['rpmMax'] as int? ?? 60,
      latencyMs: json['latencyMs'] as int? ?? 120,
    );
  }
}
