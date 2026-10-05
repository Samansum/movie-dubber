import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../firebase_options.dart';
import 'models/dub_models.dart';
import 'screens/main_navigation_screen.dart';
import 'services/app_state.dart';
import 'services/foreground/foreground_keep_alive_service.dart';
import 'services/license/license_controller.dart';
import 'services/license/license_service.dart';
import 'services/license/license_store.dart';
import 'theme/app_theme.dart';
import 'widgets/license_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Open the isolate communication port before runApp so the foreground
  // task's isolate can talk to the UI isolate once the keep-alive service
  // starts.
  ForegroundKeepAliveService.initCommunicationPort();

  // Set system navigation and status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0E16),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const KhmerDubberApp());
}

class KhmerDubberApp extends StatefulWidget {
  const KhmerDubberApp({super.key});

  @override
  State<KhmerDubberApp> createState() => _KhmerDubberAppState();
}

class _KhmerDubberAppState extends State<KhmerDubberApp>
    with WidgetsBindingObserver {
  late final AppState _state;
  late final LicenseController _license;

  @override
  void initState() {
    super.initState();
    _state = AppState();

    // The license gate owns its own Firebase/secure-storage instances so it can
    // be constructed synchronously, before `Firebase.initializeApp()` resolves.
    final store = SecureLicenseStore();
    final service = LicenseService(store: store);
    _license = LicenseController(service: service, state: _state, store: store);

    _bootstrapLicense();

    // Sweep the previous session's intermediates and renders. Nothing can
    // reference them after a restart, and doing this early keeps the device
    // from filling up with orphaned WAV/SRT/MP3/MP4 data.
    _state.cleanupPreviousRun();

    // Background keep-alive: pin the process with a foreground service so an
    // in-flight dubbing job survives the user switching to another app. The
    // service is started after the first frame — Android 12+ refuses
    // foreground service starts that race Activity creation — and is never
    // stopped by the app; only swiping the task away terminates it.
    WidgetsBinding.instance.addObserver(this);
    _state.addListener(_syncKeepAliveNotification);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ForegroundKeepAliveService.start();
    });
  }

  /// Reads the stored license, then starts Firebase and runs the daily check.
  ///
  /// The local read comes first deliberately: it needs no Firebase, so the
  /// gate decision settles while Firebase is still initialising. An
  /// unactivated device reaches the activation screen in a few hundred
  /// milliseconds instead of only after a multi-second Firebase start-up.
  ///
  /// [DefaultFirebaseOptions.currentPlatform] is required: without it Android
  /// falls back to whatever `google-services.json` produced, and a mismatch
  /// between that file and the Dart options points the SDK at the wrong project.
  /// Firebase must also be initialised *before* the Firestore check — a due
  /// check run earlier would hit `FirebaseAuth.instance` with no app
  /// registered, map that to `networkError` and burn the attempt.
  ///
  /// Firebase startup is guarded so a problem degrades to the activation
  /// screen instead of a crash on launch.
  Future<void> _bootstrapLicense() async {
    await _license.bootstrap();

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (error) {
      debugPrint('[main] Firebase init failed: $error');
    }

    _license.start();
    await _license.checkOnForeground();
  }

  /// Restarts the keep-alive service when the app returns to the foreground.
  ///
  /// Android 12+ blocks foreground service starts from the background, so a
  /// resume is the first moment a service reclaimed by the OS can be brought
  /// back. Also refreshes the notification so it reflects the current job.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ForegroundKeepAliveService.ensureRunning();
      _syncKeepAliveNotification();
    }
  }

  /// Mirrors the dubbing pipeline state into the keep-alive notification, so
  /// the user can see what the app is doing while it is not on screen.
  void _syncKeepAliveNotification() {
    ForegroundKeepAliveService.setStatusText(_keepAliveStatusText());
  }

  /// One-line summary of the current workload shown in the notification.
  String _keepAliveStatusText() {
    final active = _state.activeTask;
    if (active != null && active.isProcessing) {
      final stageIndex = active.stages
          .indexWhere((stage) => stage.status == StageStatus.inProgress);
      final stage = stageIndex >= 0
          ? DubbingStageCatalog.titleFor(stageIndex)
          : 'Dubbing';
      final percent = (active.progress * 100).clamp(0, 100).round();
      return '${active.videoTitle} — $stage · $percent%';
    }

    final queued = _state.queuedTasks.length;
    if (queued > 0) {
      return queued == 1 ? '1 job queued' : '$queued jobs queued';
    }

    final failed = _state.failedTasks.length;
    if (failed > 0) {
      return failed == 1
          ? '1 job failed — open CineDub to review'
          : '$failed jobs failed — open CineDub to review';
    }

    return ForegroundKeepAliveService.idleNotificationText;
  }

  @override
  void dispose() {
    // The foreground keep-alive service is deliberately NOT stopped here:
    // it must outlive the UI so a backgrounded dubbing job keeps running
    // until the user swipes the app away from Recents.
    WidgetsBinding.instance.removeObserver(this);
    _state.removeListener(_syncKeepAliveNotification);
    _license.stop();
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineDub AI - Khmer Video Dubber Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // The gate wraps the Navigator so the lock covers every route, dialog and
      // overlay the app can push — not just the first screen.
      builder: (context, child) => AnimatedBuilder(
        animation: _state,
        builder: (context, _) {
          // Mount the gate only once a check has positively said `locked`.
          // During the initial `unknown` window the app renders — otherwise a
          // licensed user would see the activation screen flash on every
          // launch — while `AppState.isLicenseBlocked` keeps the dubbing
          // pipeline shut until the stored key has been read.
          final locked = _state.showLicenseGate;

          final app = child ?? const SizedBox.shrink();
          if (!locked) return app;

          return LicenseGate(
            lockReason: _state.licenseLockReason,
            onActivate: _license.activate,
            errorDetail: () => _license.lastErrorDetail,
            child: app,
          );
        },
      ),
      home: MainNavigationScreen(state: _state),
    );
  }
}
