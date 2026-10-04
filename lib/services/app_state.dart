import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dub_models.dart';

class AppState extends ChangeNotifier {
  SharedPreferences? _prefs;

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
    _prefs?.setString('selected_voice_id', profile.id);
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

  void setPlayingVoiceSampleId(String? id) {
    _playingVoiceSampleId = id;
    notifyListeners();
  }

  // Tasks Management
  // Dummy processing pipeline: 4 sequential stages, each taking an equal slice
  // of the total processing time (10s * 4 = 40s per video).
  static const int _pipelineStageCount = 4;
  static const Duration _stageDuration = Duration(seconds: 10);
  static const Duration _totalProcessingDuration =
      Duration(seconds: 10 * _pipelineStageCount);

  static const List<String> _stageTitles = [
    '1. Extract audio',
    '2. Transcribe and translate',
    '3. Generate audio',
    '4. Build video',
  ];

  static const List<IconData> _stageIcons = [
    Icons.audiotrack_rounded,
    Icons.translate_rounded,
    Icons.graphic_eq_rounded,
    Icons.movie_edit,
  ];

  static const Duration _tickInterval = Duration(milliseconds: 200);

  Timer? _progressTimer;
  Duration _activeElapsed = Duration.zero;

  /// The task currently being processed, or `null` when the pipeline is idle.
  DubbingTask? _activeTask;
  DubbingTask? get activeTask => _activeTask;

  /// Whether a dubbing job is actively being processed right now.
  bool get isPipelineBusy => _activeTask?.isProcessing ?? false;

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

  // Settings & API Keys (Default to empty list, no dummy keys)
  final List<ApiKeyItem> _apiKeys = [];
  List<ApiKeyItem> get apiKeys => List.unmodifiable(_apiKeys);

  String _selectedModel = 'Gemini 2.5 Flash';
  String get selectedModel => _selectedModel;

  String _selectedTone = 'Cinematic Dynamic';
  String get selectedTone => _selectedTone;

  String _keyRotationStrategy = 'Rate-Limit Balanced';
  String get keyRotationStrategy => _keyRotationStrategy;

  AppState() {
    loadSettingsFromStorage();
  }

  Future<void> loadSettingsFromStorage() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Restore selected voice profile
      final savedVoiceId = _prefs?.getString('selected_voice_id');
      if (savedVoiceId != null) {
        final match = VoiceProfile.allProfiles.firstWhere(
          (p) => p.id == savedVoiceId,
          orElse: () => VoiceProfile.autoCast,
        );
        _selectedVoice = match;
      }

      // Restore selected Gemini model
      final savedModel = _prefs?.getString('selected_gemini_model');
      if (savedModel != null && savedModel.isNotEmpty) {
        _selectedModel = savedModel;
      }

      // Restore Khmer dubbing tone
      final savedTone = _prefs?.getString('selected_tone');
      if (savedTone != null && savedTone.isNotEmpty) {
        _selectedTone = savedTone;
      }

      // Restore key rotation strategy
      final savedStrategy = _prefs?.getString('key_rotation_strategy');
      if (savedStrategy != null && savedStrategy.isNotEmpty) {
        _keyRotationStrategy = savedStrategy;
      }

      // Restore stored API keys pool
      final keysListJson = _prefs?.getStringList('stored_api_keys');
      if (keysListJson != null) {
        _apiKeys.clear();
        for (final itemStr in keysListJson) {
          try {
            final map = jsonDecode(itemStr) as Map<String, dynamic>;
            _apiKeys.add(ApiKeyItem.fromJson(map));
          } catch (e) {
            debugPrint('Error parsing saved API key item: $e');
          }
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings from storage: $e');
    }
  }

  void _saveApiKeysToStorage() {
    final listJson = _apiKeys.map((item) => jsonEncode(item.toJson())).toList();
    _prefs?.setStringList('stored_api_keys', listJson);
  }

  // ---------------------------------------------------------------------------
  // Dubbing queue & pipeline engine
  // ---------------------------------------------------------------------------

  /// Builds the four pipeline stages for [voice]. The stage at
  /// [activeStageIndex] is the one currently running, everything before it is
  /// completed and everything after it is pending/next-up. Pass -1 to leave all
  /// stages pending (queued task) or [_pipelineStageCount] to mark all completed.
  List<PipelineStage> _buildStages({
    required VoiceProfile voice,
    required int activeStageIndex,
  }) {
    return List.generate(_pipelineStageCount, (index) {
      final StageStatus status;
      if (index < activeStageIndex) {
        status = StageStatus.completed;
      } else if (index == activeStageIndex) {
        status = StageStatus.inProgress;
      } else if (index == activeStageIndex + 1) {
        status = StageStatus.nextUp;
      } else {
        status = StageStatus.pending;
      }

      final bool isDone = status == StageStatus.completed;
      final bool isRunning = status == StageStatus.inProgress;
      final String badgeText;
      if (isDone) {
        badgeText = 'Completed';
      } else if (isRunning) {
        badgeText = 'In Progress';
      } else if (status == StageStatus.nextUp) {
        badgeText = 'Next Up';
      } else {
        badgeText = 'Pending';
      }

      return PipelineStage(
        stageNumber: index + 1,
        title: _stageTitles[index],
        description: _stageDescription(index, status, voice),
        status: status,
        badgeText: badgeText,
        icon: isDone ? Icons.check_circle_rounded : _stageIcons[index],
      );
    });
  }

  /// Human readable description for a pipeline stage in a given [status].
  String _stageDescription(int index, StageStatus status, VoiceProfile voice) {
    final bool done = status == StageStatus.completed;
    final bool running = status == StageStatus.inProgress;
    switch (index) {
      case 0:
        if (done) return 'Demuxed 48kHz WAV audio stream';
        if (running) return 'Demuxing audio track to 48kHz WAV';
        return 'Awaiting audio extraction';
      case 1:
        if (done) return 'Khmer translation completed';
        if (running) return 'Translating dialogue via $_selectedModel';
        return 'Gemini Khmer translation queued';
      case 2:
        if (done) return 'Edge-TTS Khmer audio rendered';
        if (running) return 'Synthesizing Edge-TTS ${voice.id}';
        return 'Edge-TTS synthesis queued';
      default:
        if (done) return 'Final dubbed MP4 rendered';
        if (running) return 'Remuxing video & muxing Khmer audio';
        return 'Video remux & lip-sync pending';
    }
  }

  /// Console log line shown for the stage currently being processed.
  String _stageLog(int stageIndex, DubbingTask task) {
    switch (stageIndex) {
      case 0:
        return 'Extracting audio stream from ${task.videoTitle}...';
      case 1:
        return 'Translating dialogue to Khmer with $_selectedModel...';
      case 2:
        return 'Synthesizing Khmer speech with ${task.voiceProfile.id}...';
      default:
        return 'Remuxing final video with dubbed Khmer audio...';
    }
  }

  /// Creates a brand-new dubbing task for the currently selected voice model.
  DubbingTask _createTask({
    required String videoTitle,
    required String duration,
    required String fileSpecs,
  }) {
    final voice = _selectedVoice;
    return DubbingTask(
      id: 'task_${DateTime.now().microsecondsSinceEpoch}',
      videoTitle: videoTitle,
      duration: duration,
      fileSpecs: fileSpecs,
      voiceProfile: voice,
      progress: 0.0,
      isProcessing: true,
      isQueued: false,
      isCompleted: false,
      stages: _buildStages(voice: voice, activeStageIndex: 0),
      liveStatusLog: 'Preparing pipeline for $videoTitle',
    );
  }

  /// Adds [videoTitle] (with the currently selected voice model) to the dubbing
  /// queue. When the pipeline is idle the task starts immediately, otherwise it
  /// is appended to the bottom of the queue and runs once earlier jobs finish.
  void startNewDubbingJob({
    required String videoTitle,
    required String duration,
    required String fileSpecs,
  }) {
    final task = _createTask(
      videoTitle: videoTitle,
      duration: duration,
      fileSpecs: fileSpecs,
    );

    if (_activeTask == null || !_activeTask!.isProcessing) {
      _activeTask = task;
      _beginActiveProcessing();
    } else {
      _queuedTasks.add(
        task.copyWith(
          isProcessing: false,
          isQueued: true,
          stages: _buildStages(voice: task.voiceProfile, activeStageIndex: -1),
          liveStatusLog: 'Waiting in queue position #${_queuedTasks.length + 1}',
        ),
      );
    }

    // Navigate to Queue tab to see live processing
    _currentTabIndex = 1;
    notifyListeners();
  }

  /// Aborts the running render and immediately starts the next queued task.
  void terminateActiveProcess() {
    _progressTimer?.cancel();
    _progressTimer = null;
    _activeElapsed = Duration.zero;
    _activeTask = null;
    _startNextQueuedTask();
    notifyListeners();
  }

  void _beginActiveProcessing() {
    _progressTimer?.cancel();
    _activeElapsed = Duration.zero;
    _tickProcessing();
    _progressTimer = Timer.periodic(
      _tickInterval,
      (_) {
        _activeElapsed += _tickInterval;
        _tickProcessing();
      },
    );
  }

  void _tickProcessing() {
    final task = _activeTask;
    if (task == null || !task.isProcessing) return;

    if (_activeElapsed >= _totalProcessingDuration) {
      _completeActiveTask();
      return;
    }

    var stageIndex =
        _activeElapsed.inMilliseconds ~/ _stageDuration.inMilliseconds;
    if (stageIndex >= _pipelineStageCount) {
      stageIndex = _pipelineStageCount - 1;
    }
    var progress =
        _activeElapsed.inMilliseconds / _totalProcessingDuration.inMilliseconds;
    if (progress > 1.0) progress = 1.0;

    _activeTask = task.copyWith(
      progress: progress,
      stages: _buildStages(
        voice: task.voiceProfile,
        activeStageIndex: stageIndex,
      ),
      liveStatusLog: _stageLog(stageIndex, task),
    );
    notifyListeners();
  }

  void _completeActiveTask() {
    _progressTimer?.cancel();
    _progressTimer = null;
    final task = _activeTask;
    if (task == null) return;

    _completedTasks.insert(
      0,
      task.copyWith(
        progress: 1.0,
        isProcessing: false,
        isCompleted: true,
        stages: _buildStages(
          voice: task.voiceProfile,
          activeStageIndex: _pipelineStageCount,
        ),
        liveStatusLog: 'All 4 stages completed • Output ready',
      ),
    );

    _activeTask = null;
    _activeElapsed = Duration.zero;

    _startNextQueuedTask();
    notifyListeners();
  }

  /// Pops the next queued task (if any) and starts processing it.
  void _startNextQueuedTask() {
    if (_queuedTasks.isEmpty) return;

    final next = _queuedTasks.removeAt(0);
    _renumberQueue();
    _activeTask = next.copyWith(
      isProcessing: true,
      isQueued: false,
      progress: 0.0,
      liveStatusLog: 'Starting pipeline for ${next.videoTitle}',
    );
    _beginActiveProcessing();
  }

  /// Keeps queue-position labels in the live log in sync after a dequeue.
  void _renumberQueue() {
    for (var i = 0; i < _queuedTasks.length; i++) {
      _queuedTasks[i] = _queuedTasks[i].copyWith(
        liveStatusLog: 'Waiting in queue position #${i + 1}',
      );
    }
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
    _prefs?.setString('selected_gemini_model', model);
    notifyListeners();
  }

  void setSelectedTone(String tone) {
    _selectedTone = tone;
    _prefs?.setString('selected_tone', tone);
    notifyListeners();
  }

  void setKeyRotationStrategy(String strategy) {
    _keyRotationStrategy = strategy;
    _prefs?.setString('key_rotation_strategy', strategy);
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
    _saveApiKeysToStorage();
    notifyListeners();
  }

  void removeApiKey(String id) {
    _apiKeys.removeWhere((item) => item.id == id);
    _saveApiKeysToStorage();
    notifyListeners();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }
}
