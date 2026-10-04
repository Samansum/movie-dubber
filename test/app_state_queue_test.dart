import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_dubber_mobile/models/dub_models.dart';
import 'package:khmer_dubber_mobile/services/app_state.dart';
import 'package:khmer_dubber_mobile/services/dubbing/dubbing_pipeline.dart';
import 'package:khmer_dubber_mobile/services/dubbing/ffmpeg_dubbing_service.dart';
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
    final state = AppState();
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

  testWidgets('pipeline starts idle with no dummy data', (tester) async {
    final state = AppState();
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
    expect(state.completedTasks.length, 1);
    expect(state.completedTasks.first.liveStatusLog, contains('Failed'));
    expect(state.isPipelineBusy, isFalse);

    state.dispose();
  });

  testWidgets('a job without a Gemini key fails fast and never blocks',
      (tester) async {
    // No API key saved on purpose.
    final state = AppState();
    state.workDirOverride = tempDir.path;
    state.pipelineFactory = () => FakePipeline([0]);
    await tester.pump();

    enqueue(state, 'alpha');
    await tester.pumpAndSettle();

    expect(state.activeTask, isNull);
    expect(
      state.completedTasks.first.liveStatusLog,
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
      final state = AppState();
      state.addApiKey('Key A', 'AIzaSyREAL-TOKEN-1234');

      expect(state.apiKeys.single.maskedToken, contains('•••••'));
      expect(state.apiKeys.single.token, 'AIzaSyREAL-TOKEN-1234');
      state.dispose();
    });

    test('generated key ids stay unique even in the same millisecond', () {
      final state = AppState();
      for (var i = 0; i < 50; i++) {
        state.addApiKey('Key $i', 'token-$i');
      }

      final ids = state.apiKeys.map((k) => k.id).toSet();
      expect(ids.length, 50, reason: 'no duplicate key ids');
      state.dispose();
    });

    test('nextApiKey honours the rotation strategy', () {
      final state = AppState();
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
      final state = AppState();
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
      final state = AppState();
      state.addApiKey('Good', 'token-good');

      // Simulate a legacy record persisted before raw tokens were stored.
      state.previewLegacyKeyWithoutToken();

      expect(state.apiKeys.length, 2);
      expect(state.usableApiKeys.length, 1);
      expect(state.usableApiKeys.single.alias, 'Good');

      state.dispose();
    });
  });
}
