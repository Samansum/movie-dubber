/// Voice characteristics Gemini detected for a subtitle line.
enum SpeakerGender {
  male,
  female,

  /// Returned when the line has no usable `[M]`/`[F]` tag.
  unknown,
}

/// A single parsed SRT cue.
class SrtEntry {
  /// Cue index as written in the source document.
  final int index;

  /// Cue start time, in seconds from the beginning of the media.
  final double startSeconds;

  /// Cue end time, in seconds from the beginning of the media.
  final double endSeconds;

  /// Khmer dialogue with the `[M]`/`[F]` prefix already stripped.
  final String text;

  final SpeakerGender gender;

  const SrtEntry({
    required this.index,
    required this.startSeconds,
    required this.endSeconds,
    required this.text,
    required this.gender,
  });

  /// Length of the slot this cue has to be rendered into. The synthesized
  /// speech is time-stretched to fit it.
  double get slotDuration => endSeconds - startSeconds;

  @override
  String toString() =>
      'SrtEntry(#$index, ${startSeconds.toStringAsFixed(2)}s, $text)';
}

/// One synthesized dialogue line on its way to the final audio mix.
class DubbingSegment {
  /// Absolute path of the generated MP3 for this cue.
  final String audioPath;

  /// Where the cue starts in the source video timeline.
  final double startSeconds;

  /// Real duration of [audioPath], measured with FFprobe after synthesis.
  final double durationSeconds;

  /// Slot the speech has to fit into, taken from the SRT timestamps.
  final double targetSlotDuration;

  final SpeakerGender gender;

  const DubbingSegment({
    required this.audioPath,
    required this.startSeconds,
    required this.durationSeconds,
    required this.targetSlotDuration,
    required this.gender,
  });

  /// `atempo` multiplier needed to squeeze the speech into its slot.
  ///
  /// Anything that already fits returns `1.0`; the result is capped by the
  /// caller (FFmpeg's `atempo` gets unintuitive above ~2.0).
  double get calculatedSpeed {
    if (targetSlotDuration <= 0) return 1.0;
    if (durationSeconds <= targetSlotDuration) return 1.0;
    return durationSeconds / targetSlotDuration;
  }
}
