import 'package:flutter/material.dart';

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
    khmerSampleText: 'ស្វ័យប្រវត្តិកំណត់សំឡេងតួអង្គ',
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
  });

  DubbingTask copyWith({
    double? progress,
    bool? isProcessing,
    bool? isQueued,
    bool? isCompleted,
    List<PipelineStage>? stages,
    String? liveStatusLog,
    String? outputPath,
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
