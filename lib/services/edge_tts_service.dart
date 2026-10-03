import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:edge_tts/edge_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

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
      _onPlaybackCompleted?.call();
    });
  }

  String? get currentlyPlayingVoiceId => _currentlyPlayingVoiceId;

  /// Synthesizes [text] with an Edge neural voice such as
  /// `km-KH-PisethNeural` or `km-KH-SreymomNeural` and returns MP3 bytes.
  Future<Uint8List> synthesize({
    required String text,
    required String voice,
    String rate = '+0%',
    String pitch = '+0Hz',
    String volume = '+0%',
  }) async {
    final tts = Communicate(
      text: text,
      voice: voice,
      rate: rate,
      pitch: pitch,
      volume: volume,
    );

    final audioBuilder = BytesBuilder(copy: false);

    // Stream audio events directly using type pattern matching
    await for (final event in tts.stream()) {
      if (event is AudioDataEvent) {
        audioBuilder.add(event.data);
      }
    }

    final bytes = audioBuilder.takeBytes();
    if (bytes.isEmpty) {
      throw Exception('Edge TTS returned no audio for voice $voice');
    }
    return bytes;
  }

  // ---- Public API ----

  /// Fetch audio from Edge TTS for the given voice ID (e.g. km-KH-PisethNeural)
  /// and Khmer sample text. Caches the MP3 locally.
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

    debugPrint('[EdgeTtsService] Fetching audio from Edge TTS for $voiceId...');

    final bytes = await synthesize(text: khmerText, voice: voiceId);
    await cacheFile.writeAsBytes(bytes, flush: true);

    debugPrint('[EdgeTtsService] Saved TTS audio to ${cacheFile.path}');
    return cacheFile;
  }

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
