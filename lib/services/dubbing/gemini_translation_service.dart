import 'dart:io';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../models/srt_models.dart';
import '../../prompts/khmer_dubbing_prompt.dart';
import 'srt_parser.dart';

/// Raised when the Gemini request fails or returns nothing usable.
class GeminiTranslationException implements Exception {
  final String message;

  const GeminiTranslationException(this.message);

  @override
  String toString() => 'Gemini translation failed: $message';
}

/// STEP 2 — Transcribes and translates an audio track into Khmer SRT cues.
///
/// Uses the Gemini model and API key chosen in the Dubbing Settings screen.
/// The raw response is always run through [SrtParser] before it is returned,
/// so the rest of the pipeline only ever sees well-formed cues.
class GeminiTranslationService {
  const GeminiTranslationService();

  /// Maps the display labels used by the Settings screen to real model ids.
  static const Map<String, String> _modelAliases = {
    'Gemini 1.5 Pro': 'gemini-1.5-pro',
    'Gemini 1.5 Flash': 'gemini-1.5-flash',
    'Gemini 2.0 Flash': 'gemini-2.0-flash',
    'Gemini 2.5 Flash': 'gemini-2.5-flash',
    'Gemini 2.5 Pro': 'gemini-2.5-pro',
    'Gemini 3.5 Flash': 'gemini-3.5-flash',
    'Gemini 3.7 Flash': 'gemini-3.7-flash',
    'Gemini 3.8 Flash': 'gemini-3.8-flash',
  };

  static const String _defaultModelId = 'gemini-2.5-flash';

  /// Converts a Settings-screen label such as `Gemini 2.5 Flash` into the API
  /// model id (`gemini-2.5-flash`).
  ///
  /// Already-valid ids (`gemini-...`) pass through untouched, so an unknown
  /// label degrades to [defaultModelId] rather than throwing.
  static String resolveModelId(String displayName) {
    final trimmed = displayName.trim();

    final alias = _modelAliases[trimmed];
    if (alias != null) return alias;

    final lower = trimmed.toLowerCase();
    if (lower.startsWith('gemini')) {
      return lower.replaceAll(' ', '-');
    }
    return _defaultModelId;
  }

  /// MIME type describing [audioPath] for the Gemini `inlineData` payload.
  static String mimeTypeFor(String audioPath) {
    final lower = audioPath.toLowerCase();
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.m4a') || lower.endsWith('.aac')) return 'audio/aac';
    if (lower.endsWith('.ogg')) return 'audio/ogg';
    if (lower.endsWith('.flac')) return 'audio/flac';
    if (lower.endsWith('.webm')) return 'audio/webm';
    // The pipeline extracts 48kHz mono WAV before calling this method.
    return 'audio/wav';
  }

  /// Sends [audioPath] to Gemini and returns the cleaned SRT document.
  Future<String> transcribeAndTranslate({
    required String audioPath,
    required String apiKey,
    required String modelDisplayName,
  }) async {
    final file = File(audioPath);
    if (!file.existsSync()) {
      throw GeminiTranslationException('Audio file not found: $audioPath');
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw GeminiTranslationException('Extracted audio is empty.');
    }

    final model = GenerativeModel(
      model: resolveModelId(modelDisplayName),
      apiKey: apiKey,
      systemInstruction: Content.system(KhmerDubbingPrompt.systemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.4,
        topP: 0.95,
        maxOutputTokens: 65536,
      ),
    );

    final Uint8List audioBytes = bytes;
    final content = Content.multi([
      TextPart(KhmerDubbingPrompt.requestInstruction),
      DataPart(mimeTypeFor(audioPath), audioBytes),
    ]);

    GenerateContentResponse response;
    try {
      response = await model.generateContent([content]);
    } on Exception catch (e) {
      throw GeminiTranslationException(_describe(e));
    }

    final text = response.text;
    if (text == null || text.trim().isEmpty) {
      final blockReason = response.candidates.firstOrNull?.finishReason;
      throw GeminiTranslationException(
        'Gemini returned an empty response'
        '${blockReason == null ? '' : ' (finish reason: $blockReason)'}.',
      );
    }

    return SrtParser.clean(text);
  }

  /// Transcribes, translates and parses in one step.
  Future<List<SrtEntry>> transcribeAndTranslateToEntries({
    required String audioPath,
    required String apiKey,
    required String modelDisplayName,
  }) async {
    final srt = await transcribeAndTranslate(
      audioPath: audioPath,
      apiKey: apiKey,
      modelDisplayName: modelDisplayName,
    );

    final entries = SrtParser.parse(srt);
    if (entries.isEmpty) {
      throw const GeminiTranslationException(
        'No usable subtitle cues were found in the Gemini response.',
      );
    }
    return entries;
  }

  /// Extracts a readable message from the SDK exception types.
  String _describe(Exception error) {
    if (error is GenerativeAIException) {
      return error.message;
    }
    return error.toString();
  }
}
