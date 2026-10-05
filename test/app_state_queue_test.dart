import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_dubber_mobile/models/dub_models.dart';
import 'package:khmer_dubber_mobile/screens/completed_player_screen.dart';
import 'package:khmer_dubber_mobile/services/app_state.dart';
import 'package:khmer_dubber_mobile/services/license/license_status.dart';
import 'package:khmer_dubber_mobile/services/dubbing/dubbing_pipeline.dart';
import 'package:khmer_dubber_mobile/services/dubbing/ffmpeg_dubbing_service.dart';
import 'package:khmer_dubber_mobile/services/dubbing/gemini_translation_service.dart';
import 'package:khmer_dubber_mobile/services/dubbing/tts_segment_service.dart';
import 'package:khmer_dubber_mobile/services/dubbing/workspace_cleanup_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for the real pipeline so queue mechanics can be tested without
/// FFmpeg, Gemini or Edge TTS.
class FakePipeline extends DubbingPipeline {
  FakePipeline(this.steps);

  /// Stage indices reported before completing, in order.
  final List<int> steps;

  Completer<void>? gate;
  bool wasCancelled = false;

  @override
  Future<DubbingResult> run({
    required String videoPath,
    required String workDir,
    required VoiceProfile voice,
    required String apiKey,
    required String modelDisplayName,
    double pitchHz = 0.0,
    double speedMultiplier = 1.0,
    double duckingPercent = -25.0,
    int startStage = 0,
    String? Function()? onRateLimited,
    void Function(DubbingProgress progress)? onProgress,
  }) async {
    for (final stage in steps) {
      onProgress?.call(DubbingProgress(
        stageIndex: stage,
        fraction: (stage + 1) / 4,
        message: 'stage $stage',
      ));
    }

    // Let the test observe the running state before the job finishes.
    await (gate?.future ?? Future<void>.value());

    if (wasCancelled) throw const FfmpegCancelledException();

    return DubbingResult(
      outputVideoPath: '$workDir/out.mp4',
      srtContent: '1\n00:00:00,000 --> 00:00:01,000\n[M] ស្វា',
      entries: const [],
    );
  }

  @override
  Future<void> cancel() async {
    wasCancelled = true;
    if (gate != null && !gate!.isCompleted) gate!.complete();
  }
}

/// A pipeline that walks the stages it is given, then fails on [failAtStage]
/// with a [DubbingStageException] — mirroring a real service blowing up
/// mid-pipeline.
class FailingPipeline extends DubbingPipeline {
  FailingPipeline(this.failAtStage, this.error);

  /// Zero-based index of the stage that should throw.
  final int failAtStage;
  final Object error;

  Completer<void>? gate;

  @override
  Future<DubbingResult> run({
    required String videoPath,
    required String workDir,
    required VoiceProfile voice,
    required String apiKey,
    required String modelDisplayName,
    double pitchHz = 0.0,
    double speedMultiplier = 1.0,
    double duckingPercent = -25.0,
    int startStage = 0,
    String? Function()? onRateLimited,
    void Function(DubbingProgress progress)? onProgress,
  }) async {
    // Report progress for every stage up to and including the failing one.
    for (var stage = 0; stage <= failAtStage; stage++) {
      onProgress?.call(DubbingProgress(
        stageIndex: stage,
        fraction: 0.2 * stage,
        message: 'stage $stage',
      ));
    }

    await (gate?.future ?? Future<void>.value());

    throw DubbingStageException(
      stageIndex: failAtStage,
      cause: error,
      stackTrace: StackTrace.current,
    );
  }

  @override
  Future<void> cancel() async {
    if (gate != null && !gate!.isCompleted) gate!.complete();
  }
}

/// Arguments handed to a [_CallbackPipeline] body.
class FakeRun {
  final int startStage;
  final String apiKey;
  final String? Function()? onRateLimited;
  final void Function(DubbingProgress progress)? onProgress;

  const FakeRun({
    required this.startStage,
    required this.apiKey,
    required this.onRateLimited,
    required this.onProgress,
  });
}

/// A pipeline whose behaviour is decided entirely by the test closure.
///
/// Returning `null` completes the run; throwing fails it. This keeps
/// per-attempt state (counters, recorded args) in the test rather than on the
/// fake, which matters because `AppState` builds a *new* pipeline per attempt.
class _CallbackPipeline extends DubbingPipeline {
  _CallbackPipeline(this.body);

  /// Receives the run arguments and returns an error to throw, or `null`.
  final Object? Function(FakeRun run) body;

  String? workDir = '';

  @override
  Future<DubbingResult> run({
    required String videoPath,
    required String workDir,
    required VoiceProfile voice,
    required String apiKey,
    required String modelDisplayName,
    double pitchHz = 0.0,
    double speedMultiplier = 1.0,
    double duckingPercent = -25.0,
    int startStage = 0,
    String? Function()? onRateLimited,
    void Function(DubbingProgress progress)? onProgress,
  }) async {
    this.workDir = workDir;

    final error = body(FakeRun(
      startStage: startStage,
      apiKey: apiKey,
      onRateLimited: onRateLimited,
      onProgress: onProgress,
    ));
    if (error != null) throw error;

    return DubbingResult(
      outputVideoPath: '$workDir/out.mp4',
      srtContent: '',
      entries: const [],
    );
  }
}

/// A pipeline that records whether it was ever asked to run, used to prove the
/// license guard stops a job before any pipeline work begins.
class RecordingPipeline extends DubbingPipeline {
  RecordingPipeline(this.created);

  final List<RecordingPipeline> created;
  Completer<void>? gate;

  @override
  Future<DubbingResult> run({
    required String videoPath,
    required String workDir,
    required VoiceProfile voice,
    required String apiKey,
    required String modelDisplayName,
    double pitchHz = 0.0,
    double speedMultiplier = 1.0,
    double duckingPercent = -25.0,
    int startStage = 0,
    String? Function()? onRateLimited,
    void Function(DubbingProgress progress)? onProgress,
  }) async {
    created.add(this);
    await (gate?.future ?? Future<void>.value());
    return DubbingResult(
      outputVideoPath: '$workDir/out.mp4',
      srtContent: '',
      entries: const [],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('dubbing_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// Builds an AppState with a valid license in place.
  ///
  /// The dubbing pipeline refuses to start while the app is license-locked, so
  /// queue mechanics are exercised against a licensed state. License behaviour
  /// itself is covered in license_service_test.dart.
  AppState licensedState() {
    final state = AppState();
    state.setLicenseStatus(LicenseStatus.valid);
    return state;
  }

  /// Builds an AppState wired to fake pipelines with a temp work dir and a saved
  /// Gemini key, so jobs actually run.
  ///
  /// Every job gets its own [FakePipeline] (recorded in [created]) so a
  /// cancelled pipeline is never reused by the next job.
  AppState buildState(
    List<FakePipeline> created, {
    List<int> steps = const [0],
    Completer<void>? gate,
  }) {
    final state = licensedState();
    state.addApiKey('Test Key', 'fake-token-123');
    state.workDirOverride = tempDir.path;
    state.pipelineFactory = () {
      final pipeline = FakePipeline(steps)..gate = gate;
      created.add(pipeline);
      return pipeline;
    };
    return state;
  }

  /// Enqueues a job pointing at a file inside [tempDir].
  void enqueue(AppState state, String name) {
    state.startNewDubbingJob(
      videoTitle: '$name.mp4',
      duration: '01:00',
      fileSpecs: '1.0 MB • MP4',
      videoPath: '${tempDir.path}/$name.mp4',
    );
  }

  group('license gate', () {
    testWidgets('a locked app refuses to start a dubbing job',
        (tester) async {
      final state = AppState();
      state.addApiKey('Test Key', 'fake-token-123');
      state.workDirOverride = tempDir.path;
      final created = <RecordingPipeline>[];
      state.pipelineFactory = () => RecordingPipeline(created);

      state.setLicenseStatus(
        LicenseStatus.locked,
        reason: 'Your license is no longer valid.',
      );
      await tester.pump();

      enqueue(state, 'blocked');

      // No task is created, nothing is queued and the pipeline never runs.
      expect(state.queuedTasks, isEmpty);
      expect(state.activeTask, isNull);
      expect(created, isEmpty);
      expect(state.completedTasks, isEmpty);

      state.dispose();
    });

    testWidgets('an unknown license status also blocks the pipeline',
        (tester) async {
      final state = AppState();
      state.workDirOverride = tempDir.path;
      final created = <RecordingPipeline>[];
      state.pipelineFactory = () => RecordingPipeline(created);

      // `unknown` is the cold-start state, before secure storage is read.
      expect(state.licenseStatus, LicenseStatus.unknown);
      expect(state.isLicenseBlocked, isTrue);

      state.startNewDubbingJob(
        videoTitle: 'early.mp4',
        duration: '01:00',
        fileSpecs: '1.0 MB • MP4',
        videoPath: '${tempDir.path}/early.mp4',
      );
      await tester.pump();

      expect(created, isEmpty);
      expect(state.activeTask, isNull);

      state.dispose();
    });

    testWidgets('a valid license lets the job run and retry is allowed',
        (tester) async {
      final created = <RecordingPipeline>[];
      final state = licensedState();
      state.addApiKey('Test Key', 'fake-token-123');
      state.workDirOverride = tempDir.path;
      state.pipelineFactory = () => RecordingPipeline(created);

      expect(state.isLicenseBlocked, isFalse);

      enqueue(state, 'allowed');
      await tester.pumpAndSettle();

      expect(created, isNotEmpty);
      expect(state.completedTasks, isNotEmpty);

      state.dispose();
    });

    testWidgets('locking mid-session stops further jobs from starting',
        (tester) async {
      final state = licensedState();
      state.addApiKey('Test Key', 'fake-token-123');
      state.workDirOverride = tempDir.path;
      final created = <RecordingPipeline>[];
      state.pipelineFactory = () => RecordingPipeline(created);

      // e.g. the once-a-day background check revoked the key.
      state.setLicenseStatus(LicenseStatus.locked, reason: 'Revoked.');
      await tester.pump();

      enqueue(state, 'after-lock');
      await tester.pumpAndSettle();

      expect(created, isEmpty);
      expect(state.completedTasks, isEmpty);

      state.dispose();
    });
  });

  testWidgets('pipeline starts idle with no dummy data', (tester) async {
    final state = licensedState();
    await tester.pump();

    expect(state.activeTask, isNull);
    expect(state.queuedTasks, isEmpty);
    expect(state.completedTasks, isEmpty);
    expect(state.isPipelineBusy, isFalse);

    state.dispose();
  });

  testWidgets('a job with a real file runs the pipeline and completes',
      (tester) async {
    final created = <FakePipeline>[];
    final state = buildState(created, steps: [0, 1, 2, 3]);
    await tester.pump();

    enqueue(state, 'alpha');
    await tester.pumpAndSettle();

    expect(state.activeTask, isNull);
    expect(state.completedTasks.length, 1);
    expect(state.completedTasks.first.videoTitle, 'alpha.mp4');
    expect(state.completedTasks.first.isCompleted, isTrue);
    expect(state.completedTasks.first.progress, 1.0);
    expect(state.completedTasks.first.outputPath, endsWith('out.mp4'));
    expect(state.currentTabIndex, 1, reason: 'navigates to Queue tab');

    state.dispose();
  });

  testWidgets('progress drives the stage tiles and the live console log',
      (tester) async {
    final gate = Completer<void>();
    final created = <FakePipeline>[];
    final state = buildState(created, steps: [0, 1, 2, 3], gate: gate);
    await tester.pump();

    enqueue(state, 'alpha');
    await tester.pump();

    final task = state.activeTask!;
    expect(task.isProcessing, isTrue);
    expect(task.progress, 1.0);
    expect(task.liveStatusLog, 'stage 3');
    expect(task.stages[3].status, StageStatus.inProgress);
    expect(task.stages[2].status, StageStatus.completed);
    expect(task.stages.first.status, StageStatus.completed);

    gate.complete();
    await tester.pumpAndSettle();

    expect(state.completedTasks.length, 1);
    state.dispose();
  });
  testWidgets('first job runs immediately, later jobs queue at the bottom',
      (tester) async {
    final gate = Completer<void>();
    final created = <FakePipeline>[];
    final state = buildState(created, gate: gate);
    await tester.pump();

    enqueue(state, 'alpha');
    await tester.pump();

    expect(state.activeTask, isNotNull);
    expect(state.activeTask!.videoTitle, 'alpha.mp4');
    expect(state.activeTask!.isProcessing, isTrue);
    expect(state.queuedTasks, isEmpty);
    expect(state.currentTabIndex, 1, reason: 'navigates to Queue tab');

    enqueue(state, 'beta');
    await tester.pump();

    expect(state.activeTask!.videoTitle, 'alpha.mp4');
    expect(state.queuedTasks.length, 1);
    expect(state.queuedTasks.first.videoTitle, 'beta.mp4');
    expect(state.queuedTasks.first.isQueued, isTrue);
    expect(state.queuedTasks.first.isProcessing, isFalse);
    // The queued job keeps its source path for when it is promoted.
    expect(state.queuedTasks.first.videoPath, endsWith('beta.mp4'));

    gate.complete();
    await tester.pumpAndSettle();
    state.dispose();
  });

  testWidgets('finishing a job promotes the next queued job (FIFO)',
      (tester) async {
    final gate = Completer<void>();
    final created = <FakePipeline>[];
    final state = buildState(created, gate: gate);
    await tester.pump();

    enqueue(state, 'first');
    enqueue(state, 'second');
    enqueue(state, 'third');
    await tester.pump();
    expect(state.queuedTasks.length, 2);
    expect(state.activeTask!.videoTitle, 'first.mp4');

    // Releasing the gate lets every job run to completion in turn.
    gate.complete();
    await tester.pumpAndSettle();

    // `completedTasks` is newest-first, so this is the reverse of the run order.
    expect(
      state.completedTasks.map((t) => t.videoTitle),
      ['third.mp4', 'second.mp4', 'first.mp4'],
      reason: 'jobs render in FIFO order',
    );
    expect(state.completedTasks.every((t) => t.isCompleted), isTrue);
    expect(state.queuedTasks, isEmpty);
    expect(state.activeTask, isNull, reason: 'queue drained, pipeline idle');
    expect(state.isPipelineBusy, isFalse);

    state.dispose();
  });

  testWidgets('terminate cancels the active job and promotes the next one',
      (tester) async {
    final gate = Completer<void>();
    final created = <FakePipeline>[];
    final state = buildState(created, gate: gate);
    await tester.pump();

    enqueue(state, 'a');
    enqueue(state, 'b');
    await tester.pump();

    final running = created.first;
    await state.terminateActiveProcess();
    // The next job gets a fresh pipeline and runs to completion.
    if (!gate.isCompleted) gate.complete();
    await tester.pumpAndSettle();

    expect(running.wasCancelled, isTrue, reason: 'FFmpeg session cancelled');
    // The cancelled job is not recorded as a completed render.
    expect(
      state.completedTasks.where((t) => t.videoTitle == 'a.mp4'),
      isEmpty,
    );
    // The queued job was promoted and rendered instead.
    expect(
      state.completedTasks.map((t) => t.videoTitle),
      contains('b.mp4'),
    );
    expect(state.isPipelineBusy, isFalse);
    expect(state.activeTask, isNull);
    expect(state.queuedTasks, isEmpty);

    state.dispose();
  });
  testWidgets('a job without a source file fails fast and never blocks',
      (tester) async {
    final created = <FakePipeline>[];
    final state = buildState(created);
    await tester.pump();

    state.startNewDubbingJob(
      videoTitle: 'ghost.mp4',
      duration: '01:00',
      fileSpecs: '1.0 MB • MP4',
      // No videoPath supplied.
    );
    await tester.pumpAndSettle();

    expect(state.activeTask, isNull);
    // A crashed render must NOT be reported as a completed one.
    expect(state.completedTasks, isEmpty);
    expect(state.failedTasks.length, 1);
    expect(state.failedTasks.first.liveStatusLog, contains('Stopped at'));
    expect(state.failedTasks.first.hasFailed, isTrue);
    expect(state.failedTasks.first.isCompleted, isFalse);
    expect(state.isPipelineBusy, isFalse);

    state.dispose();
  });

  testWidgets('a job without a Gemini key fails fast and never blocks',
      (tester) async {
    // No API key saved on purpose.
    final state = licensedState();
    state.workDirOverride = tempDir.path;
    state.pipelineFactory = () => FakePipeline([0]);
    await tester.pump();

    enqueue(state, 'alpha');
    await tester.pumpAndSettle();

    expect(state.activeTask, isNull);
    expect(state.completedTasks, isEmpty);
    expect(state.failedTasks.length, 1);
    expect(
      state.failedTasks.first.error!.message,
      contains('Gemini API key'),
    );
    expect(state.isPipelineBusy, isFalse);

    state.dispose();
  });

  testWidgets('removeQueuedTask drops only the target job', (tester) async {
    final gate = Completer<void>();
    final created = <FakePipeline>[];
    final state = buildState(created, gate: gate);
    await tester.pump();

    enqueue(state, 'running');
    enqueue(state, 'queued-1');
    enqueue(state, 'queued-2');
    await tester.pump();

    expect(state.queuedTasks.length, 2);
    final target = state.queuedTasks.first;

    expect(state.removeQueuedTask(target.id), isTrue);

    // Only the targeted job is gone; the active render is untouched.
    expect(state.queuedTasks.length, 1);
    expect(state.queuedTasks.first.videoTitle, 'queued-2.mp4');
    expect(state.activeTask!.videoTitle, 'running.mp4');
    expect(state.activeTask!.isProcessing, isTrue);

    gate.complete();
    await tester.pumpAndSettle();
    state.dispose();
  });

  testWidgets('removeQueuedTask renumbers the remaining queue positions',
      (tester) async {
    final gate = Completer<void>();
    final created = <FakePipeline>[];
    final state = buildState(created, gate: gate);
    await tester.pump();

    for (final name in ['running', 'q1', 'q2', 'q3']) {
      enqueue(state, name);
    }
    await tester.pump();

    expect(state.queuedTasks[0].liveStatusLog, contains('#1'));
    expect(state.queuedTasks[2].liveStatusLog, contains('#3'));

    // Removing the head promotes q2 to position #1.
    state.removeQueuedTask(state.queuedTasks.first.id);

    expect(state.queuedTasks.first.videoTitle, 'q2.mp4');
    expect(state.queuedTasks.first.liveStatusLog, contains('#1'));
    expect(state.queuedTasks.last.videoTitle, 'q3.mp4');
    expect(state.queuedTasks.last.liveStatusLog, contains('#2'));

    gate.complete();
    await tester.pumpAndSettle();
    state.dispose();
  });

  testWidgets('removeQueuedTask returns false for unknown or active jobs',
      (tester) async {
    final gate = Completer<void>();
    final created = <FakePipeline>[];
    final state = buildState(created, gate: gate);
    await tester.pump();

    enqueue(state, 'running');
    await tester.pump();
    final activeId = state.activeTask!.id;

    expect(state.removeQueuedTask('does-not-exist'), isFalse);
    expect(state.removeQueuedTask(activeId), isFalse);
    expect(state.activeTask!.videoTitle, 'running.mp4');
    expect(state.activeTask!.isProcessing, isTrue);

    gate.complete();
    await tester.pumpAndSettle();
    state.dispose();
  });

  testWidgets('a removed job never renders, even after the active one ends',
      (tester) async {
    final gate = Completer<void>();
    final created = <FakePipeline>[];
    final state = buildState(created, gate: gate);
    await tester.pump();

    for (final name in ['running', 'keep', 'drop']) {
      enqueue(state, name);
    }
    await tester.pump();

    final dropped =
        state.queuedTasks.firstWhere((task) => task.videoTitle == 'drop.mp4');
    expect(state.removeQueuedTask(dropped.id), isTrue);

    gate.complete();
    await tester.pumpAndSettle();

    final rendered = state.completedTasks.map((task) => task.videoTitle);
    expect(rendered, isNot(contains('drop.mp4')));
    expect(rendered, containsAll(<String>['running.mp4', 'keep.mp4']));

    state.dispose();
  });
  group('API key pool', () {
    test('stores the raw token so the pipeline can call Gemini', () {
      final state = licensedState();
      state.addApiKey('Key A', 'AIzaSyREAL-TOKEN-1234');

      expect(state.apiKeys.single.maskedToken, contains('•••••'));
      expect(state.apiKeys.single.token, 'AIzaSyREAL-TOKEN-1234');
      state.dispose();
    });

    test('generated key ids stay unique even in the same millisecond', () {
      final state = licensedState();
      for (var i = 0; i < 50; i++) {
        state.addApiKey('Key $i', 'token-$i');
      }

      final ids = state.apiKeys.map((k) => k.id).toSet();
      expect(ids.length, 50, reason: 'no duplicate key ids');
      state.dispose();
    });

    test('nextApiKey honours the rotation strategy', () {
      final state = licensedState();
      state.addApiKey('A', 'token-a');
      state.addApiKey('B', 'token-b');
      state.addApiKey('C', 'token-c');

      // Round-Robin cycles deterministically.
      state.setKeyRotationStrategy('Round-Robin');
      final seen = [
        state.nextApiKey()!.id,
        state.nextApiKey()!.id,
        state.nextApiKey()!.id,
      ];
      expect(seen.toSet().length, 3, reason: 'each key is served once');

      // Rate-Limit Balanced picks the least-used key.
      state.setKeyRotationStrategy('Rate-Limit Balanced');
      expect(state.nextApiKey()!.alias, 'A');

      state.dispose();
    });

    test('recordKeyUsage bumps the RPM counter', () {
      final state = licensedState();
      state.addApiKey('A', 'token-a');
      final id = state.apiKeys.single.id;

      expect(state.apiKeys.single.rpmUsage, 0);
      state.recordKeyUsage(id);
      expect(state.apiKeys.single.rpmUsage, 1);
      state.recordKeyUsage(id);
      expect(state.apiKeys.single.rpmUsage, 2);

      state.dispose();
    });

    test('usableApiKeys excludes keys saved without a raw token', () {
      final state = licensedState();
      state.addApiKey('Good', 'token-good');

      // Simulate a legacy record persisted before raw tokens were stored.
      state.previewLegacyKeyWithoutToken();

      expect(state.apiKeys.length, 2);
      expect(state.usableApiKeys.length, 1);
      expect(state.usableApiKeys.single.alias, 'Good');

      state.dispose();
    });
  });
group('Player screen selection', () {
    test('playerTask is null before anything has rendered', () {
      final state = licensedState();
      state.addApiKey('K', 'token');
      expect(state.playerTask, isNull, reason: 'nothing rendered yet');

      state.dispose();
    });

    testWidgets('openTaskInPlayer selects the job and jumps to the Player tab',
        (tester) async {
      final created = <FakePipeline>[];
      final state = buildState(created, steps: [0, 1, 2, 3]);
      await tester.pump();

      enqueue(state, 'alpha');
      enqueue(state, 'beta');
      await tester.pumpAndSettle();

      expect(state.completedTasks.length, 2);

      // Open the OLDER render explicitly; it must win over the "latest" fallback.
      final older = state.completedTasks
          .firstWhere((task) => task.videoTitle == 'alpha.mp4');
      state.openTaskInPlayer(older);

      expect(state.playerTask!.id, older.id,
          reason: 'plays the specific job the user tapped');
      expect(state.playerTask!.videoTitle, 'alpha.mp4');
      expect(state.currentTabIndex, 2, reason: 'jumps to the Player tab');
      expect(state.isPlayingVideo, isFalse, reason: 'starts paused');

      state.dispose();
    });

    testWidgets('playerTask defaults to the most recent render when unset',
        (tester) async {
      final created = <FakePipeline>[];
      final state = buildState(created, steps: [0, 1, 2, 3]);
      await tester.pump();

      enqueue(state, 'alpha');
      enqueue(state, 'beta');
      await tester.pumpAndSettle();

      // completedTasks is newest-first, so the fallback is 'beta.mp4'.
      expect(state.playerTask!.videoTitle, 'beta.mp4');

      state.dispose();
    });

    testWidgets('saveToGallery fails loudly when there is nothing to save',
        (tester) async {
      final state = licensedState();
      state.addApiKey('K', 'token');
      await tester.pump();

      await state.saveToGallery();

      expect(state.saveGalleryState, 'error');
      expect(state.saveGalleryError, contains('No rendered video'));

      state.dispose();
    });

    testWidgets(
        'saveToGallery reports a missing output file instead of pretending to save',
        (tester) async {
      final created = <FakePipeline>[];
      final state = buildState(created, steps: [0, 1, 2, 3]);
      await tester.pump();

      enqueue(state, 'alpha');
      await tester.pumpAndSettle();

      final done = state.completedTasks.single;
      // The fake pipeline reports $workDir/out.mp4, which was never written.
      expect(File(done.outputPath!).existsSync(), isFalse);

      await state.saveToGallery();

      expect(state.saveGalleryState, 'error',
          reason: 'must not claim success for a file that does not exist');
      expect(state.saveGalleryError, contains('no longer exists'));

      state.dispose();
    });

    testWidgets(
        'the Save to Gallery button stays on screen after being tapped',
        (tester) async {
      final created = <FakePipeline>[];
      final state = buildState(created, steps: [0, 1, 2, 3]);
      await tester.pump();

      enqueue(state, 'alpha');
      await tester.pumpAndSettle();
      state.openTaskInPlayer(state.completedTasks.single);

      await tester.pumpWidget(
        MaterialApp(home: CompletedPlayerScreen(state: state)),
      );
      await tester.pumpAndSettle();

      final saveButton = find.text('Save to Gallery');
      expect(saveButton, findsOneWidget);

      // The button sits below the video card, so scroll it into view first.
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();

      // Tap it. The underlying file does not exist, so this exercises the
      // failure path — the button must still be there afterwards.
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Save to Gallery'), findsOneWidget,
          reason: 'the control must never be removed once it has been used');
      expect(state.saveGalleryState, 'error');
      // The raw reason is surfaced rather than a false success.
      expect(find.textContaining('no longer exists'), findsOneWidget);

      state.dispose();
    });
  });

    group('Gemini key rotation on rate limit', () {
    test('rotateKey sidelines the throttled key and promotes another', () {
      final state = licensedState();
      state.addApiKey('A', 'token-a');
      state.addApiKey('B', 'token-b');
      state.addApiKey('C', 'token-c');

      // Failover Priority makes the pick deterministic for this assertion.
      state.setKeyRotationStrategy('Failover Priority');
      final current = state.nextApiKey()!;

      final promoted = state.rotateKey(current.id);
      expect(promoted, isNotNull, reason: 'a spare key must be handed back');
      expect(promoted, isNot(current.token));

      // The throttled key is no longer usable...
      expect(
        state.usableApiKeys.where((k) => k.id == current.id),
        isEmpty,
        reason: 'rate-limited key is parked',
      );
      // ...and the promoted key is now the default for future jobs.
      expect(state.preferredKeyId, isNotNull);
      expect(state.nextApiKey()!.id, state.preferredKeyId);

      state.dispose();
    });

    test('rotateKey returns null when no other key is available', () {
      final state = licensedState();
      state.addApiKey('Solo', 'token-solo');

      final only = state.nextApiKey()!;
      expect(state.rotateKey(only.id), isNull,
          reason: 'pool exhausted must not loop on the same key');
      expect(state.usableApiKeys, isEmpty);

      state.dispose();
    });

    test('a throttled key becomes usable again after its cooldown', () async {
      final state = licensedState();
      state.addApiKey('A', 'token-a');
      state.addApiKey('B', 'token-b');

      final a = state.nextApiKey()!;
      state.rotateKey(a.id, cooldown: const Duration(milliseconds: 40));
      expect(state.usableApiKeys.any((k) => k.id == a.id), isFalse);

      // Cooldowns are wall-clock based, so this needs real time to elapse
      // (a `tester.pump` would only advance the fake timer, not `DateTime`).
      await Future<void>.delayed(const Duration(milliseconds: 90));

      // Cooldown expiry restores the key instead of permanently banning it.
      expect(state.usableApiKeys.any((k) => k.id == a.id), isTrue);
      state.dispose();
    });

    test('the promoted key keeps serving until it is throttled itself', () {
      final state = licensedState();
      state.addApiKey('A', 'token-a');
      state.addApiKey('B', 'token-b');

      final a = state.nextApiKey()!;
      state.rotateKey(a.id);
      final promotedId = state.preferredKeyId!;

      // Repeated calls keep returning the promoted key.
      expect(state.nextApiKey()!.id, promotedId);
      expect(state.nextApiKey()!.id, promotedId);

      state.dispose();
    });
  });

  group('Retry a failed stage', () {
    testWidgets('a retried job resumes at the failing stage index',
        (tester) async {
      // `pipelineFactory` builds a *new* pipeline per attempt, so the attempt
      // counter has to live in the test closure rather than on the fake.
      var attempts = 0;
      final startStages = <int>[];

      final state = licensedState();
      state.addApiKey('Test Key', 'fake-token-123');
      state.workDirOverride = tempDir.path;
      state.pipelineFactory = () => _CallbackPipeline((run) {
            attempts++;
            startStages.add(run.startStage);
            if (attempts == 1) {
              // The real pipeline reports progress per stage, which is what
              // lets an unattributed error be pinned to the right step.
              run.onProgress?.call(const DubbingProgress(
                stageIndex: 1,
                fraction: 0.2,
                message: 'Transcribing and translating',
              ));
              return const GeminiTranslationException('boom');
            }
            return null;
          });
      await tester.pump();

      enqueue(state, 'alpha');
      await tester.pumpAndSettle();
      expect(state.failedTasks.length, 1);
      expect(state.failedTasks.single.failedStageIndex, 1);
      expect(startStages.single, 0,
          reason: 'first attempt starts from the top');

      final retried = state.retryFailedStage(state.failedTasks.single.id);
      expect(retried, isTrue);
      expect(state.failedTasks, isEmpty, reason: 'left the failed list');

      await tester.pumpAndSettle();

      expect(startStages, hasLength(2));
      expect(startStages.last, 1,
          reason: 'resumes at the stage that failed, not from stage 1');
      expect(state.completedTasks.length, 1,
          reason: 'a successful retry lands in completed');

      state.dispose();
    });

    test('retryFailedStage and removeFailedTask ignore unknown ids', () {
      final state = licensedState();
      expect(state.retryFailedStage('nope'), isFalse);
      expect(state.removeFailedTask('nope'), isFalse);
      state.dispose();
    });

    testWidgets('removeFailedTask drops only the target job',
        (tester) async {
      final state = licensedState();
      state.addApiKey('Test Key', 'fake-token-123');
      state.workDirOverride = tempDir.path;
      var calls = 0;
      state.pipelineFactory = () {
        calls++;
        // Fail both jobs, at different stages.
        return FailingPipeline(calls == 1 ? 1 : 3, Exception('boom'));
      };
      await tester.pump();

      enqueue(state, 'first');
      enqueue(state, 'second');
      await tester.pumpAndSettle();
      expect(state.failedTasks.length, 2);

      final target = state.failedTasks
          .firstWhere((t) => t.videoTitle == 'first.mp4');

      expect(state.removeFailedTask(target.id), isTrue);
      expect(state.failedTasks.length, 1);
      expect(state.failedTasks.single.videoTitle, 'second.mp4');

      state.dispose();
    });
  });

  group('Retry policies', () {
    test('Gemini allows exactly 3 retries after the first attempt', () {
      expect(maxGeminiAttempts - 1, 3,
          reason: 'the brief asks for 3 retries on a 503');
      expect(
        geminiRetryDelays,
        hasLength(maxGeminiAttempts - 1),
        reason: 'one back-off slot per retry, none left unused',
      );
    });

    test('TTS allows 5 retries starting at 1 second', () {
      // The brief: wait 1s, retry; wait 2s, retry; up to 5 retries per entry.
      expect(ttsRetryDelays, hasLength(5));
      expect(ttsRetryDelays.first, const Duration(seconds: 1));
      expect(ttsRetryDelays[1], const Duration(seconds: 2));
      expect(maxTtsAttempts, ttsRetryDelays.length + 1);
    });

    test('Gemini errors are classified by cause', () {
      // 429 / RESOURCE_EXHAUSTED needs a *different* key, not a retry.
      expect(
        classifyGeminiError(ServerException('429 RESOURCE_EXHAUSTED: quota')),
        GeminiFailureKind.rateLimited,
      );
      expect(
        classifyGeminiError(ServerException('Quota exceeded for quota metric')),
        GeminiFailureKind.rateLimited,
      );

      // 5xx blips are worth retrying on the same key.
      expect(
        classifyGeminiError(
          GenerativeAIException('Server Error [503]: backend down'),
        ),
        GeminiFailureKind.transientServer,
      );
      expect(
        classifyGeminiError(InvalidApiKey('API key not valid')),
        GeminiFailureKind.invalidKey,
      );

      // A blocked region can never be fixed by retrying.
      expect(
        classifyGeminiError(UnsupportedUserLocation()),
        GeminiFailureKind.fatal,
      );
      expect(
        classifyGeminiError(
          GenerativeAISdkException('Unhandled response format'),
        ),
        GeminiFailureKind.fatal,
      );
    });

    test('only retryable Gemini failures are marked retryable', () {
      expect(
        const GeminiTranslationException('x', kind: GeminiFailureKind.rateLimited)
            .isRetryable,
        isTrue,
      );
      expect(
        const GeminiTranslationException(
          'x',
          kind: GeminiFailureKind.transientServer,
        ).isRetryable,
        isTrue,
      );
      expect(
        const GeminiTranslationException('x', kind: GeminiFailureKind.fatal)
            .isRetryable,
        isFalse,
      );
    });

    test('a TTS failure names the cue, voice and attempt count', () {
      const error = TtsEntryException(
        cueIndex: 12,
        text: 'សូមស្វាគមន៍',
        voiceId: 'km-KH-PisethNeural',
        attempts: 6,
        cause: 'socket closed',
      );

      expect(error.summary, contains('line 12'));
      expect(error.details, contains('km-KH-PisethNeural'));
      expect(error.details, contains('socket closed'));
      expect(error.details, contains('Attempts:  6'));
    });
  });

  group('Workspace cleanup on app reopen', () {
    test('removes stale artifacts but keeps the work dir', () async {
      final docs = Directory.systemTemp.createTempSync('cleanup_docs');
      addTearDown(() {
        if (docs.existsSync()) docs.deleteSync(recursive: true);
      });

      final workDir = Directory('${docs.path}/dubbing_jobs')..createSync();

      // Simulate leftovers from a previous session.
      final wav = File('${workDir.path}/clip.audio.wav')
        ..writeAsBytesSync(List.filled(64, 1));
      final srt = File('${workDir.path}/clip.khmer.srt')
        ..writeAsStringSync('1\n');
      final mp4 = File('${workDir.path}/clip_dubbed.mp4')
        ..writeAsBytesSync(List.filled(32, 1));
      final segments = Directory('${workDir.path}/clip_segments')..createSync();
      File('${segments.path}/line_1.mp3').writeAsBytesSync(List.filled(16, 1));
      final cache = File('${docs.path}/tts_cache_km-KH-PisethNeural.mp3')
        ..writeAsBytesSync(List.filled(8, 1));
      final keep = File('${docs.path}/unrelated.dat')..writeAsStringSync('keep');

      final report = await WorkspaceCleanupService.cleanPreviousRun(
        workDirOverride: docs.path,
      );

      expect(wav.existsSync(), isFalse);
      expect(srt.existsSync(), isFalse);
      expect(mp4.existsSync(), isFalse);
      expect(segments.existsSync(), isFalse);
      expect(cache.existsSync(), isFalse);

      // The work dir itself survives so the next job can write straight away.
      expect(workDir.existsSync(), isTrue);
      // Files outside the managed folders are never touched.
      expect(keep.existsSync(), isTrue);
      expect(report.freedBytes, greaterThan(0));
      expect(report.warnings, isEmpty);
    });

    test('a missing work dir is not an error', () async {
      final docs = Directory.systemTemp.createTempSync('cleanup_empty');
      addTearDown(() => docs.deleteSync(recursive: true));

      final report = await WorkspaceCleanupService.cleanPreviousRun(
        workDirOverride: docs.path,
      );

      expect(report.removedPaths, isEmpty);
      expect(report.warnings, isEmpty);
    });

    test('reclaims the bytes of every deleted file', () async {
      final docs = Directory.systemTemp.createTempSync('cleanup_bytes');
      addTearDown(() => docs.deleteSync(recursive: true));

      final workDir = Directory('${docs.path}/dubbing_jobs')..createSync();
      File('${workDir.path}/a.wav').writeAsBytesSync(List.filled(100, 0));
      File('${workDir.path}/b.srt').writeAsBytesSync(List.filled(50, 0));

      final report = await WorkspaceCleanupService.cleanPreviousRun(
        workDirOverride: docs.path,
      );

      expect(report.removedPaths.length, 2);
      expect(report.freedBytes, 150);
    });
  });

  group('Pipeline stage error tracking', () {
    /// Builds a state whose pipeline fails on [failAtStage].
    AppState buildFailingState(int failAtStage, Object error) {
      final state = licensedState();
      state.addApiKey('Test Key', 'fake-token-123');
      state.workDirOverride = tempDir.path;
      state.pipelineFactory = () => FailingPipeline(failAtStage, error);
      return state;
    }

    testWidgets('a stage failure never appears as a completed render',
        (tester) async {
      final state = buildFailingState(
        1,
        const GeminiTranslationException('API key not valid'),
      );
      await tester.pump();

      enqueue(state, 'alpha');
      await tester.pumpAndSettle();

      expect(state.completedTasks, isEmpty,
          reason: 'a failed job must not be reported as done');
      expect(state.failedTasks.length, 1);
      expect(state.failedTasks.first.videoTitle, 'alpha.mp4');
      expect(state.activeTask, isNull);
      expect(state.isPipelineBusy, isFalse);

      state.dispose();
    });

    testWidgets('the failing stage is marked failed and later stages stay pending',
        (tester) async {
      final state = buildFailingState(
        1,
        const GeminiTranslationException('quota exceeded'),
      );
      await tester.pump();

      enqueue(state, 'alpha');
      await tester.pumpAndSettle();

      final failed = state.failedTasks.first;
      expect(failed.failedStageIndex, 1);

      // Stage 1 completed before the failure.
      expect(failed.stages[0].status, StageStatus.completed);
      // Stage 2 is the one that threw.
      expect(failed.stages[1].status, StageStatus.failed);
      expect(failed.stages[1].badgeText, 'Failed');
      // Nothing after it ran.
      expect(failed.stages[2].status, StageStatus.pending);
      expect(failed.stages[3].status, StageStatus.pending);

      // No stage is left spinning once the pipeline stopped.
      expect(
        failed.stages.where((s) => s.status == StageStatus.inProgress),
        isEmpty,
      );

      state.dispose();
    });

    testWidgets('each stage index maps to the right failing stage',
        (tester) async {
      for (var stage = 0; stage < 4; stage++) {
        final state = buildFailingState(
          stage,
          const GeminiTranslationException('boom'),
        );
        await tester.pump();

        enqueue(state, 'job$stage');
        await tester.pumpAndSettle();

        final failed = state.failedTasks.first;
        expect(failed.failedStageIndex, stage);
        expect(failed.stages[stage].status, StageStatus.failed);

        // Everything before the failure finished successfully.
        for (var i = 0; i < stage; i++) {
          expect(failed.stages[i].status, StageStatus.completed);
        }
        // Everything after it never ran.
        for (var i = stage + 1; i < 4; i++) {
          expect(failed.stages[i].status, StageStatus.pending);
        }

        state.dispose();
      }
    });

    testWidgets('the raw error message is preserved verbatim for copying',
        (tester) async {
      const rawLog =
          'Conversion failed!\nInvalid data found when processing input';
      final state = buildFailingState(
        3,
        const FfmpegException('-i in.mp4 -c:v copy out.mp4', rawLog),
      );
      await tester.pump();

      enqueue(state, 'alpha');
      await tester.pumpAndSettle();

      final error = state.failedTasks.first.error!;
      // The FFmpeg command and the raw log both survive for the technical user.
      expect(error.details, contains('-i in.mp4 -c:v copy out.mp4'));
      expect(error.details, contains('Conversion failed!'));
      expect(error.details, contains('Invalid data found'));
      expect(error.errorType, 'FfmpegException');

      // The copyable report bundles it all together.
      final report = state.failedTasks.first.errorReport;
      expect(report, contains('alpha.mp4'));
      expect(report, contains('4. Build video'));
      expect(report, contains('Raw details'));
      expect(report, contains(rawLog));

      state.dispose();
    });

    testWidgets('a failed job still promotes the next queued job',
        (tester) async {
      final state = licensedState();
      state.addApiKey('Test Key', 'fake-token-123');
      state.workDirOverride = tempDir.path;

      var calls = 0;
      state.pipelineFactory = () {
        calls++;
        // The first job fails; the second runs clean.
        if (calls == 1) {
          return FailingPipeline(2, Exception('tts blew up'));
        }
        return FakePipeline([0, 1, 2, 3]);
      };
      await tester.pump();

      enqueue(state, 'first');
      enqueue(state, 'second');
      await tester.pumpAndSettle();

      expect(state.failedTasks.single.videoTitle, 'first.mp4');
      expect(state.completedTasks.single.videoTitle, 'second.mp4');
      expect(state.queuedTasks, isEmpty);
      expect(state.isPipelineBusy, isFalse);

      state.dispose();
    });

    testWidgets('stage 4 success marks every stage completed', (tester) async {
      final created = <FakePipeline>[];
      final state = buildState(created, steps: [0, 1, 2, 3]);
      await tester.pump();

      enqueue(state, 'alpha');
      await tester.pumpAndSettle();

      final done = state.completedTasks.first;
      expect(done.hasFailed, isFalse);
      expect(done.error, isNull);
      expect(done.errorReport, isEmpty);
      expect(
        done.stages.every((s) => s.status == StageStatus.completed),
        isTrue,
      );

      state.dispose();
    });
  });
}
