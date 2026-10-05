import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_navigation_screen.dart';
import 'services/app_state.dart';
import 'services/license/license_controller.dart';
import 'services/license/license_service.dart';
import 'services/license/license_status.dart';
import 'services/license/license_store.dart';
import 'theme/app_theme.dart';
import 'widgets/license_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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

class _KhmerDubberAppState extends State<KhmerDubberApp> {
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
  }

  /// Starts Firebase (once) and then reads the stored license.
  ///
  /// Both steps are guarded so a Firebase problem degrades to the activation
  /// screen instead of a crash on launch: an uninitialised SDK surfaces as a
  /// `networkError`, which the gate reports rather than acting on.
  Future<void> _bootstrapLicense() async {
    try {
      await Firebase.initializeApp();
    } catch (error) {
      debugPrint('[main] Firebase init failed: $error');
    }

    _license.start();
    await _license.bootstrap();
  }

  @override
  void dispose() {
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
          final locked = _state.licenseStatus != LicenseStatus.valid;

          final app = child ?? const SizedBox.shrink();
          if (!locked) return app;

          return LicenseGate(
            lockReason: _state.licenseLockReason,
            onActivate: _license.activate,
            child: app,
          );
        },
      ),
      home: MainNavigationScreen(state: _state),
    );
  }
}
