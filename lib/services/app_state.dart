import 'dart:async';
import 'package:flutter/material.dart';
import '../models/dub_models.dart';

class AppState extends ChangeNotifier {
  // Navigation
  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  void setTabIndex(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  // Voice Selection & Tuning
  VoiceProfile _selectedVoice = VoiceProfile.autoCast;
  VoiceProfile get selectedVoice => _selectedVoice;

  double _pitchHz = 0.0;
  double get pitchHz => _pitchHz;

  double _speedMultiplier = 1.05;
  double get speedMultiplier => _speedMultiplier;

  double _duckingPercent = -25.0;
  double get duckingPercent => _duckingPercent;

  String? _playingVoiceSampleId;
  String? get playingVoiceSampleId => _playingVoiceSampleId;

  void selectVoice(VoiceProfile profile) {
    _selectedVoice = profile;
    notifyListeners();
  }

  void setPitch(double val) {
    _pitchHz = val;
    notifyListeners();
  }

  void setSpeed(double val) {
    _speedMultiplier = val;
    notifyListeners();
  }

  void setDucking(double val) {
    _duckingPercent = val;
    notifyListeners();
  }

  void resetTuning() {
    _pitchHz = 0.0;
    _speedMultiplier = 1.05;
    _duckingPercent = -25.0;
    notifyListeners();
  }

  void toggleVoiceSample(String id) {
    if (_playingVoiceSampleId == id) {
      _playingVoiceSampleId = null;
    } else {
      _playingVoiceSampleId = id;
    }
    notifyListeners();
  }

  // Tasks Management
  Timer? _progressTimer;

  late DubbingTask _activeTask;
  DubbingTask get activeTask => _activeTask;

  final List<DubbingTask> _queuedTasks = [];
  List<DubbingTask> get queuedTasks => List.unmodifiable(_queuedTasks);

  final List<DubbingTask> _completedTasks = [];
  List<DubbingTask> get completedTasks => List.unmodifiable(_completedTasks);

  // Player State
  bool _isPlayingVideo = false;
  bool get isPlayingVideo => _isPlayingVideo;

  bool _isSubtitleEnabled = true;
  bool get isSubtitleEnabled => _isSubtitleEnabled;

  bool _isKhmerAudioTrack = true; // true = Khmer AI, false = Original English
  bool get isKhmerAudioTrack => _isKhmerAudioTrack;

  double _playbackSeconds = 74.0; // 01:14
  double get playbackSeconds => _playbackSeconds;
  final double totalVideoDurationSeconds = 110.0; // 01:50

  String _saveGalleryState = 'idle'; // 'idle', 'saving', 'saved'
  String get saveGalleryState => _saveGalleryState;

  // Settings & API Keys
  final List<ApiKeyItem> _apiKeys = [
    const ApiKeyItem(
      id: 'key_1',
      alias: 'Personal Key (Gemini 1.5 Pro)',
      maskedToken: 'AIzaSyD•••••••••••••••••••••98xK1',
      model: 'Gemini 1.5 Pro',
      status: 'Active',
      rpmUsage: 12,
      rpmMax: 15,
      latencyMs: 142,
    ),
    const ApiKeyItem(
      id: 'key_2',
      alias: 'Studio Team Key (Gemini 1.5 Flash)',
      maskedToken: 'AIzaSyB•••••••••••••••••••••44Lz9',
      model: 'Gemini 1.5 Flash',
      status: 'Standby',
      rpmUsage: 4,
      rpmMax: 60,
      latencyMs: 98,
    ),
    const ApiKeyItem(
      id: 'key_3',
      alias: 'Backup Free Tier',
      maskedToken: 'AIzaSyA•••••••••••••••••••••77qW2',
      model: 'Gemini 1.5 Flash',
      status: 'Cooldown',
      rpmUsage: 15,
      rpmMax: 15,
      latencyMs: 210,
    ),
  ];
  List<ApiKeyItem> get apiKeys => List.unmodifiable(_apiKeys);

  String _selectedModel = 'Gemini 1.5 Pro (High Fidelity)';
  String get selectedModel => _selectedModel;

  String _selectedTone = 'Cinematic Dynamic';
  String get selectedTone => _selectedTone;

  String _keyRotationStrategy = 'Rate-Limit Balanced';
  String get keyRotationStrategy => _keyRotationStrategy;

  AppState() {
    _initializeDefaultTasks();
    _startLiveSimulation();
  }

  void _initializeDefaultTasks() {
    _activeTask = DubbingTask(
      id: 'task_active_01',
      videoTitle: 'Cyber_Action_Trailer_1080p.mp4',
      duration: '02:45',
      fileSpecs: '48.2 MB • H.264 / AAC • 1080p 60fps',
      voiceProfile: VoiceProfile.pisethNeural,
      progress: 0.64,
      isProcessing: true,
      isQueued: false,
      isCompleted: false,
      stages: const [
        PipelineStage(
          stageNumber: 1,
          title: '1. Extract audio',
          description: 'Demuxed 48kHz WAV audio stream',
          status: StageStatus.completed,
          badgeText: 'Completed',
          icon: Icons.check_circle_rounded,
        ),
        PipelineStage(
          stageNumber: 2,
          title: '2. Transcribe and translate',
          description: 'Translating to Khmer SRT via Gemini 1.5 • Segment 14/22',
          status: StageStatus.inProgress,
          badgeText: 'In Progress (68%)',
          icon: Icons.sync_rounded,
        ),
        PipelineStage(
          stageNumber: 3,
          title: '3. Generate audio',
          description: 'Edge-TTS km-KH-PisethNeural • Synthesis queue ready',
          status: StageStatus.nextUp,
          badgeText: 'Next Up',
          icon: Icons.graphic_eq_rounded,
        ),
        PipelineStage(
          stageNumber: 4,
          title: '4. Build video',
          description: 'Remux & Lip-sync • Final MP4 rendering',
          status: StageStatus.pending,
          badgeText: 'Pending',
          icon: Icons.movie_edit,
        ),
      ],
      liveStatusLog: 'Translating dialogue chunk #14: "The neural firewall has collapsed."',
    );

    _queuedTasks.add(
      const DubbingTask(
        id: 'task_queued_01',
        videoTitle: 'Angkor_Historical_Doc_Trailer.mp4',
        duration: '04:10',
        fileSpecs: '72.4 MB • 4K UHD • 24fps',
        voiceProfile: VoiceProfile.sreymomNeural,
        progress: 0.0,
        isProcessing: false,
        isQueued: true,
        isCompleted: false,
        stages: [
          PipelineStage(
            stageNumber: 1,
            title: '1. Extract audio',
            description: 'Awaiting audio extraction runner',
            status: StageStatus.pending,
            badgeText: 'Queued',
            icon: Icons.hourglass_top_rounded,
          ),
          PipelineStage(
            stageNumber: 2,
            title: '2. Transcribe and translate',
            description: 'Gemini 1.5 Khmer Documentary Prompt',
            status: StageStatus.pending,
            badgeText: 'Pending',
            icon: Icons.translate_rounded,
          ),
          PipelineStage(
            stageNumber: 3,
            title: '3. Generate audio',
            description: 'Edge-TTS km-KH-SreymomNeural',
            status: StageStatus.pending,
            badgeText: 'Pending',
            icon: Icons.volume_up_rounded,
          ),
          PipelineStage(
            stageNumber: 4,
            title: '4. Build video',
            description: 'Full HDR Rec.709 color grade remux',
            status: StageStatus.pending,
            badgeText: 'Pending',
            icon: Icons.video_file_rounded,
          ),
        ],
        liveStatusLog: 'Waiting in queue position #1',
      ),
    );

    _completedTasks.add(
      const DubbingTask(
        id: 'task_completed_01',
        videoTitle: 'SciFi_Neon_Scene_Dubbed.mp4',
        duration: '01:50',
        fileSpecs: '1080p 60fps • 48kHz • 54.2 MB',
        voiceProfile: VoiceProfile.autoCast,
        progress: 1.0,
        isProcessing: false,
        isQueued: false,
        isCompleted: true,
        stages: [
          PipelineStage(
            stageNumber: 1,
            title: '1. Extract audio',
            description: 'Demuxed 48kHz WAV audio stream',
            status: StageStatus.completed,
            badgeText: 'Completed',
            icon: Icons.check_circle_rounded,
          ),
          PipelineStage(
            stageNumber: 2,
            title: '2. Transcribe and translate',
            description: 'Gemini 1.5 Khmer Studio Prompt (22/22 segments)',
            status: StageStatus.completed,
            badgeText: 'Completed',
            icon: Icons.check_circle_rounded,
          ),
          PipelineStage(
            stageNumber: 3,
            title: '3. Generate audio',
            description: 'Edge-TTS Dual Smart Multi-Speaker',
            status: StageStatus.completed,
            badgeText: 'Completed',
            icon: Icons.check_circle_rounded,
          ),
          PipelineStage(
            stageNumber: 4,
            title: '4. Build video',
            description: 'Rendered H.264 / AAC 60fps',
            status: StageStatus.completed,
            badgeText: 'Completed',
            icon: Icons.check_circle_rounded,
          ),
        ],
        liveStatusLog: 'Ready for gallery export',
      ),
    );
  }

  void _startLiveSimulation() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (_activeTask.isProcessing) {
        double newProgress = _activeTask.progress + 0.02;
        if (newProgress >= 1.0) {
          newProgress = 1.0;
          _activeTask = _activeTask.copyWith(
            progress: 1.0,
            isProcessing: false,
            isCompleted: true,
            liveStatusLog: 'All 4 stages completed! Output rendered.',
          );
          _completedTasks.insert(0, _activeTask);
        } else {
          // Dynamic stage progression logic
          List<PipelineStage> updatedStages = List.from(_activeTask.stages);
          if (newProgress > 0.75) {
            updatedStages[1] = updatedStages[1].copyWith(
              status: StageStatus.completed,
              badgeText: 'Done',
              description: 'Completed 22/22 segments translated',
            );
            updatedStages[2] = updatedStages[2].copyWith(
              status: StageStatus.inProgress,
              badgeText: 'Generating Audio',
              description: 'Synthesizing Edge-TTS km-KH-PisethNeural',
            );
          }
          _activeTask = _activeTask.copyWith(
            progress: newProgress,
            stages: updatedStages,
            liveStatusLog: 'Processing segment ${((newProgress * 22).clamp(1, 22)).toInt()}/22 with Gemini 1.5...',
          );
        }
        notifyListeners();
      }
    });
  }

  void startNewDubbingJob({
    required String videoTitle,
    required String duration,
    required String fileSpecs,
  }) {
    _activeTask = DubbingTask(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      videoTitle: videoTitle,
      duration: duration,
      fileSpecs: fileSpecs,
      voiceProfile: _selectedVoice,
      progress: 0.05,
      isProcessing: true,
      isQueued: false,
      isCompleted: false,
      stages: [
        const PipelineStage(
          stageNumber: 1,
          title: '1. Extract audio',
          description: 'Demuxing audio track to 48kHz WAV',
          status: StageStatus.inProgress,
          badgeText: 'Starting...',
          icon: Icons.sync_rounded,
        ),
        const PipelineStage(
          stageNumber: 2,
          title: '2. Transcribe and translate',
          description: 'Gemini 1.5 Flash translation queued',
          status: StageStatus.nextUp,
          badgeText: 'Next Up',
          icon: Icons.translate_rounded,
        ),
        PipelineStage(
          stageNumber: 3,
          title: '3. Generate audio',
          description: 'Edge-TTS ${_selectedVoice.neuralCode}',
          status: StageStatus.pending,
          badgeText: 'Pending',
          icon: Icons.graphic_eq_rounded,
        ),
        const PipelineStage(
          stageNumber: 4,
          title: '4. Build video',
          description: 'Video remuxing and subtitle burnt-in',
          status: StageStatus.pending,
          badgeText: 'Pending',
          icon: Icons.movie_edit,
        ),
      ],
      liveStatusLog: 'Demuxing media tracks from $videoTitle',
    );

    // Navigate to Queue tab to see live processing
    _currentTabIndex = 1;
    notifyListeners();
  }

  void terminateActiveProcess() {
    _activeTask = _activeTask.copyWith(
      isProcessing: false,
      liveStatusLog: 'Process cancelled by user.',
    );
    notifyListeners();
  }

  // Player Controls
  void togglePlayVideo() {
    _isPlayingVideo = !_isPlayingVideo;
    notifyListeners();
  }

  void toggleSubtitle() {
    _isSubtitleEnabled = !_isSubtitleEnabled;
    notifyListeners();
  }

  void setAudioTrack(bool isKhmer) {
    _isKhmerAudioTrack = isKhmer;
    notifyListeners();
  }

  void seekVideo(double seconds) {
    _playbackSeconds = seconds.clamp(0.0, totalVideoDurationSeconds);
    notifyListeners();
  }

  void saveToGallery(VoidCallback onDone) {
    _saveGalleryState = 'saving';
    notifyListeners();

    Timer(const Duration(milliseconds: 1400), () {
      _saveGalleryState = 'saved';
      notifyListeners();
      onDone();

      Timer(const Duration(seconds: 3), () {
        _saveGalleryState = 'idle';
        notifyListeners();
      });
    });
  }

  // Settings & Keys
  void setSelectedModel(String model) {
    _selectedModel = model;
    notifyListeners();
  }

  void setSelectedTone(String tone) {
    _selectedTone = tone;
    notifyListeners();
  }

  void setKeyRotationStrategy(String strategy) {
    _keyRotationStrategy = strategy;
    notifyListeners();
  }

  void addApiKey(String alias, String token) {
    String masked = token.length > 8
        ? '${token.substring(0, 7)}•••••••••••••••••••••${token.substring(token.length - 4)}'
        : 'AIzaSy•••••••••••';

    _apiKeys.add(
      ApiKeyItem(
        id: 'key_${DateTime.now().millisecondsSinceEpoch}',
        alias: alias.isEmpty ? 'Custom Key' : alias,
        maskedToken: masked,
        model: _selectedModel.split(' ')[0],
        status: 'Active',
        rpmUsage: 0,
        rpmMax: 60,
        latencyMs: 115,
      ),
    );
    notifyListeners();
  }

  void removeApiKey(String id) {
    _apiKeys.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }
}
