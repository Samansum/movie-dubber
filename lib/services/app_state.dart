import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_l10n.dart';
import '../models/dub_models.dart';
import 'dubbing/dubbing_pipeline.dart';
import 'dubbing/ffmpeg_dubbing_service.dart';
import 'dubbing/gemini_translation_service.dart';
import 'dubbing/tts_segment_service.dart';
import 'dubbing/workspace_cleanup_service.dart';
import 'license/license_status.dart';

class AppState extends ChangeNotifier {
  SharedPreferences? _prefs;

  // License
  /// Where the app stands with respect to licensing.
  ///
  /// Starts [LicenseStatus.unknown]: the stored license has not been read yet.
  /// The app UI renders while `unknown` so a licensed user never sees the
  /// activation screen flash on launch, but [isLicenseBlocked] keeps the
  /// dubbing pipeline shut until the read resolves to [LicenseStatus.valid].
  LicenseStatus _licenseStatus = LicenseStatus.unknown;

  /// Why the app is locked, shown above the key field. `null` when the app is
  /// simply not activated yet.
  String? _licenseLockReason;

  LicenseStatus get licenseStatus => _licenseStatus;

  /// Non-null only while [licenseStatus] is [LicenseStatus.locked].
  String? get licenseLockReason => _licenseLockReason;

  /// Whether the activation gate should be mounted over the app.
  ///
  /// Deliberately narrower than [isLicenseBlocked]: the gate appears only once
  /// a check has positively reported [LicenseStatus.locked] — never during the
  /// [LicenseStatus.unknown] window between launch and the first
  /// secure-storage read, which is what stops it flashing on every launch.
  bool get showLicenseGate => _licenseStatus == LicenseStatus.locked;

  /// Whether the dubbing pipeline is allowed to start a job.
  ///
  /// Reads the in-memory status only and never performs I/O: the pipeline guard
  /// must stay synchronous so a job can be refused before any network call.
  bool get isLicenseBlocked => _licenseStatus != LicenseStatus.valid;

  /// Records the outcome of a license check and wakes any listeners.
  void setLicenseStatus(LicenseStatus status, {String? reason}) {
    if (_licenseStatus == status && _licenseLockReason == reason) return;
    _licenseStatus = status;
    _licenseLockReason = status == LicenseStatus.locked ? reason : null;
    notifyListeners();
  }

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

  double _duckingPercent = 0.25;
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
  static const int _pipelineStageCount = DubbingStageCatalog.stageCount;

  /// Titles resolved for the current App Language. Re-read on every build
  /// rather than cached in a const, so switching language re-renders them.
  List<String> get _stageTitles => DubbingStageCatalog.titlesFor(_appLocale);

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

  /// Jobs that stopped on an error. Kept apart from [_completedTasks] so a
  /// crashed render is never presented as a successful one.
  final List<DubbingTask> _failedTasks = [];
  List<DubbingTask> get failedTasks => List.unmodifiable(_failedTasks);

  // Player State
  /// Mirrors the real `video_player` play state so the rest of the app can
  /// observe playback without owning the controller.
  bool _isPlayingVideo = false;
  bool get isPlayingVideo => _isPlayingVideo;

  /// The completed job opened in the Player screen.
  ///
  /// Set by the Queue screen's "Play" button. Falls back to the most recent
  /// successful render so the Player tab is never empty after a job finishes.
  DubbingTask? _playerTask;
  DubbingTask? get playerTask =>
      _playerTask ?? (_completedTasks.isNotEmpty ? _completedTasks.first : null);

  /// Opens [task] in the Player screen and jumps to that tab.
  void openTaskInPlayer(DubbingTask task) {
    _playerTask = task;
    _isPlayingVideo = false;
    _saveGalleryState = 'idle';
    _currentTabIndex = 2;
    notifyListeners();
  }

  String _saveGalleryState = 'idle'; // 'idle', 'saving', 'saved', 'error'
  String get saveGalleryState => _saveGalleryState;

  /// Raw failure text from the last save attempt, `null` when it succeeded.
  String? _saveGalleryError;
  String? get saveGalleryError => _saveGalleryError;

  // Settings & API Keys (Default to empty list, no dummy keys)
  final List<ApiKeyItem> _apiKeys = [];
  List<ApiKeyItem> get apiKeys => List.unmodifiable(_apiKeys);

  String _selectedModel = 'Gemini 2.5 Flash';
  String get selectedModel => _selectedModel;

  String _selectedTone = 'Cinematic Dynamic';
  String get selectedTone => _selectedTone;

  String _keyRotationStrategy = 'Rate-Limit Balanced';
  String get keyRotationStrategy => _keyRotationStrategy;

  // App display language (Settings → App Language / ភាសា).
  //
  // Only English and Khmer are offered. The choice is persisted so it survives
  // a restart, and [_appLocale] is what MaterialApp is given as its `locale`
  // plus what [stringsFor] uses for text produced outside the widget tree.
  Locale _appLocale = const Locale('en');
  Locale get appLocale => _appLocale;

  /// Whether the app is currently displaying Khmer.
  bool get isKhmer => _appLocale.languageCode == 'km';

  /// Switches the whole UI to [languageCode] (`'en'` or `'km'`).
  ///
  /// Unknown codes fall back to English rather than throwing, so a stale or
  /// corrupt stored value can never blank the UI.
  void setAppLanguage(String languageCode) {
    final normalized = languageCode == 'km' ? 'km' : 'en';
    final next = Locale(normalized);
    if (_appLocale == next) return;
    _appLocale = next;
    _prefs?.setString('app_language', normalized);
    // Stage titles/badges/descriptions were rendered into the task models when
    // they were created, so rebuild them in the new language — otherwise jobs
    // already on screen would keep the previous language's text.
    _relocalizeTasks();
    notifyListeners();
  }

  /// Re-renders every stored task's stage text in the current App Language.
  ///
  /// Only the display strings change; status, progress, errors and ordering
  /// are copied across untouched.
  void _relocalizeTasks() {
    DubbingTask relocalize(DubbingTask task) => task.copyWith(
          stages: task.stages
              .map(
                (stage) => PipelineStage(
                  stageNumber: stage.stageNumber,
                  title: _stageTitles[stage.stageNumber - 1],
                  description: stage.status == StageStatus.failed
                      ? _failedStageDescription(stage.stageNumber - 1)
                      : _stageDescription(
                          stage.stageNumber - 1,
                          stage.status,
                          task.voiceProfile,
                        ),
                  status: stage.status,
                  badgeText: switch (stage.status) {
                    StageStatus.failed => stringsFor(_appLocale).badgeFailed,
                    StageStatus.completed =>
                      stringsFor(_appLocale).badgeCompleted,
                    StageStatus.inProgress =>
                      stringsFor(_appLocale).badgeInProgress,
                    StageStatus.nextUp => stringsFor(_appLocale).badgeNextUp,
                    StageStatus.pending => stringsFor(_appLocale).badgePending,
                  },
                  icon: stage.icon,
                ),
              )
              .toList(growable: false),
        );

    if (_activeTask != null) _activeTask = relocalize(_activeTask!);
    for (var i = 0; i < _queuedTasks.length; i++) {
      _queuedTasks[i] = relocalize(_queuedTasks[i]);
    }
    for (var i = 0; i < _completedTasks.length; i++) {
      _completedTasks[i] = relocalize(_completedTasks[i]);
    }
    for (var i = 0; i < _failedTasks.length; i++) {
      _failedTasks[i] = relocalize(_failedTasks[i]);
    }
  }

  AppState() {
    loadSettingsFromStorage();
  }

  /// Deletes artifacts left over from the previous session.
  ///
  /// The queue lives in memory only, so nothing can reference last run's
  /// renders once the app restarts. Sweeping them here stops the extracted
  /// audio, SRTs, per-cue MP3s and rendered videos from piling up on the
  /// user's device. Fire-and-forget: cleanup must never block the first frame.
  Future<WorkspaceCleanupReport> cleanupPreviousRun() async {
    final report = await WorkspaceCleanupService.cleanPreviousRun(
      workDirOverride: workDirOverride,
    );
    if (_disposed) return report;

    _lastCleanupReport = report;
    if (!report.isEmpty) {
      debugPrint(
        '[AppState] Startup cleanup removed ${report.removedPaths.length} '
        'artifact(s), freed ${report.freedBytes} bytes.',
      );
      for (final warning in report.warnings) {
        debugPrint('[AppState] Cleanup warning: $warning');
      }
    }
    return report;
  }

  /// Report from the most recent [cleanupPreviousRun], for diagnostics.
  WorkspaceCleanupReport? _lastCleanupReport;
  WorkspaceCleanupReport? get lastCleanupReport => _lastCleanupReport;

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

      // Restore the App Language chosen in Settings. Anything other than
      // 'km' resolves to English, matching setAppLanguage's fallback.
      final savedLanguage = _prefs?.getString('app_language');
      _appLocale = Locale(savedLanguage == 'km' ? 'km' : 'en');

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

      // Rate-limit cooldowns do not survive a restart, so any key left parked
      // by a previous session becomes usable again.
      reviveParkedKeys();

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
  ///
  /// When [failedStageIndex] is given, that stage is marked
  /// [StageStatus.failed] and every stage after it falls back to
  /// [StageStatus.pending] — the pipeline stopped, so nothing after it ran.
  List<PipelineStage> _buildStages({
    required VoiceProfile voice,
    required int activeStageIndex,
    int? failedStageIndex,
  }) {
    return List.generate(_pipelineStageCount, (index) {
      final StageStatus status;
      if (failedStageIndex != null) {
        // The pipeline stopped: everything before the failure finished,
        // everything after it never ran.
        if (index < failedStageIndex) {
          status = StageStatus.completed;
        } else if (index == failedStageIndex) {
          status = StageStatus.failed;
        } else {
          status = StageStatus.pending;
        }
      } else if (index < activeStageIndex) {
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
      final bool isFailed = status == StageStatus.failed;
      final l10n = stringsFor(_appLocale);
      final String badgeText;
      if (isFailed) {
        badgeText = l10n.badgeFailed;
      } else if (isDone) {
        badgeText = l10n.badgeCompleted;
      } else if (isRunning) {
        badgeText = l10n.badgeInProgress;
      } else if (status == StageStatus.nextUp) {
        badgeText = l10n.badgeNextUp;
      } else {
        badgeText = l10n.badgePending;
      }

      return PipelineStage(
        stageNumber: index + 1,
        title: _stageTitles[index],
        description:
            isFailed ? _failedStageDescription(index) : _stageDescription(index, status, voice),
        status: status,
        badgeText: badgeText,
        icon: switch (status) {
          StageStatus.completed => Icons.check_circle_rounded,
          StageStatus.failed => Icons.error_rounded,
          _ => _stageIcons[index],
        },
      );
    });
  }

  /// Description shown on the stage that stopped the pipeline.
  String _failedStageDescription(int index) {
    final l10n = stringsFor(_appLocale);
    switch (index) {
      case 0:
        return l10n.failedDesc0;
      case 1:
        return l10n.failedDesc1;
      case 2:
        return l10n.failedDesc2;
      default:
        return l10n.failedDesc3;
    }
  }

  /// Human readable description for a pipeline stage in a given [status].
  String _stageDescription(int index, StageStatus status, VoiceProfile voice) {
    final bool done = status == StageStatus.completed;
    final bool running = status == StageStatus.inProgress;
    final l10n = stringsFor(_appLocale);
    switch (index) {
      case 0:
        if (done) return l10n.stage0Done;
        if (running) return l10n.stage0Running;
        return l10n.stage0Pending;
      case 1:
        if (done) return l10n.stage1Done;
        if (running) return l10n.stage1Running;
        return l10n.stage1Pending;
      case 2:
        if (done) return l10n.stage2Done;
        if (running) return l10n.stage2Running;
        return l10n.stage2Pending;
      default:
        if (done) return l10n.stage3Done;
        if (running) return l10n.stage3Running;
        return l10n.stage3Pending;
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
      liveStatusLog: stringsFor(_appLocale).preparingPipeline(videoTitle),
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
    // Refuse before the task exists so a locked app never shows a queued job it
    // will not run. In-memory check only — no network request.
    if (isLicenseBlocked) {
      debugPrint('[AppState] startNewDubbingJob refused: license is '
          '${_licenseStatus.name}.');
      return;
    }

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
              stringsFor(_appLocale).waitingInQueue(_queuedTasks.length + 1),
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

  /// Stage index reported by the most recent [DubbingProgress] of the running
  /// job. Used to attribute errors that carry no explicit stage index.
  int _lastStageIndex = 0;

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

    // License gate. Deliberately reads the in-memory status only and makes no
    // network call: every job path (new job, dequeue, retry) funnels through
    // here, so this single check stops the job from spending a Gemini/FFmpeg
    // run while the app is locked.
    //
    // The task is failed rather than silently dropped, which releases the
    // single pipeline slot and promotes the next queued job instead of
    // leaving `_activeTask` spinning forever.
    if (isLicenseBlocked) {
      debugPrint('[AppState] Refusing to start ${task.videoTitle}: '
          'license is ${_licenseStatus.name}.');
      const reason = 'A valid license key is required to start a dubbing job.';
      _failActiveTask(
        task,
        DubbingStageCatalog.errorForStage(
          0,
          cause: const DubbingConfigurationException(reason),
          message: reason,
          details: 'AppState.isLicenseBlocked was true '
              '(license status: ${_licenseStatus.name}).',
        ),
      );
      return;
    }

    final videoPath = task.videoPath;
    if (videoPath == null || videoPath.isEmpty) {
      _failActiveTask(
        task,
        DubbingStageCatalog.errorForStage(
          0,
          cause: const DubbingConfigurationException(
            'No source file on disk — re-pick the video and try again.',
          ),
          message: 'No source file on disk — re-pick the video and try again.',
          details: 'task.videoPath was null or empty',
        ),
      );
      return;
    }

    final key = nextApiKey();
    if (key == null) {
      const reason = 'No Gemini API key available. '
          'Add one in the Settings tab first.';
      _failActiveTask(
        task,
        DubbingStageCatalog.errorForStage(
          1,
          cause: const DubbingConfigurationException(reason),
          message: reason,
          details: 'AppState.nextApiKey() returned null — the key pool has no '
              'usable key (empty token or Cooldown status).',
        ),
      );
      return;
    }
    recordKeyUsage(key.id);

    final pipeline = _createPipeline();
    _activePipeline = pipeline;
    _isRunningPipeline = true;
    // Fresh job => fresh stage attribution.
    _lastStageIndex = 0;

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
        // A failed job can be resumed at the stage that broke instead of
        // re-running every stage from scratch.
        startStage: task.resumeFromStage ?? 0,
        // Called by stage 2 when Gemini rate-limits us: park the throttled
        // key and hand back a different one to retry with.
        onRateLimited: () => rotateKey(key.id),
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
          liveStatusLog: stringsFor(_appLocale).allStagesCompleted,
        ),
      );

      _activeTask = null;
      _startNextQueuedTask();
    } on FfmpegCancelledException {
      // Terminated from the Queue screen; there is nothing to record.
      _releasePipelineSlot();
      return;
    } catch (e, stackTrace) {
      _releasePipelineSlot();
      if (pipeline.isCancelled) return;
      _failActiveTask(task, _describeError(e, stackTrace));
    }
  }

  /// Re-queues a failed job starting at the stage that failed.
  ///
  /// Stages before [resumeFromStage] already produced their artifacts, so the
  /// pipeline reuses them: a TTS retry skips Gemini entirely and only
  /// re-synthesizes the lines that failed. Returns `false` when the job is not
  /// in the failed list (e.g. it was already removed).
  bool retryFailedStage(String taskId, {int? fromStage}) {
    // Same in-memory guard as startNewDubbingJob — a retry would otherwise
    // re-enter the pipeline while the app is locked.
    if (isLicenseBlocked) return false;

    final index = _failedTasks.indexWhere((task) => task.id == taskId);
    if (index == -1) return false;

    final failed = _failedTasks.removeAt(index);
    final resumeFrom = fromStage ?? failed.failedStageIndex ?? 0;

    // The job rejoins the queue; it only starts once a slot frees up.
    final requeued = failed.copyWith(
      isProcessing: false,
      isQueued: true,
      isCompleted: false,
      progress: 0.0,
      error: null,
      resumeFromStage: resumeFrom,
      stages: _buildStages(
        voice: failed.voiceProfile,
        activeStageIndex: -1,
      ),
      liveStatusLog:
          stringsFor(_appLocale).queuedToRetry(DubbingStageCatalog.titleFor(resumeFrom)),
    );

    if (_activeTask == null || !_activeTask!.isProcessing) {
      _activeTask = requeued;
      _runActiveTask(requeued);
    } else {
      _queuedTasks.add(requeued);
    }

    notifyListeners();
    return true;
  }

  /// Removes a failed job from the queue screen.
  ///
  /// Returns `false` when no failed job carries [taskId].
  bool removeFailedTask(String taskId) {
    final before = _failedTasks.length;
    _failedTasks.removeWhere((task) => task.id == taskId);
    if (_failedTasks.length == before) return false;
    notifyListeners();
    return true;
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
    // Remember the stage currently executing so an error that arrives without
    // stage information can still be attributed to the right step.
    _lastStageIndex = stageIndex;

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

  /// Marks the running job as failed, records the raw diagnostic and promotes the
  /// next queued job so the pipeline never deadlocks.
  ///
  /// The job is moved to [_failedTasks] — never into [_completedTasks] — so a
  /// crashed render is not reported as "Done". The stage list is rebuilt from
  /// the *live* task so the stage that threw keeps its completed predecessors
  /// and is marked [StageStatus.failed], while every later stage drops back to
  /// pending.
  void _failActiveTask(DubbingTask task, DubbingError error) {
    // Use the live task when it is the same job, otherwise fall back to the
    // snapshot we were handed.
    final current = _activeTask?.id == task.id ? _activeTask! : task;
    final voice = current.voiceProfile;

    final failed = current.copyWith(
      isProcessing: false,
      isQueued: false,
      isCompleted: false,
      progress: current.progress.clamp(0.0, 1.0),
      stages: _buildStages(
        voice: voice,
        // The failed stage replaces whatever was running, so no stage is left
        // spinning once the pipeline has stopped.
        activeStageIndex: -1,
        failedStageIndex: error.stageIndex,
      ),
      liveStatusLog: stringsFor(_appLocale).stoppedAtStage(error.stageTitle, error.message),
      error: error,
    );

    _failedTasks.insert(0, failed);

    _activeTask = null;
    _startNextQueuedTask();
    notifyListeners();
  }

  /// Turns any thrown object into a [DubbingError] attributed to a stage.
  ///
  /// [DubbingStageException] already carries the stage index; anything else is
  /// attributed to the last stage that reported progress, which is the best
  /// available signal for an unattributed failure.
  DubbingError _describeError(Object error, [StackTrace? stackTrace]) {
    if (error is DubbingStageException) {
      return DubbingStageCatalog.errorForStage(
        error.stageIndex,
        cause: error.cause,
        stackTrace: error.stackTrace,
        message: _shortMessage(error.cause),
        details: _rawDetails(error.cause),
      );
    }

    return DubbingStageCatalog.errorForStage(
      _lastReportedStageIndex,
      cause: error,
      stackTrace: stackTrace,
      message: _shortMessage(error),
      details: _rawDetails(error),
    );
  }

  /// Index of the most recent stage that reported progress, used to attribute
  /// errors that arrive without explicit stage information.
  int get _lastReportedStageIndex =>
      _activeTask == null ? 0 : _lastStageIndex.clamp(0, _pipelineStageCount - 1);

  /// Best-effort one-line summary shown on the failure card.
  String _shortMessage(Object error) {
    if (error is DubbingConfigurationException) return error.message;
    if (error is GeminiTranslationException) return error.message;
    if (error is TtsEntryException) return error.summary;
    if (error is FfmpegException) {
      final logs = error.logs;
      final tail = (logs == null || logs.isEmpty) ? '' : ': ${logs.trim()}';
      return 'FFmpeg command failed$tail';
    }
    return error.toString();
  }

  /// Full, unfiltered error body — this is what the copy button exposes.
  String _rawDetails(Object error) {
    if (error is DubbingConfigurationException) return error.message;
    if (error is GeminiTranslationException) {
      // `details` carries the untouched SDK response body.
      return error.details.isEmpty ? error.message : error.details;
    }
    // Names the cue, voice, attempt count and the last underlying error.
    if (error is TtsEntryException) return error.details;

    if (error is FfmpegException) {
      // Keep the command *and* the raw log: the command identifies which of
      // the stages' FFmpeg invocations broke, the log says why.
      final logs = error.logs ?? '(no log output captured)';
      return 'Command:\n${error.command}\n\nFFmpeg log:\n$logs';
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
      liveStatusLog: stringsFor(_appLocale).startingPipeline(next.videoTitle),
    );
    _runActiveTask(next);
  }

  /// Keeps queue-position labels in the live log in sync after a dequeue.
  void _renumberQueue() {
    for (var i = 0; i < _queuedTasks.length; i++) {
      _queuedTasks[i] = _queuedTasks[i].copyWith(
        liveStatusLog: stringsFor(_appLocale).waitingInQueue(i + 1),
      );
    }
  }

  // Player Controls
  /// Mirrors the real player's play state into the app state.
  void setPlayingVideo(bool playing) {
    if (_isPlayingVideo != playing) {
      _isPlayingVideo = playing;
      notifyListeners();
    }
  }

  /// Copies the rendered video for [playerTask] into the device's public
  /// Movies/Videos collection.
  ///
  /// Uses the MediaStore-backed `gal` plugin, so the file is visible in a file
  /// manager / gallery app (not just inside the app sandbox). Errors are
  /// surfaced through [saveGalleryError] with the plugin's raw message rather
  /// than being swallowed.
  Future<void> saveToGallery() async {
    final task = playerTask;
    final sourcePath = task?.outputPath;

    if (task == null || sourcePath == null || sourcePath.isEmpty) {
      _saveGalleryState = 'error';
      _saveGalleryError =
          'No rendered video available for "${task?.videoTitle ?? 'unknown'}".';
      notifyListeners();
      return;
    }

    final source = File(sourcePath);
    if (!source.existsSync()) {
      _saveGalleryState = 'error';
      _saveGalleryError = 'The rendered video no longer exists on disk:\n'
          '$sourcePath';
      notifyListeners();
      return;
    }

    _saveGalleryState = 'saving';
    _saveGalleryError = null;
    notifyListeners();

    try {
      // Android 10 and below need an explicit grant before the shared
      // collection can be written to.
      if (!await Gal.hasAccess(toAlbum: true)) {
        await Gal.requestAccess(toAlbum: true);
      }

      // `album` becomes a sub-folder of the device's Movies directory.
      await Gal.putVideo(sourcePath, album: 'CineDub AI');

      _saveGalleryState = 'saved';
      _saveGalleryError = null;
    } on GalException catch (e) {
      _saveGalleryState = 'error';
      _saveGalleryError = '${e.type.message}\n(${e.type.name})';
    } catch (e) {
      _saveGalleryState = 'error';
      _saveGalleryError = e.toString();
    }

    notifyListeners();
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
  /// [ApiKeyItem.token] and are skipped, as are ones flagged as cooling down
  /// or still inside their cooldown window.
  List<ApiKeyItem> get usableApiKeys => _apiKeys
      .where((key) =>
          key.token.isNotEmpty &&
          key.status != 'Cooldown' &&
          !_isCoolingDown(key.id))
      .toList(growable: false);

  /// How long a rate-limited key stays sidelined before it is usable again.
  static const Duration _keyCooldown = Duration(seconds: 60);

  /// Key id -> the moment its cooldown expires.
  final Map<String, DateTime> _keyCooldownUntil = {};

  /// Key promoted by the last rate-limit rotation. It keeps serving requests
  /// until it hits its own limit.
  String? _preferredKeyId;

  bool _isCoolingDown(String keyId) {
    final until = _keyCooldownUntil[keyId];
    return until != null && until.isAfter(DateTime.now());
  }

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
  ///
  /// Once [rotateKey] promotes a key after a rate limit, that key is returned
  /// for every subsequent job until it hits its own limit — see
  /// [_preferredKeyId].
  ApiKeyItem? nextApiKey() {
    final pool = usableApiKeys;
    if (pool.isEmpty) return null;

    // A key promoted by a previous rate-limit rotation keeps serving requests
    // until it is throttled itself.
    if (_preferredKeyId != null) {
      final preferred = pool.where((key) => key.id == _preferredKeyId);
      if (preferred.isNotEmpty) return preferred.first;
    }

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

  /// Marks [keyId] as throttled and promotes the next usable key to serve
  /// subsequent requests.
  ///
  /// Returns the newly promoted key's raw token, or `null` when the pool has no
  /// other usable key left. The throttled key becomes available again after
  /// [cooldown] expires, so a long job can keep going once the RPM window rolls
  /// over.
  String? rotateKey(String keyId, {Duration cooldown = _keyCooldown}) {
    // The cooldown is tracked purely in memory. Persisting a 'Cooldown' status
    // would permanently disable the key, because `usableApiKeys` has no way to
    // tell that the window has rolled over after an app restart.
    _keyCooldownUntil[keyId] = DateTime.now().add(cooldown);

    // The outgoing key is no longer the default.
    if (_preferredKeyId == keyId) _preferredKeyId = null;

    final next = usableApiKeys
        .where((key) => key.id != keyId)
        .fold<ApiKeyItem?>(null, (best, key) {
      if (best == null) return key;
      // Prefer the least-used key so the pool spreads load.
      return key.rpmUsage < best.rpmUsage ? key : best;
    });

    if (next == null) return null;

    _preferredKeyId = next.id;
    // A promoted key must not be left sidelined from an earlier rotation.
    _keyCooldownUntil.remove(next.id);
    notifyListeners();
    return next.token;
  }

  /// Id of the key currently preferred after a rate-limit rotation.
  String? get preferredKeyId => _preferredKeyId;

  /// Key ids that are still inside their cooldown window.
  List<String> get coolingDownKeyIds => _keyCooldownUntil.entries
      .where((entry) => entry.value.isAfter(DateTime.now()))
      .map((entry) => entry.key)
      .toList(growable: false);

  /// Replaces [original] with an updated copy, optionally changing [status].
  void _replaceKey(ApiKeyItem original, {String? status}) {
    final index = _apiKeys.indexWhere((item) => item.id == original.id);
    if (index == -1) return;

    _apiKeys[index] = ApiKeyItem(
      id: original.id,
      alias: original.alias,
      maskedToken: original.maskedToken,
      token: original.token,
      model: original.model,
      status: status ?? original.status,
      rpmUsage: original.rpmUsage,
      rpmMax: original.rpmMax,
      latencyMs: original.latencyMs,
    );
    _saveApiKeysToStorage();
  }

  /// Returns the persisted status to 'Active'.
  ///
  /// Cooldowns are deliberately session-scoped (see [rotateKey]), so a key that
  /// was parked before the app was killed must become usable again on restart
  /// rather than staying dead forever.
  void reviveParkedKeys() {
    final parked = _apiKeys.where((key) => key.status == 'Cooldown');
    if (parked.isEmpty) return;
    for (final key in parked.toList()) {
      _replaceKey(key, status: 'Active');
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
