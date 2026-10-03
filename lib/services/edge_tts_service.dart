import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class EdgeTtsService {
  static final EdgeTtsService _instance = EdgeTtsService._internal();
  factory EdgeTtsService() => _instance;
  EdgeTtsService._internal() {
    _initAudioPlayer();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingVoiceId;
  VoidCallback? _onPlaybackCompleted;

  void _initAudioPlayer() {
    _audioPlayer.onPlayerComplete.listen((_) {
      _currentlyPlayingVoiceId = null;
      if (_onPlaybackCompleted != null) {
        _onPlaybackCompleted!();
      }
    });
  }

  String? get currentlyPlayingVoiceId => _currentlyPlayingVoiceId;

  /// Fetch audio from Google/Edge TTS for the given voice ID and Khmer sample text.
  /// Caches the generated MP3 locally so subsequent calls play directly from cache.
  Future<File> getOrFetchAudio({
    required String voiceId,
    required String khmerText,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final cacheFile = File('${docsDir.path}/tts_cache_$voiceId.mp3');

    if (await cacheFile.exists() && (await cacheFile.length()) > 0) {
      debugPrint('[EdgeTtsService] Loaded cached audio for $voiceId');
      return cacheFile;
    }

    debugPrint('[EdgeTtsService] Fetching audio from TTS endpoint for $voiceId...');
    final encodedText = Uri.encodeComponent(khmerText);
    // Google TTS public endpoint for Khmer
    final url = Uri.parse(
      'https://translate.google.com/translate_tts?ie=UTF-8&q=$encodedText&tl=km&client=tw-ob',
    );

    final response = await http.get(
      url,
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
    );

    if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
      await cacheFile.writeAsBytes(response.bodyBytes);
      debugPrint('[EdgeTtsService] Saved TTS audio to ${cacheFile.path}');
      return cacheFile;
    } else {
      throw Exception('Failed to fetch TTS audio: ${response.statusCode}');
    }
  }

  /// Play audio for a specific voice profile.
  /// If already playing this voice, it stops playback.
  Future<void> togglePlaySample({
    required String voiceId,
    required String khmerText,
    required VoidCallback onStateChanged,
  }) async {
    if (_currentlyPlayingVoiceId == voiceId) {
      await stopSample();
      onStateChanged();
      return;
    }

    await _audioPlayer.stop();
    _currentlyPlayingVoiceId = voiceId;
    _onPlaybackCompleted = () {
      _currentlyPlayingVoiceId = null;
      onStateChanged();
    };
    onStateChanged();

    try {
      final audioFile = await getOrFetchAudio(
        voiceId: voiceId,
        khmerText: khmerText,
      );

      if (_currentlyPlayingVoiceId == voiceId) {
        await _audioPlayer.play(DeviceFileSource(audioFile.path));
      }
    } catch (e) {
      debugPrint('[EdgeTtsService] Error playing sample: $e');
      _currentlyPlayingVoiceId = null;
      onStateChanged();
    }
  }

  Future<void> stopSample() async {
    await _audioPlayer.stop();
    _currentlyPlayingVoiceId = null;
  }
}
