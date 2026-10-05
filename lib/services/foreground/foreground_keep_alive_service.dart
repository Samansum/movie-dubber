import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Entry point the foreground service invokes inside its own (task) isolate
/// whenever the service starts.
///
/// Must stay top-level and keep `@pragma('vm:entry-point')` — the AOT
/// snapshot only retains callbacks that carry the annotation, and the handle
/// is resolved with `PluginUtilities.getCallbackHandle` at service start.
@pragma('vm:entry-point')
void foregroundKeepAliveCallback() {
  FlutterForegroundTask.setTaskHandler(KeepAliveTaskHandler());
}

/// Task handler living in the service isolate.
///
/// The keep-alive service has no background workload of its own: the dubbing
/// pipeline keeps executing on the main isolate as long as the process is
/// pinned by the foreground service. The handler therefore only records
/// lifecycle events for debugging.
class KeepAliveTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[KeepAlive] service started (starter: ${starter.name})');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Not used: the task runs with [ForegroundTaskEventAction.nothing].
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    debugPrint('[KeepAlive] service destroyed (timeout: $isTimeout)');
  }
}

/// Keeps the dubbing process alive while the app is in the background.
///
/// Android reaps cached processes within minutes of an app being backgrounded,
/// which would kill an in-flight dubbing job. Starting a foreground service
/// pins the process at foreground priority, so the FFmpeg/Gemini/Edge-TTS
/// pipeline keeps running when the user switches to another app — until the
/// user force-terminates the app by swiping it from Recents.
///
/// **Why the service stops on swipe but not on app-switch**
///
/// The manifest declares the plugin service with `android:stopWithTask="true"`
/// while the Dart-side `ForegroundTaskOptions.stopWithTask` is deliberately
/// left unset:
///
/// * Passing `stopWithTask: true` from Dart writes the option into the
///   plugin's preferences, which makes the plugin install
///   `TrackVisibilityUtils` — a callback that stops the service as soon as the
///   last Activity pauses, i.e. the moment the user switches apps. That is
///   the opposite of this feature.
/// * Leaving it unset makes the plugin read the manifest flag instead:
///   `onTaskRemoved` calls `stopSelf()` (swipe from Recents terminates the
///   app and no restart alarm is scheduled) while ordinary backgrounding
///   never touches the service.
class ForegroundKeepAliveService {
  ForegroundKeepAliveService._();

  /// Notification channel shown while the service runs.
  static const String _channelId = 'cinedub_keep_alive';

  /// Title of the persistent keep-alive notification.
  static const String notificationTitle = 'CineDub AI is running';

  /// Text used until the first real state update arrives.
  static const String idleNotificationText =
      'Ready — dubbing keeps running in the background';

  /// Minimum spacing between notification text updates.
  ///
  /// The pipeline can emit progress several times a second; pushing every
  /// tick through the platform channel would be pure overhead, so updates are
  /// rate-limited with a trailing flush that always delivers the latest text.
  static const Duration _updateInterval = Duration(seconds: 1);

  static bool _initialized = false;
  static bool _startRequested = false;
  static bool _serviceRunning = false;

  static String? _lastSentText;
  static DateTime _lastSentAt = DateTime.fromMillisecondsSinceEpoch(0);
  static String? _pendingText;
  static Timer? _flushTimer;

  /// Whether a start was attempted and the service reported success.
  static bool get isRunning => _serviceRunning;

  /// Opens the isolate communication port used by the task handler.
  ///
  /// Call this once from `main()` **before** `runApp`.
  static void initCommunicationPort() {
    FlutterForegroundTask.initCommunicationPort();
  }

  /// Requests the runtime permissions the service needs to be visible.
  /// Failures are logged only — a declined permission degrades the
  /// notification's visibility but never prevents the service from running.
  static Future<void> _requestPermissions() async {
    try {
      // Android 13+: the foreground service notification is only shown once
      // the POST_NOTIFICATIONS permission is granted.
      final permission =
          await FlutterForegroundTask.checkNotificationPermission();
      if (permission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
    } catch (error) {
      debugPrint('[KeepAlive] notification permission request failed: $error');
    }
  }

  /// Best-effort battery-optimization exemption (Android 6+).
  ///
  /// Aggressive OEM power managers (Xiaomi, Huawei, Samsung…) otherwise kill
  /// background processes regardless of the foreground service. The system
  /// dialog is shown only once and only when the app is not exempt yet.
  static Future<void> _requestBatteryExemption() async {
    if (!Platform.isAndroid) return;
    try {
      if (await FlutterForegroundTask.isIgnoringBatteryOptimizations) return;
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    } catch (error) {
      debugPrint('[KeepAlive] battery exemption request failed: $error');
    }
  }

  /// Registers the plugin options. Idempotent.
  static void _initTask() {
    if (_initialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: 'CineDub keep-alive',
        channelDescription:
            'Holds the dubbing pipeline alive while the app is in the '
            'background.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
        showWhen: false,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        // Not a boot-resumed service: after a reboot the user has no task in
        // Recents anymore, so there is nothing left to keep alive.
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        // The pipeline is network-bound (Gemini, Edge TTS) and CPU-bound
        // (FFmpeg): hold the CPU and the Wi-Fi radio while it runs.
        allowWakeLock: true,
        allowWifiLock: true,
        // Schedule a restart if Android destroys the service without an
        // explicit stop (e.g. an OEM memory trim).
        allowAutoRestart: true,
        // `stopWithTask` is intentionally NOT set here — see the class docs.
      ),
    );
    _initialized = true;
  }

  static Future<void> _doStart() async {
    _initTask();

    if (Platform.isAndroid) {
      await _requestPermissions();
    }

    final ServiceRequestResult result;
    try {
      result = await FlutterForegroundTask.startService(
        notificationTitle: notificationTitle,
        notificationText: idleNotificationText,
        callback: foregroundKeepAliveCallback,
      );
    } catch (error) {
      // Never let a platform failure take the app down at launch.
      debugPrint('[KeepAlive] startService threw: $error');
      _serviceRunning = false;
      return;
    }

    if (result is ServiceRequestSuccess) {
      _serviceRunning = true;
      if (Platform.isAndroid) {
        unawaited(_requestBatteryExemption());
      }
    } else if (result is ServiceRequestFailure) {
      // A leftover instance from a previous run is as good as a fresh start.
      if (result.error is ServiceAlreadyStartedException) {
        _serviceRunning = true;
      } else {
        _serviceRunning = false;
        debugPrint('[KeepAlive] startService failed: ${result.error}');
      }
    }
  }

  /// Starts the foreground service exactly once.
  ///
  /// Safe to call repeatedly (e.g. from a post-frame callback): subsequent
  /// calls become no-ops.
  static Future<void> start() async {
    if (_startRequested) return;
    _startRequested = true;
    await _doStart();
  }

  /// Restarts the service if the OS reclaimed it while the app was away.
  ///
  /// Android 12+ forbids foreground service starts from the background, so
  /// this must be called when the app is (back) in the foreground — the app
  /// resume hook is the natural place.
  static Future<void> ensureRunning() async {
    if (!_startRequested) return;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        _serviceRunning = true;
        return;
      }
      debugPrint('[KeepAlive] service was reclaimed — restarting');
      await _doStart();
    } catch (error) {
      debugPrint('[KeepAlive] ensureRunning failed: $error');
    }
  }

  /// Pushes [text] into the keep-alive notification, at most one update per
  /// [_updateInterval] with a trailing flush so the final text is never lost.
  static Future<void> setStatusText(String text) async {
    if (!_serviceRunning || text == _lastSentText) return;

    final elapsed = DateTime.now().difference(_lastSentAt);
    if (elapsed >= _updateInterval) {
      await _sendStatusText(text);
      return;
    }

    _pendingText = text;
    _flushTimer ??= Timer(_updateInterval - elapsed, () {
      _flushTimer = null;
      final pending = _pendingText;
      _pendingText = null;
      if (pending != null) unawaited(_sendStatusText(pending));
    });
  }

  static Future<void> _sendStatusText(String text) async {
    _lastSentText = text;
    _lastSentAt = DateTime.now();
    try {
      final result =
          await FlutterForegroundTask.updateService(notificationText: text);
      if (result is ServiceRequestFailure &&
          result.error is ServiceNotStartedException) {
        _serviceRunning = false;
      }
    } catch (error) {
      debugPrint('[KeepAlive] updateService failed: $error');
    }
  }

  /// Stops the service. Never called during the app lifecycle — the whole
  /// point is that the service outlives the UI — only for completeness and
  /// tests.
  static Future<void> stop() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    _pendingText = null;
    _lastSentText = null;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        final result = await FlutterForegroundTask.stopService();
        if (result is ServiceRequestFailure) {
          debugPrint('[KeepAlive] stopService failed: ${result.error}');
        }
      }
    } catch (error) {
      debugPrint('[KeepAlive] stopService threw: $error');
    } finally {
      _serviceRunning = false;
      _startRequested = false;
    }
  }
}
