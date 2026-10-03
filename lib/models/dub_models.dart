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
  final String neuralCode;
  final String avatarUrl;
  final String roleTag;
  final String badgeText;
  final String khmerSampleText;
  final String durationText;
  final String description;

  const VoiceProfile({
    required this.id,
    required this.name,
    required this.type,
    required this.neuralCode,
    required this.avatarUrl,
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
    neuralCode: 'AI Dynamic Cast Detection',
    avatarUrl: '',
    roleTag: 'Auto-Cast Engine',
    badgeText: 'Auto-Cast',
    khmerSampleText: 'ស្វ័យប្រវត្តិកំណត់សំឡេងតួអង្គ',
    durationText: 'Auto',
    description: 'Smart auto-detects male and female character voices automatically.',
  );

  static const VoiceProfile pisethNeural = VoiceProfile(
    id: 'voice_piseth',
    name: 'Piseth Neural',
    type: VoiceType.male,
    neuralCode: 'km-KH-PisethNeural',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
    roleTag: 'Cinematic Deep Narrator',
    badgeText: 'Ultra Low Latency',
    khmerSampleText: 'សួស្តី! ខ្ញុំជាសំឡេងបកប្រែ',
    durationText: '0:03',
    description: 'Resonant, authoritative male narration for action & cinema trailers.',
  );

  static const VoiceProfile sreymomNeural = VoiceProfile(
    id: 'voice_sreymom',
    name: 'Sreymom Neural',
    type: VoiceType.female,
    neuralCode: 'km-KH-SreymomNeural',
    avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&auto=format&fit=crop&q=80',
    roleTag: 'Warm & Natural Storyteller',
    badgeText: 'Optimal for Dialogues',
    khmerSampleText: 'សូមស្វាគមន៍មកកាន់ CineDub',
    durationText: '0:03',
    description: 'Expressive and clear female voice ideal for documentaries & dialogues.',
  );

  static const List<VoiceProfile> allProfiles = [
    autoCast,
    pisethNeural,
    sreymomNeural,
  ];
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
  }) {
    return DubbingTask(
      id: id,
      videoTitle: videoTitle,
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
  final String maskedToken;
  final String model;
  final String status; // 'Active', 'Standby', 'Cooldown'
  final int rpmUsage;
  final int rpmMax;
  final int latencyMs;

  const ApiKeyItem({
    required this.id,
    required this.alias,
    required this.maskedToken,
    required this.model,
    required this.status,
    required this.rpmUsage,
    required this.rpmMax,
    required this.latencyMs,
  });
}
