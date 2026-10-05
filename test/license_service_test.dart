import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_dubber_mobile/services/license/license_result.dart';
import 'package:khmer_dubber_mobile/services/license/license_service.dart';
import 'package:khmer_dubber_mobile/services/license/license_store.dart';

/// In-memory stand-in for `flutter_secure_storage`, so license tests need no
/// platform channels.
class FakeLicenseStore implements LicenseStore {
  FakeLicenseStore({this.code, this.lastVerifiedAt});

  String? code;
  int? lastVerifiedAt;

  int clearCalls = 0;

  @override
  Future<String?> readCode() async => code;

  @override
  Future<int?> readLastVerifiedAt() async => lastVerifiedAt;

  @override
  Future<void> writeCode(String code, DateTime verifiedAt) async {
    this.code = code;
    lastVerifiedAt = verifiedAt.toUtc().millisecondsSinceEpoch;
  }

  @override
  Future<void> writeLastVerifiedAt(DateTime verifiedAt) async {
    lastVerifiedAt = verifiedAt.toUtc().millisecondsSinceEpoch;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    code = null;
    lastVerifiedAt = null;
  }
}

const String kKey = 'KD-7F3A9C21-B84E55D0';

void main() {
  late FakeFirebaseFirestore firestore;
  late String deviceId;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    deviceId = 'device-uid-1';
  });

  LicenseService buildService(
    FakeLicenseStore store, {
    String? uid = 'device-uid-1',
    bool offline = false,
  }) {
    return LicenseService(
      store: store,
      firestore: firestore,
      deviceIdResolver: () async {
        if (offline) throw Exception('network unreachable');
        return uid;
      },
    );
  }

  /// Seeds a license document. `note` is present to mirror the real schema and
  /// prove the service ignores unknown fields.
  Future<void> seed(
    String key, {
    bool revoked = false,
    String? boundDevice,
  }) async {
    await firestore.collection('licenses').doc(key).set({
      'revoked': revoked,
      'deviceId': boundDevice,
      'note': 'ignore me',
    });
  }

  group('activate', () {
    test('missing document is invalid and stores nothing', () async {
      final store = FakeLicenseStore();
      final service = buildService(store);

      final result = await service.activate('KD-NOPE-0000-0000');

      expect(result, LicenseResult.invalid);
      expect(result.message, 'Invalid license key');
      // A rejected key must never be persisted, or the device would look
      // licensed on the next launch.
      expect(store.code, isNull);
    });

    test('an empty key is rejected without touching Firestore', () async {
      final store = FakeLicenseStore();
      final service = buildService(store);

      expect(await service.activate('   '), LicenseResult.invalid);
      expect(store.code, isNull);
    });

    test('revoked key is rejected and never stored', () async {
      await seed(kKey, revoked: true);
      final store = FakeLicenseStore();
      final service = buildService(store);

      final result = await service.activate(kKey);

      expect(result, LicenseResult.revoked);
      expect(result.message, 'This license has been revoked');
      expect(store.code, isNull);
    });

    test('unclaimed key is claimed for this device and stored', () async {
      await seed(kKey);
      final store = FakeLicenseStore();
      final service = buildService(store);

      final result = await service.activate(kKey);

      expect(result, LicenseResult.valid);
      // The document now binds to this device...
      final doc = await firestore.collection('licenses').doc(kKey).get();
      expect(doc.get('deviceId'), deviceId);
      expect(doc.get('activatedDate'), isNotNull);
      // ...and the key is persisted for the next cold start.
      expect(store.code, kKey);
      expect(store.lastVerifiedAt, isNotNull);
    });

    test('key already bound to this device stays valid', () async {
      await seed(kKey, boundDevice: deviceId);
      final store = FakeLicenseStore();
      final service = buildService(store);

      expect(await service.activate(kKey), LicenseResult.valid);
      expect(store.code, kKey);
    });

    test('key bound to another device is rejected as usedByOther', () async {
      await seed(kKey, boundDevice: 'some-other-device');
      final store = FakeLicenseStore();
      final service = buildService(store);

      final result = await service.activate(kKey);

      expect(result, LicenseResult.usedByOther);
      expect(result.message, 'This key is already used on another device');
      // The original binding must not be stolen.
      final doc = await firestore.collection('licenses').doc(kKey).get();
      expect(doc.get('deviceId'), 'some-other-device');
      expect(store.code, isNull);
    });

    test('input is trimmed and upper-cased before the lookup', () async {
      await seed(kKey);
      final store = FakeLicenseStore();
      final service = buildService(store);

      final result = await service.activate('  kd-7f3a9c21-b84e55d0  ');

      expect(result, LicenseResult.valid);
      expect(store.code, kKey);
    });

    test('a failed lookup reports networkError and stores nothing', () async {
      await seed(kKey);
      final store = FakeLicenseStore();
      final service = buildService(store, offline: true);

      final result = await service.activate(kKey);

      expect(result, LicenseResult.networkError);
      expect(result.message, 'No internet connection, please try again');
      expect(store.code, isNull);
    });
  });

  group('verifyIfDue', () {
    test('does nothing when no license is stored', () async {
      final store = FakeLicenseStore();
      final service = buildService(store);

      expect(await service.verifyIfDue(), isNull);
      expect(store.clearCalls, 0);
    });

    test('sends no request when the last check is under 24h old', () async {
      await seed(kKey, boundDevice: deviceId);
      // Captured once so the assertion compares against the same instant that
      // was seeded — recomputing `now` would drift by a few milliseconds.
      final stamp = DateTime.now()
          .subtract(const Duration(hours: 2))
          .toUtc()
          .millisecondsSinceEpoch;
      final store = FakeLicenseStore(code: kKey, lastVerifiedAt: stamp);
      final service = buildService(store);

      // Reopening the app within the day must trust the stored state.
      expect(await service.verifyIfDue(), isNull);
      expect(store.clearCalls, 0);
      // The timestamp is untouched, so it stays fresh.
      expect(store.lastVerifiedAt, stamp);
    });

    test('two launches within a day produce no Firestore request', () async {
      await seed(kKey, boundDevice: deviceId);
      final store = FakeLicenseStore(code: kKey, lastVerifiedAt: 0);
      final service = buildService(store);

      // First launch is due and performs the single permitted check.
      expect(await service.verifyIfDue(), LicenseResult.valid);
      final stampAfterFirst = store.lastVerifiedAt;

      // Second launch seconds later must not hit Firestore again.
      expect(await service.verifyIfDue(), isNull);
      expect(await service.verifyIfDue(), isNull);
      expect(store.lastVerifiedAt, stampAfterFirst);
      expect(store.clearCalls, 0);
    });

    test('revalidates and refreshes the timestamp once 24h have passed',
        () async {
      await seed(kKey, boundDevice: deviceId);
      final store = FakeLicenseStore(
        code: kKey,
        lastVerifiedAt: DateTime.now()
            .subtract(const Duration(days: 2))
            .toUtc()
            .millisecondsSinceEpoch,
      );
      final service = buildService(store);

      expect(await service.verifyIfDue(), LicenseResult.valid);

      // Refreshed to roughly now.
      final refreshed =
          DateTime.fromMillisecondsSinceEpoch(store.lastVerifiedAt!, isUtc: true);
      expect(
        DateTime.now().toUtc().difference(refreshed).inMinutes.abs(),
        lessThan(5),
      );
      expect(store.clearCalls, 0);
    });

    test('a deleted document invalidates and clears the stored license',
        () async {
      final store = FakeLicenseStore(code: kKey, lastVerifiedAt: 0);
      final service = buildService(store);

      expect(await service.verifyIfDue(), LicenseResult.invalid);
      expect(store.code, isNull);
      expect(store.lastVerifiedAt, isNull);
    });

    test('a revoked key clears the stored license', () async {
      await seed(kKey, revoked: true, boundDevice: deviceId);
      final store = FakeLicenseStore(code: kKey, lastVerifiedAt: 0);
      final service = buildService(store);

      expect(await service.verifyIfDue(), LicenseResult.revoked);
      expect(store.code, isNull);
    });

    test('a key now bound elsewhere clears the stored license', () async {
      await seed(kKey, boundDevice: 'a-different-device');
      final store = FakeLicenseStore(code: kKey, lastVerifiedAt: 0);
      final service = buildService(store);

      expect(await service.verifyIfDue(), LicenseResult.usedByOther);
      expect(store.code, isNull);
    });

    test('offline keeps the license and does not refresh the timestamp',
        () async {
      await seed(kKey, boundDevice: deviceId);
      final stamp = DateTime.now()
          .subtract(const Duration(days: 3))
          .toUtc()
          .millisecondsSinceEpoch;
      final store = FakeLicenseStore(code: kKey, lastVerifiedAt: stamp);
      final service = buildService(store, offline: true);

      // Never lock a paying user out because of a dropped connection...
      expect(await service.verifyIfDue(), LicenseResult.networkError);
      expect(store.code, kKey);
      expect(store.clearCalls, 0);
      // ...and leave the stale stamp so the next launch retries.
      expect(store.lastVerifiedAt, stamp);
    });

    test('a future timestamp is treated as due and rechecked', () async {
      await seed(kKey, boundDevice: deviceId);
      final store = FakeLicenseStore(
        code: kKey,
        lastVerifiedAt: DateTime.now()
            .add(const Duration(days: 2))
            .toUtc()
            .millisecondsSinceEpoch,
      );
      final service = buildService(store);

      // A clock change must not freeze checks forever.
      expect(await service.verifyIfDue(), LicenseResult.valid);
    });
  });

  group('LicenseResult', () {
    test('only valid and networkError are non-fatal', () {
      expect(LicenseResult.valid.isFatal, isFalse);
      expect(LicenseResult.networkError.isFatal, isFalse);
      expect(LicenseResult.invalid.isFatal, isTrue);
      expect(LicenseResult.revoked.isFatal, isTrue);
      expect(LicenseResult.usedByOther.isFatal, isTrue);
    });
  });
}