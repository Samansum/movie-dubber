import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_dubber_mobile/models/dub_models.dart';
import 'package:khmer_dubber_mobile/models/srt_models.dart';
import 'package:khmer_dubber_mobile/services/dubbing/gemini_translation_service.dart';
import 'package:khmer_dubber_mobile/services/dubbing/srt_parser.dart';
import 'package:khmer_dubber_mobile/services/dubbing/tts_segment_service.dart';

void main() {
  group('cleanText', () {
    test('strips invisible characters Gemini injects', () {
      const dirty = 'ស្វាមកដល់មកមក﻿­ចុះ';
      final cleaned = SrtParser.cleanText(dirty);

      expect(cleaned, 'ស្វាមកដល់មកមកចុះ');
      expect(cleaned.contains('﻿'), isFalse);
      expect(cleaned.contains('­'), isFalse);
    });

    test('leaves ordinary Khmer text untouched', () {
      const clean = '[F] ផ្លែស្រកានាគនេះពោពេញទៅដោយសំរាម។';
      expect(SrtParser.cleanText(clean), clean);
    });
  });

  group('normalizeTimestamp', () {
    test('converts colon-separated milliseconds to a comma', () {
      expect(SrtParser.normalizeTimestamp('00:00:01:500'), '00:00:01,500');
    });

    test('keeps an already valid timestamp unchanged', () {
      expect(SrtParser.normalizeTimestamp('00:01:23,456'), '00:01:23,456');
    });

    test('accepts fractional seconds', () {
      expect(SrtParser.normalizeTimestamp('00:00:01.750'), '00:00:01,750');
    });

    test('zero-pads short milliseconds the same way pysrt does', () {
      // Mirrors the reference Python's `ms.zfill(3)[:3]`, which left-pads to
      // width 3: both "5" and "05" become "005".
      expect(SrtParser.normalizeTimestamp('00:00:01,5'), '00:00:01,005');
      expect(SrtParser.normalizeTimestamp('00:00:01,05'), '00:00:01,005');
      // Anything longer is truncated to the first three digits.
      expect(SrtParser.normalizeTimestamp('00:00:01,1500'), '00:00:01,150');
    });

    test('shifts hours down into minutes (pysrt-style fix)', () {
      // 1 hour 2 minutes 3 seconds -> 00:62:03,000
      expect(SrtParser.normalizeTimestamp('01:02:03,000'), '00:62:03,000');
    });

    test('clamps out-of-range seconds', () {
      expect(SrtParser.normalizeTimestamp('00:00:75,000'), '00:00:59,000');
    });

    test('normalizes stray spacing', () {
      expect(SrtParser.normalizeTimestamp(' 00:00:04 : 500 '), '00:00:04,500');
    });
  });

  group('fixTimestamps', () {
    test('rewrites every timestamp line in a document', () {
      const input = '1\n00:00:00:000 --> 00:00:01:899\n[F] ផ្លែស្រកា';
      expect(SrtParser.fixTimestamps(input),
          contains('00:00:00,000 --> 00:00:01,899'));
    });
  });

  group('fixBlankLines', () {
    test('collapses multiple blank lines to exactly one', () {
      const input = '1\n00:00:00,000 --> 00:00:01,000\nA\n\n\n\n\n2\n'
          '00:00:01,000 --> 00:00:02,000\nB';
      expect(
          SrtParser.fixBlankLines(input),
          '1\n00:00:00,000 --> 00:00:01,000\nA\n\n'
          '2\n00:00:01,000 --> 00:00:02,000\nB');
    });

    test('normalizes CRLF line endings', () {
      const input = '1\r\n00:00:00,000 --> 00:00:01,000\r\nA\r\n\r\n'
          '2\r\n00:00:01,000 --> 00:00:02,000\r\nB';
      expect(SrtParser.fixBlankLines(input).contains('\r'), isFalse);
    });

    test('returns empty for blank input', () {
      expect(SrtParser.fixBlankLines('   \n\n  '), isEmpty);
    });
  });

  group('clean', () {
    test('removes markdown fences Gemini wraps the document in', () {
      const input = '```srt\n1\n00:00:00,000 --> 00:00:01,000\n[M] ស្វា\n```';
      final cleaned = SrtParser.clean(input);

      expect(cleaned.contains('```'), isFalse);
      expect(cleaned, startsWith('1\n'));
      expect(cleaned.trim(), endsWith('[M] ស្វា'));
    });
  });

  group('splitGenderTag', () {
    test('detects male and female tags', () {
      final male = SrtParser.splitGenderTag('[M] Hello');
      expect(male.gender, SpeakerGender.male);
      expect(male.text, 'Hello');

      final female = SrtParser.splitGenderTag('[F] ផ្លែស្រកា');
      expect(female.gender, SpeakerGender.female);
      expect(female.text, 'ផ្លែស្រកា');
    });

    test('accepts long-form tags case-insensitively', () {
      expect(SrtParser.splitGenderTag('[Male] hi').gender, SpeakerGender.male);
      expect(
          SrtParser.splitGenderTag('[FEMALE] hi').gender, SpeakerGender.female);
    });

    test('reports unknown when the tag is missing', () {
      final result = SrtParser.splitGenderTag('No tag here');
      expect(result.gender, SpeakerGender.unknown);
      expect(result.text, 'No tag here');
    });
  });

  group('parse', () {
    test('parses the sample SRT from the brief', () {
      const sample = '''
1
00:00:00,000 --> 00:00:01,899
[F] ផ្លែស្រកានាគនេះពោពេញទៅដោយសំរាម។

2
00:00:01,899 --> 00:00:04,500
[F] ម្ចាស់របស់វាសង្សថាឆ្កគបានលួចស៊ី។

3
00:00:04,500 --> 00:00:06,000
[F] ឆ្កគបានបដិសេធយ៉ាងដាច់អហង្ការ។
''';
      final entries = SrtParser.parse(sample);

      expect(entries.length, 3);
      expect(entries[0].index, 1);
      expect(entries[0].startSeconds, 0.0);
      expect(entries[0].endSeconds, closeTo(1.899, 0.001));
      expect(entries[0].gender, SpeakerGender.female);
      expect(
        entries[0].text,
        'ផ្លែស្រកានាគនេះពោពេញទៅដោយសំរាម។',
      );
      expect(entries[2].startSeconds, closeTo(4.5, 0.001));
      expect(entries[2].endSeconds, closeTo(6.0, 0.001));
    });

    test('skips blocks without a readable timestamp', () {
      const input = 'not a cue\n\n'
          '1\n00:00:00,000 --> 00:00:01,000\n[M] ស្វា';
      final entries = SrtParser.parse(input);

      expect(entries.length, 1);
      expect(entries.single.text, 'ស្វា');
    });

    test('swaps a cue whose end precedes its start', () {
      const input = '1\n00:00:05,000 --> 00:00:02,000\n[M] ស្វា';
      final entry = SrtParser.parse(input).single;

      expect(entry.startSeconds, closeTo(2.0, 0.001));
      expect(entry.endSeconds, closeTo(5.0, 0.001));
    });

    test('gives a zero-length cue a minimum slot', () {
      const input = '1\n00:00:03,000 --> 00:00:03,000\n[M] ស្វា';
      expect(SrtParser.parse(input).single.slotDuration, greaterThan(0));
    });

    test('drops cues whose text is only a gender tag', () {
      const input = '1\n00:00:00,000 --> 00:00:01,000\n[M]\n\n'
          '2\n00:00:01,000 --> 00:00:02,000\n[M] ស្វា';
      final entries = SrtParser.parse(input);

      expect(entries.length, 1);
      expect(entries.single.index, 2);
    });

    test('joins multi-line cue bodies', () {
      const input = '1\n00:00:00,000 --> 00:00:02,000\n[M] កុំ\nរួច';
      expect(SrtParser.parse(input).single.text, 'កុំ រួច');
    });

    test('tolerates a document that still uses colon milliseconds', () {
      const raw = '1\n00:00:00:000 --> 00:00:01:899\n[M] ស្វា';
      final entries = SrtParser.parse(SrtParser.clean(raw));

      expect(entries.single.endSeconds, closeTo(1.899, 0.001));
    });
  });

  group('resolveModelId', () {
    test('maps Settings labels to API model ids', () {
      expect(GeminiTranslationService.resolveModelId('Gemini 2.5 Flash'),
          'gemini-2.5-flash');
      expect(GeminiTranslationService.resolveModelId('Gemini 1.5 Pro'),
          'gemini-1.5-pro');
    });

    test('passes through an already-valid id', () {
      expect(GeminiTranslationService.resolveModelId('gemini-2.0-flash'),
          'gemini-2.0-flash');
    });

    test('falls back to a default for an unknown label', () {
      expect(GeminiTranslationService.resolveModelId('Something Else'),
          'gemini-2.5-flash');
    });
  });

  group('mimeTypeFor', () {
    test('maps extensions to Gemini mime types', () {
      expect(GeminiTranslationService.mimeTypeFor('a.wav'), 'audio/wav');
      expect(GeminiTranslationService.mimeTypeFor('a.mp3'), 'audio/mpeg');
      expect(GeminiTranslationService.mimeTypeFor('a.m4a'), 'audio/aac');
      // Unknown extensions fall back to WAV, which is what the pipeline writes.
      expect(GeminiTranslationService.mimeTypeFor('a.bin'), 'audio/wav');
    });
  });

  group('TtsSegmentService', () {
    test('auto-cast maps gender to the matching Khmer neural voice', () {
      expect(
        TtsSegmentService.resolveVoiceId(
          selectedVoice: VoiceProfile.autoCast,
          gender: SpeakerGender.male,
        ),
        VoiceProfile.pisethNeural.id,
      );
      expect(
        TtsSegmentService.resolveVoiceId(
          selectedVoice: VoiceProfile.autoCast,
          gender: SpeakerGender.female,
        ),
        VoiceProfile.sreymomNeural.id,
      );
    });

    test('auto-cast falls back to the male voice for untagged lines', () {
      expect(
        TtsSegmentService.resolveVoiceId(
          selectedVoice: VoiceProfile.autoCast,
          gender: SpeakerGender.unknown,
        ),
        VoiceProfile.pisethNeural.id,
      );
    });

    test('an explicit single voice overrides the detected gender', () {
      expect(
        TtsSegmentService.resolveVoiceId(
          selectedVoice: VoiceProfile.sreymomNeural,
          gender: SpeakerGender.male,
        ),
        VoiceProfile.sreymomNeural.id,
      );
    });

    test('formats the Edge TTS pitch and rate strings', () {
      expect(TtsSegmentService.formatPitch(0), '+0Hz');
      expect(TtsSegmentService.formatPitch(5), '+5Hz');
      expect(TtsSegmentService.formatPitch(-3), '-3Hz');

      expect(TtsSegmentService.formatEdgeRate(1.0), '+0%');
      expect(TtsSegmentService.formatEdgeRate(1.05), '+5%');
      expect(TtsSegmentService.formatEdgeRate(0.8), '-20%');
    });
  });

  group('DubbingSegment.calculatedSpeed', () {
    DubbingSegment build(double duration, double slot) => DubbingSegment(
          audioPath: 'a.mp3',
          startSeconds: 0,
          durationSeconds: duration,
          targetSlotDuration: slot,
          gender: SpeakerGender.male,
        );

    test('leaves speech that already fits alone', () {
      expect(build(2.0, 4.0).calculatedSpeed, 1.0);
    });

    test('stretches speech that overruns its slot', () {
      // 6s of speech in a 3s slot -> 2x.
      expect(build(6.0, 3.0).calculatedSpeed, 2.0);
    });

    test('is 1.0 when the slot is degenerate', () {
      expect(build(5.0, 0).calculatedSpeed, 1.0);
    });
  });
}
