import '../../models/srt_models.dart';

/// Parses and sanitizes the SRT documents returned by Gemini.
///
/// The model is reliable but not perfectly formatted: it emits `:` instead of
/// `,` before milliseconds, zero-width characters, stray code fences and
/// occasionally overlapping cues. Every response therefore goes through
/// [clean] before it reaches the TTS stage.
class SrtParser {
  SrtParser._();

  /// Invisible characters Gemini sometimes injects into the output.
  static const List<int> _invisibleCodeUnits = [
    0x200B, // zero-width space
    0x200C, // zero-width non-joiner
    0x200D, // zero-width joiner
    0xFEFF, // byte order mark
    0x00AD, // soft hyphen
  ];

  static final RegExp _codeFence = RegExp(r'^\s*```[a-zA-Z]*\s*$|^\s*```\s*$');
  static final RegExp _timestampLine = RegExp(r'([\d:,.]+)\s*-->\s*([\d:,.]+)');

  /// Removes invisible unicode characters Gemini sometimes injects.
  static String cleanText(String content) {
    var result = content;
    for (final codeUnit in _invisibleCodeUnits) {
      result = result.replaceAll(String.fromCharCode(codeUnit), '');
    }
    return result;
  }

  /// Ensures exactly one blank line between SRT subtitle blocks.
  static String fixBlankLines(String content) {
    final normalized =
        content.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    if (normalized.isEmpty) return '';

    final blocks = normalized
        .split(RegExp(r'\n{2,}'))
        .map((block) => block.trim())
        .where((block) => block.isNotEmpty);

    return blocks.join('\n\n');
  }

  static int _parseInt(String input, int fallback) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return fallback;
    return int.tryParse(cleaned) ?? fallback;
  }

  static String _format(int hours, int minutes, int seconds, int ms) {
    // Minutes are intentionally NOT clamped to 59: the pysrt-style fix folds
    // hours into minutes (1:02:03 -> 00:62:03) and clamping would silently
    // corrupt any video longer than an hour.
    final safeMinutes = minutes < 0 ? 0 : minutes;
    final safeSeconds = seconds.clamp(0, 59);
    return '${hours.toString().padLeft(2, '0')}:'
        '${safeMinutes.toString().padLeft(2, '0')}:'
        '${safeSeconds.toString().padLeft(2, '0')},'
        '${ms.toString().padLeft(3, '0')}';
  }

  /// Normalizes a single `HH:MM:SS,mmm` timestamp.
  ///
  /// Accepts `:`-separated milliseconds and fractional-seconds styles, takes
  /// the last three time components, and applies the same pysrt-style shift as
  /// the original Python helper: hours are folded into minutes so the value
  /// stays inside the `00:MM:SS,mmm` range most players expect.
  static String normalizeTimestamp(String raw) {
    // Drop any internal whitespace first: Gemini sometimes emits
    // `00:00:04 : 500`, which would otherwise be read as minutes.
    var value = raw.replaceAll(RegExp(r'\s+'), '');

    // `00:00:01:500` -> `00:00:01,500`
    value = value.replaceAllMapped(
      RegExp(r'(\d+):(\d{3})$'),
      (match) => '${match.group(1)},${match.group(2)}',
    );

    String timePart;
    String msPart = '';
    final commaIndex = value.lastIndexOf(',');
    if (commaIndex >= 0) {
      timePart = value.substring(0, commaIndex);
      msPart = value.substring(commaIndex + 1);
    } else {
      timePart = value;
    }

    // Accept a fractional-seconds tail (`00:00:01.500`) as well.
    final dotIndex = timePart.lastIndexOf('.');
    if (dotIndex >= 0) {
      final fraction = timePart.substring(dotIndex + 1);
      timePart = timePart.substring(0, dotIndex);
      if (msPart.isEmpty && fraction.isNotEmpty) {
        msPart = fraction;
      }
    }

    // Left-pad then truncate, mirroring the reference Python's
    // `ms.zfill(3)[:3]`: "5" -> "005" (5ms) and "05" -> "050" (50ms).
    final milliseconds =
        int.tryParse(msPart.padLeft(3, '0').substring(0, 3))?.clamp(0, 999) ??
            0;

    final parts = timePart.split(':').where((part) => part.isNotEmpty).toList();
    final normalized =
        parts.length > 3 ? parts.sublist(parts.length - 3) : parts;

    while (normalized.length < 3) {
      normalized.insert(0, '0');
    }

    final hours = _parseInt(normalized[0], 0);
    final minutes = _parseInt(normalized[1], 0);
    final seconds = _parseInt(normalized[2], 0);

    // pysrt-style fix: shift hours down into minutes.
    if (hours > 0) {
      return _format(0, minutes + hours * 60, seconds, milliseconds);
    }
    return _format(hours, minutes, seconds, milliseconds);
  }

  /// Fixes timestamps using pysrt logic and normalizes the format.
  static String fixTimestamps(String content) {
    return content.replaceAllMapped(_timestampLine, (match) {
      final start = normalizeTimestamp(match.group(1)!);
      final end = normalizeTimestamp(match.group(2)!);
      return '$start --> $end';
    });
  }

  /// Full clean-up pass applied to a raw Gemini response.
  static String clean(String rawContent) {
    var content = cleanText(rawContent);

    // Strip markdown fences the model sometimes wraps the document in.
    content = content
        .split('\n')
        .where((line) => !_codeFence.hasMatch(line))
        .join('\n');

    content = fixTimestamps(content);
    content = fixBlankLines(content);
    return content;
  }

  /// Converts `HH:MM:SS,mmm` into seconds.
  static double toSeconds(String raw) {
    var value = raw.trim();
    value = value.replaceAllMapped(
      RegExp(r'(\d+):(\d{3})$'),
      (match) => '${match.group(1)},${match.group(2)}',
    );
    value = value.replaceAll(':', ' ').replaceAll(',', '.');
    final parts = value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(double.tryParse)
        .whereType<double>()
        .toList();
    if (parts.isEmpty) return 0;
    if (parts.length == 1) return parts.first;
    if (parts.length == 2) return parts[0] * 60 + parts[1];
    return parts[parts.length - 3] * 3600 +
        parts[parts.length - 2] * 60 +
        parts[parts.length - 1];
  }

  /// Removes a leading `[M]`/`[F]` tag and reports the detected gender.
  static ({String text, SpeakerGender gender}) splitGenderTag(String body) {
    final match = RegExp(r'^\s*\[(m|f|male|female)\]', caseSensitive: false)
        .firstMatch(body);

    if (match == null) {
      return (text: body.trim(), gender: SpeakerGender.unknown);
    }

    final tag = match.group(1)!.toLowerCase();
    final gender = (tag == 'm' || tag == 'male')
        ? SpeakerGender.male
        : SpeakerGender.female;

    return (text: body.substring(match.end).trim(), gender: gender);
  }

  /// Parses a cleaned SRT document into [SrtEntry] values.
  ///
  /// Blocks without a readable timestamp are skipped, and cues whose end
  /// precedes their start are swapped (the same repair `pysrt` performs)
  /// rather than crashing the pipeline.
  static List<SrtEntry> parse(String srtContent) {
    final entries = <SrtEntry>[];
    final blocks = srtContent.split(RegExp(r'\n{2,}'));

    var fallbackIndex = 1;
    for (final block in blocks) {
      final lines = block
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      if (lines.isEmpty) continue;

      final timestampIndex = lines.indexWhere((line) => line.contains('-->'));
      if (timestampIndex == -1) continue;

      final match = _timestampLine.firstMatch(lines[timestampIndex]);
      if (match == null) continue;

      var start = toSeconds(match.group(1)!);
      var end = toSeconds(match.group(2)!);

      if (end < start) {
        final swap = start;
        start = end;
        end = swap;
      }
      if (end == start) {
        end = start + 1.0;
      }

      final body = lines.skip(timestampIndex + 1).join(' ').trim();
      if (body.isEmpty) continue;

      final parsed = splitGenderTag(body);
      if (parsed.text.isEmpty) continue;

      var index = fallbackIndex;
      final headerDigits = lines[0].replaceAll(RegExp(r'[^0-9]'), '');
      if (timestampIndex > 0 && int.tryParse(headerDigits) != null) {
        index = int.parse(headerDigits);
      }
      fallbackIndex = index + 1;

      entries.add(
        SrtEntry(
          index: index,
          startSeconds: start,
          endSeconds: end,
          text: parsed.text,
          gender: parsed.gender,
        ),
      );
    }

    return entries;
  }
}
