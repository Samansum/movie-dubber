import 'dart:io';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../models/srt_models.dart';
import '../../prompts/khmer_dubbing_prompt.dart';
import 'srt_parser.dart';

/// Why a Gemini call failed, so callers can decide between retrying, rotating
/// the API key, or giving up.
enum GeminiFailureKind {
  /// Quota/RPM exhausted (HTTP 429 / RESOURCE_EXHAUSTED). A different key from
  /// the pool will usually succeed.
  rateLimited,

  /// 5xx / UNAVAILABLE — the request never reached a healthy backend.
  /// Retrying the *same* key is worthwhile.
  transientServer,

  /// The key was rejected (API_KEY_INVALID). Retrying it is pointless, but
  /// another key from the pool may work.
  invalidKey,

  /// Region blocked, malformed request, SDK bug, empty response, etc.
  /// Retrying will not help.
  fatal,
}

/// Raised when the Gemini request fails or returns nothing usable.
class GeminiTranslationException implements Exception {
  final String message;

  /// Raw SDK error body, kept for the copy-to-clipboard report.
  final String details;

  final GeminiFailureKind kind;

  const GeminiTranslationException(
    this.message, {
    this.details = '',
    this.kind = GeminiFailureKind.fatal,
  });

  bool get isRateLimited => kind == GeminiFailureKind.rateLimited;
  bool get isTransient => kind == GeminiFailureKind.transientServer;
  bool get isInvalidKey => kind == GeminiFailureKind.invalidKey;

  /// Retrying with the same key could plausibly succeed.
  bool get isRetryable =>
      kind == GeminiFailureKind.rateLimited ||
      kind == GeminiFailureKind.transientServer ||
      kind == GeminiFailureKind.invalidKey;

  @override
  String toString() => 'Gemini translation failed: $message';
}

/// Classifies an SDK exception into a [GeminiFailureKind].
///
/// `google_generative_ai` 0.4.x exposes no status code: 5xx responses arrive
/// as a base `GenerativeAIException` whose *message* embeds
/// `Server Error [<code>]`, while 4xx bodies are routed through `parseError`,
/// which maps everything except an invalid key to `ServerException`. Rate
/// limits therefore have to be detected from the message text.
GeminiFailureKind classifyGeminiError(Object error) {
  if (error is InvalidApiKey) return GeminiFailureKind.invalidKey;
  if (error is UnsupportedUserLocation) return GeminiFailureKind.fatal;
  if (error is GenerativeAISdkException) return GeminiFailureKind.fatal;

  final text = (error is GenerativeAIException ? error.message : error.toString())
      .toLowerCase();

  // Rate limit wins over the generic server bucket: a 429 also surfaces as
  // ServerException, but it needs a *different key*, not the same one again.
  if (text.contains('429') ||
      text.contains('resource_exhausted') ||
      text.contains('rate limit') ||
      text.contains('ratelimit') ||
      text.contains('quota exceeded') ||
      text.contains('too many requests')) {
    return GeminiFailureKind.rateLimited;
  }

  if (text.contains('server error') ||
      text.contains('503') ||
      text.contains('502') ||
      text.contains('504') ||
      text.contains('500') ||
      text.contains('unavailable') ||
      text.contains('deadline exceeded') ||
      text.contains('internal error')) {
    return GeminiFailureKind.transientServer;
  }

  // `ServerException` is the SDK's catch-all for unrecognised 4xx bodies;
  // those are worth one more try before giving up.
  if (error is ServerException) return GeminiFailureKind.transientServer;

  return GeminiFailureKind.fatal;
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
      // Keep the classification so the orchestrator can retry transient
      // failures and rotate keys on 429, instead of failing the whole job.
      throw GeminiTranslationException(
        _describe(e),
        details: _rawDetailsOf(e),
        kind: classifyGeminiError(e),
      );
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

  /// Unfiltered SDK text for the copy-to-clipboard diagnostic.
  String _rawDetailsOf(Exception error) => error.toString();
}
