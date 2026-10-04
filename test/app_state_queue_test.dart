import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_dubber_mobile/models/dub_models.dart';
import 'package:khmer_dubber_mobile/services/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('pipeline starts idle with no dummy data', (tester) async {
    final state = AppState();
    await tester.pump();

    expect(state.activeTask, isNull);
    expect(state.queuedTasks, isEmpty);
    expect(state.completedTasks, isEmpty);
    expect(state.isPipelineBusy, isFalse);

    state.dispose();
  });

  testWidgets('first job runs immediately, later jobs queue at the bottom',
      (tester) async {
    final state = AppState();
    await tester.pump();

    state.startNewDubbingJob(
      videoTitle: 'alpha.mp4',
      duration: '01:00',
      fileSpecs: '10.0 MB • MP4 • 1920 × 1080',
    );

    expect(state.activeTask, isNotNull);
    expect(state.activeTask!.videoTitle, 'alpha.mp4');
    expect(state.activeTask!.isProcessing, isTrue);
    expect(state.queuedTasks, isEmpty);
    expect(state.currentTabIndex, 1, reason: 'navigates to Queue tab');

    state.startNewDubbingJob(
      videoTitle: 'beta.mp4',
      duration: '02:00',
      fileSpecs: '20.0 MB • MP4 • 1280 × 720',
    );

    expect(state.activeTask!.videoTitle, 'alpha.mp4');
    expect(state.queuedTasks.length, 1);
    expect(state.queuedTasks.first.videoTitle, 'beta.mp4');
    expect(state.queuedTasks.first.isQueued, isTrue);
    expect(state.queuedTasks.first.isProcessing, isFalse);

    state.dispose();
  });

  testWidgets('runs 4 x 10s stages then picks the next queued job',
      (tester) async {
    final state = AppState();
    await tester.pump();

    state.startNewDubbingJob(
      videoTitle: 'first.mp4',
      duration: '01:00',
      fileSpecs: '10.0 MB • MP4 • 1920 × 1080',
    );
    state.startNewDubbingJob(
      videoTitle: 'second.mp4',
      duration: '02:00',
      fileSpecs: '20.0 MB • MP4 • 1280 × 720',
    );

    // Stage 1 is running right after starting.
    expect(state.activeTask!.stages.first.status, StageStatus.inProgress);

    // 20s in, the third stage (index 2) is running.
    await tester.pump(const Duration(seconds: 20));
    expect(state.activeTask!.videoTitle, 'first.mp4');
    expect(state.activeTask!.stages[2].status, StageStatus.inProgress);

    // 40s total finishes the first job; the queued one takes over.
    await tester.pump(const Duration(seconds: 20));
    expect(state.completedTasks.length, 1);
    expect(state.completedTasks.first.videoTitle, 'first.mp4');
    expect(state.completedTasks.first.isCompleted, isTrue);
    expect(state.activeTask!.videoTitle, 'second.mp4');
    expect(state.queuedTasks, isEmpty);

    // Finish the second job too: the queue drains and the pipeline goes idle.
    await tester.pump(const Duration(seconds: 40));
    expect(state.activeTask, isNull);
    expect(state.completedTasks.length, 2);
    expect(state.completedTasks.first.videoTitle, 'second.mp4');
    expect(state.isPipelineBusy, isFalse);

    state.dispose();
  });

  testWidgets('terminate aborts the active job and starts the next one',
      (tester) async {
    final state = AppState();
    await tester.pump();

    state.startNewDubbingJob(
      videoTitle: 'a.mp4',
      duration: '01:00',
      fileSpecs: '1.0 MB • MP4 • 640 × 480',
    );
    state.startNewDubbingJob(
      videoTitle: 'b.mp4',
      duration: '01:00',
      fileSpecs: '1.0 MB • MP4 • 640 × 480',
    );

    state.terminateActiveProcess();

    expect(state.activeTask!.videoTitle, 'b.mp4');
    expect(state.activeTask!.isProcessing, isTrue);
    expect(state.queuedTasks, isEmpty);
    expect(state.completedTasks, isEmpty);

    state.dispose();
  });

  testWidgets('removeQueuedTask drops only the target job', (tester) async {
    final state = AppState();
    await tester.pump();

    state.startNewDubbingJob(
      videoTitle: 'running.mp4',
      duration: '01:00',
      fileSpecs: '1.0 MB • MP4 • 640 × 480',
    );
    state.startNewDubbingJob(
      videoTitle: 'queued-1.mp4',
      duration: '02:00',
      fileSpecs: '2.0 MB • MP4 • 1280 × 720',
    );
    state.startNewDubbingJob(
      videoTitle: 'queued-2.mp4',
      duration: '03:00',
      fileSpecs: '3.0 MB • MP4 • 1920 × 1080',
    );

    expect(state.queuedTasks.length, 2);
    final target = state.queuedTasks.first;

    expect(state.removeQueuedTask(target.id), isTrue);

    // Only the targeted job is gone; the active render is untouched.
    expect(state.queuedTasks.length, 1);
    expect(state.queuedTasks.first.videoTitle, 'queued-2.mp4');
    expect(state.activeTask!.videoTitle, 'running.mp4');
    expect(state.activeTask!.isProcessing, isTrue);

    state.dispose();
  });

  testWidgets('removeQueuedTask renumbers the remaining queue positions',
      (tester) async {
    final state = AppState();
    await tester.pump();

    state.startNewDubbingJob(
      videoTitle: 'running.mp4',
      duration: '01:00',
      fileSpecs: '1.0 MB • MP4 • 640 × 480',
    );
    state.startNewDubbingJob(
      videoTitle: 'queued-1.mp4',
      duration: '02:00',
      fileSpecs: '2.0 MB • MP4 • 1280 × 720',
    );
    state.startNewDubbingJob(
      videoTitle: 'queued-2.mp4',
      duration: '03:00',
      fileSpecs: '3.0 MB • MP4 • 1920 × 1080',
    );
    state.startNewDubbingJob(
      videoTitle: 'queued-3.mp4',
      duration: '04:00',
      fileSpecs: '4.0 MB • MP4 • 1920 × 1080',
    );

    expect(state.queuedTasks[0].liveStatusLog, contains('#1'));
    expect(state.queuedTasks[2].liveStatusLog, contains('#3'));

    // Removing the head promotes queued-2 to position #1.
    state.removeQueuedTask(state.queuedTasks.first.id);

    expect(state.queuedTasks.first.videoTitle, 'queued-2.mp4');
    expect(state.queuedTasks.first.liveStatusLog, contains('#1'));
    expect(state.queuedTasks.last.videoTitle, 'queued-3.mp4');
    expect(state.queuedTasks.last.liveStatusLog, contains('#2'));

    state.dispose();
  });

  testWidgets('removeQueuedTask returns false for unknown or active jobs',
      (tester) async {
    final state = AppState();
    await tester.pump();

    state.startNewDubbingJob(
      videoTitle: 'running.mp4',
      duration: '01:00',
      fileSpecs: '1.0 MB • MP4 • 640 × 480',
    );
    final activeId = state.activeTask!.id;

    expect(state.removeQueuedTask('does-not-exist'), isFalse);
    expect(state.removeQueuedTask(activeId), isFalse);
    expect(state.activeTask!.videoTitle, 'running.mp4');
    expect(state.activeTask!.isProcessing, isTrue);

    state.dispose();
  });

  testWidgets('a removed job never runs even after the active one finishes',
      (tester) async {
    final state = AppState();
    await tester.pump();

    state.startNewDubbingJob(
      videoTitle: 'running.mp4',
      duration: '01:00',
      fileSpecs: '1.0 MB • MP4 • 640 × 480',
    );
    state.startNewDubbingJob(
      videoTitle: 'keep.mp4',
      duration: '02:00',
      fileSpecs: '2.0 MB • MP4 • 1280 × 720',
    );
    state.startNewDubbingJob(
      videoTitle: 'drop.mp4',
      duration: '03:00',
      fileSpecs: '3.0 MB • MP4 • 1920 × 1080',
    );

    final dropped = state.queuedTasks.firstWhere(
      (task) => task.videoTitle == 'drop.mp4',
    );
    expect(state.removeQueuedTask(dropped.id), isTrue);

    // The active job completes and promotes the surviving queued job.
    await tester.pump(const Duration(seconds: 40));
    expect(state.activeTask!.videoTitle, 'keep.mp4');
    expect(state.queuedTasks, isEmpty);

    await tester.pump(const Duration(seconds: 40));
    expect(state.completedTasks.length, 2);
    expect(
      state.completedTasks.map((task) => task.videoTitle),
      isNot(contains('drop.mp4')),
    );

    state.dispose();
  });
}
