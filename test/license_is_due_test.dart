import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_dubber_mobile/services/license/license_service.dart';

/// Covers the once-a-day policy that keeps repeated app launches from turning
/// into repeated Firestore requests.
void main() {
  group('isDue', () {
    final now = DateTime.utc(2026, 5, 10, 12);

    test('is due when nothing was ever verified', () {
      expect(isDue(now: now, lastVerifiedAt: null), isTrue);
    });

    test('is not due just under 24 hours after the last check', () {
      final last = now
          .subtract(const Duration(hours: 23, minutes: 59))
          .millisecondsSinceEpoch;

      expect(isDue(now: now, lastVerifiedAt: last), isFalse);
    });

    test('is due exactly 24 hours after the last check', () {
      final last =
          now.subtract(kLicenseCheckInterval).millisecondsSinceEpoch;

      expect(isDue(now: now, lastVerifiedAt: last), isTrue);
    });

    test('is due beyond 24 hours after the last check', () {
      final last = now
          .subtract(const Duration(hours: 24, seconds: 1))
          .millisecondsSinceEpoch;

      expect(isDue(now: now, lastVerifiedAt: last), isTrue);
    });

    test('is due when the timestamp is in the future (clock changed)', () {
      final last =
          now.add(const Duration(hours: 3)).millisecondsSinceEpoch;

      // Must NOT be trusted, otherwise a backwards clock change would freeze
      // licensing checks forever.
      expect(isDue(now: now, lastVerifiedAt: last), isTrue);
    });

    test('a local-time timestamp is compared in UTC', () {
      // The same instant expressed in local time must give the same verdict.
      final lastUtc = now.subtract(const Duration(hours: 2));
      final asLocal = lastUtc.toLocal().millisecondsSinceEpoch;

      expect(isDue(now: now, lastVerifiedAt: asLocal), isFalse);
    });

    test('honours a custom interval', () {
      final last = now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch;

      expect(
        isDue(
          now: now,
          lastVerifiedAt: last,
          interval: const Duration(hours: 1),
        ),
        isTrue,
      );
    });
  });
}