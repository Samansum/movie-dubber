import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_navigation_screen.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    _state = AppState();
    // Sweep the previous session's intermediates and renders. Nothing can
    // reference them after a restart, and doing this early keeps the device
    // from filling up with orphaned WAV/SRT/MP3/MP4 data.
    _state.cleanupPreviousRun();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineDub AI - Khmer Video Dubber Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: MainNavigationScreen(state: _state),
    );
  }
}
