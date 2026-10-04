import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dub_models.dart';
import 'dubbing/dubbing_pipeline.dart';
import 'dubbing/ffmpeg_dubbing_service.dart';
import 'dubbing/gemini_translation_service.dart';

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
  // The four real pipeline stages. Their duration is now driven by the actual
  // work (FFmpeg / Gemini / Edge TTS) rather than a fixed dummy clock.
  static const int _pipelineStageCount = 4;

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

  /// Monotonic counter guaranteeing unique task ids, since `DateTime.now()`
  /// can return the same timestamp for jobs enqueued in quick succession.
  int _taskIdCounter = 0;

  /// Monotonic counter guaranteeing unique API key ids for the same reason.
  int _apiKeyCounter = 0;

  /// Cursor used by the "Round-Robin" key rotation strategy.
  int _keyRoundRobinIndex = 0;

  /// Guards notifications that may land after [dispose].
  bool _disposed = false;

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
      // Loading is fire-and-forget from the constructor, so it can land after
      // the state was disposed (e.g. in tests). That is harmless.
      if (_disposed) return;
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

  /// Creates a brand-new dubbing task for the currently selected voice model.
  ///
  /// [taskId] must be unique: it is what identifies the job in the queue (for
  /// example when removing it). A monotonic counter is mixed into the id
  /// because `DateTime.now()` is not fine-grained enough on every platform —
  /// several jobs enqueued in the same instant would otherwise collide.
  DubbingTask _createTask({
    required String videoTitle,
    required String duration,
    required String fileSpecs,
    required String taskId,
    String? videoPath,
  }) {
    final voice = _selectedVoice;
    return DubbingTask(
      id: taskId,
      videoTitle: videoTitle,
      videoPath: videoPath,
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

  /// Generates an id that is guaranteed not to clash with any other task.
  String _generateTaskId() {
    _taskIdCounter += 1;
    return 'task_${DateTime.now().microsecondsSinceEpoch}_$_taskIdCounter';
  }

  /// Adds [videoTitle] (with the currently selected voice model) to the dubbing
  /// queue. When the pipeline is idle the task starts immediately, otherwise it
  /// is appended to the bottom of the queue and runs once earlier jobs finish.
  void startNewDubbingJob({
    required String videoTitle,
    required String duration,
    required String fileSpecs,
    String? videoPath,
  }) {
    final task = _createTask(
      videoTitle: videoTitle,
      duration: duration,
      fileSpecs: fileSpecs,
      taskId: _generateTaskId(),
      videoPath: videoPath,
    );

    if (_activeTask == null || !_activeTask!.isProcessing) {
      _activeTask = task;
      _runActiveTask(task);
    } else {
      _queuedTasks.add(
        task.copyWith(
          isProcessing: false,
          isQueued: true,
          stages: _buildStages(voice: task.voiceProfile, activeStageIndex: -1),
          liveStatusLog:
              'Waiting in queue position #${_queuedTasks.length + 1}',
        ),
      );
    }

    // Navigate to Queue tab to see live processing
    _currentTabIndex = 1;
    notifyListeners();
  }

  /// Aborts the running render and immediately starts the next queued task.
  Future<void> terminateActiveProcess() async {
    await _activePipeline?.cancel();
    _releasePipelineSlot();
    _activeTask = null;
    _startNextQueuedTask();
    notifyListeners();
  }

  /// Removes the queued task with [taskId] from the queue without touching the
  /// currently active render.
  ///
  /// Returns `true` when a task was found and removed. The remaining queue
  /// entries are renumbered so their live log keeps matching their position.
  bool removeQueuedTask(String taskId) {
    final index = _queuedTasks.indexWhere((task) => task.id == taskId);
    if (index == -1) return false;

    _queuedTasks.removeAt(index);
    _renumberQueue();
    notifyListeners();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Real pipeline execution
  // ---------------------------------------------------------------------------

  /// Pipeline instance of the running job, used to cancel it on terminate.
  DubbingPipeline? _activePipeline;

  /// Overrides how the pipeline is built. Tests use this to run a fake
  /// pipeline without touching FFmpeg, Gemini or Edge TTS.
  @visibleForTesting
  DubbingPipeline Function()? pipelineFactory;

  /// Overrides the directory used for intermediate files. Tests point this at a
  /// temp folder so no plugin channels are required.
  @visibleForTesting
  String? workDirOverride;

  /// Guards against two pipeline runs overlapping (terminate racing completion).
  bool _isRunningPipeline = false;

  DubbingPipeline _createPipeline() =>
      pipelineFactory?.call() ?? DubbingPipeline();

  /// Directory that holds intermediate audio, SRT and rendered output.
  Future<String> _resolveWorkDir() async {
    final override = workDirOverride;
    if (override != null) return override;

    final dir = await getApplicationDocumentsDirectory();
    final workDir = Directory('${dir.path}/dubbing_jobs');
    if (!workDir.existsSync()) {
      await workDir.create(recursive: true);
    }
    return workDir.path;
  }

  /// Runs the four real dubbing stages for [task] and reports progress.
  Future<void> _runActiveTask(DubbingTask task) async {
    if (_isRunningPipeline) return;

    final videoPath = task.videoPath;
    if (videoPath == null || videoPath.isEmpty) {
      _failActiveTask(
        task,
        'No source file on disk — re-pick the video and try again.',
      );
      return;
    }

    final key = nextApiKey();
    if (key == null) {
      _failActiveTask(
        task,
        'No Gemini API key available. Add one in the Settings tab first.',
      );
      return;
    }
    recordKeyUsage(key.id);

    final pipeline = _createPipeline();
    _activePipeline = pipeline;
    _isRunningPipeline = true;

    // Snapshot tuning + model so mid-job changes cannot corrupt a running job.
    final voice = task.voiceProfile;
    final pitch = _pitchHz;
    final speed = _speedMultiplier;
    final ducking = _duckingPercent;
    final model = _selectedModel;

    try {
      final workDir = await _resolveWorkDir();
      final result = await pipeline.run(
        videoPath: videoPath,
        workDir: workDir,
        voice: voice,
        apiKey: key.token,
        modelDisplayName: model,
        pitchHz: pitch,
        speedMultiplier: speed,
        duckingPercent: ducking,
        onProgress: _applyProgress,
      );

      if (pipeline.isCancelled) return;

      // Release the slot *before* promoting the next job, otherwise
      // `_runActiveTask` would bail out on the guard flag and the queue would
      // stall forever.
      _releasePipelineSlot();

      _completedTasks.insert(
        0,
        task.copyWith(
          progress: 1.0,
          isProcessing: false,
          isCompleted: true,
          outputPath: result.outputVideoPath,
          stages: _buildStages(
            voice: voice,
            activeStageIndex: _pipelineStageCount,
          ),
          liveStatusLog: 'All 4 stages completed • Output ready',
        ),
      );

      _activeTask = null;
      _startNextQueuedTask();
    } on FfmpegCancelledException {
      // Terminated from the Queue screen; there is nothing to record.
      _releasePipelineSlot();
      return;
    } catch (e) {
      _releasePipelineSlot();
      if (pipeline.isCancelled) return;
      _failActiveTask(task, _describeError(e));
    }
  }

  /// Frees the single pipeline slot so the next queued job can start.
  void _releasePipelineSlot() {
    _isRunningPipeline = false;
    _activePipeline = null;
  }

  /// Mirrors a [DubbingProgress] update onto the active task.
  void _applyProgress(DubbingProgress progress) {
    final task = _activeTask;
    if (task == null) return;

    final stageIndex = progress.stageIndex.clamp(0, _pipelineStageCount - 1);
    _activeTask = task.copyWith(
      progress: progress.fraction.clamp(0.0, 1.0),
      stages: _buildStages(
        voice: task.voiceProfile,
        activeStageIndex: stageIndex,
      ),
      liveStatusLog: progress.message,
    );
    notifyListeners();
  }

  /// Marks the running job as failed, surfaces the reason and promotes the next
  /// queued job so the pipeline never deadlocks.
  void _failActiveTask(DubbingTask task, String reason) {
    _completedTasks.insert(
      0,
      task.copyWith(
        isProcessing: false,
        progress: 0.0,
        liveStatusLog: 'Failed • $reason',
      ),
    );

    _activeTask = null;
    _startNextQueuedTask();
    notifyListeners();
  }

  String _describeError(Object error) {
    if (error is DubbingConfigurationException) return error.message;
    if (error is GeminiTranslationException) return error.message;
    if (error is FfmpegException) {
      final logs = error.logs;
      final tail = logs == null || logs.isEmpty ? '' : ' (${logs.trim()})';
      return 'FFmpeg error$tail';
    }
    return error.toString();
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
    _runActiveTask(next);
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
        id: _generateKeyId(),
        alias: alias.isEmpty ? 'Custom Key' : alias,
        maskedToken: masked,
        // The unmasked token is kept so the pipeline can actually call Gemini;
        // only `maskedToken` is ever rendered in the UI.
        token: token,
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

  /// Key pool entries that can actually be used for an API call.
  ///
  /// Keys saved before raw tokens were persisted have an empty
  /// [ApiKeyItem.token] and are skipped, as are ones flagged as cooling down.
  List<ApiKeyItem> get usableApiKeys => _apiKeys
      .where((key) => key.token.isNotEmpty && key.status != 'Cooldown')
      .toList(growable: false);

  /// Injects a key that has no raw token, mimicking a record persisted before
  /// real tokens were stored. Used by tests to cover the migration path.
  @visibleForTesting
  void previewLegacyKeyWithoutToken({String alias = 'Legacy Key'}) {
    _apiKeys.add(
      ApiKeyItem(
        id: _generateKeyId(),
        alias: alias,
        maskedToken: 'AIzaSy•••••••••••',
        token: '',
        model: _selectedModel.split(' ')[0],
        status: 'Active',
        rpmUsage: 0,
        rpmMax: 60,
        latencyMs: 120,
      ),
    );
    notifyListeners();
  }

  /// Returns the next API key according to [_keyRotationStrategy], or `null`
  /// when the pool holds no usable key.
  ApiKeyItem? nextApiKey() {
    final pool = usableApiKeys;
    if (pool.isEmpty) return null;

    switch (_keyRotationStrategy) {
      case 'Round-Robin':
        final key = pool[_keyRoundRobinIndex % pool.length];
        _keyRoundRobinIndex = (_keyRoundRobinIndex + 1) % pool.length;
        return key;
      case 'Failover Priority':
        // Lowest latency first: the fastest key is tried before any fallback.
        final sorted = [...pool]
          ..sort((a, b) => a.latencyMs.compareTo(b.latencyMs));
        return sorted.first;
      case 'Rate-Limit Balanced':
      default:
        // Fewest requests in the current window first, so no single key is
        // hammered until it hits its RPM ceiling.
        final sorted = [...pool]
          ..sort((a, b) => a.rpmUsage.compareTo(b.rpmUsage));
        return sorted.first;
    }
  }

  /// Generates an id that is guaranteed not to clash with any other API key.
  String _generateKeyId() {
    _apiKeyCounter += 1;
    return 'key_${DateTime.now().microsecondsSinceEpoch}_$_apiKeyCounter';
  }

  /// Records that [keyId] served a request, bumping its RPM counter.
  void recordKeyUsage(String keyId) {
    final index = _apiKeys.indexWhere((key) => key.id == keyId);
    if (index == -1) return;

    final key = _apiKeys[index];
    _apiKeys[index] = ApiKeyItem(
      id: key.id,
      alias: key.alias,
      maskedToken: key.maskedToken,
      token: key.token,
      model: key.model,
      status: key.status,
      rpmUsage: key.rpmUsage + 1,
      rpmMax: key.rpmMax,
      latencyMs: key.latencyMs,
    );
    notifyListeners();
  }

  void removeApiKey(String id) {
    _apiKeys.removeWhere((item) => item.id == id);
    _saveApiKeysToStorage();
    notifyListeners();
  }

  /// Cancels any in-flight FFmpeg work so a running job does not outlive the
  /// app state.
  @override
  void dispose() {
    _disposed = true;
    _activePipeline?.cancel();
    super.dispose();
  }
}
