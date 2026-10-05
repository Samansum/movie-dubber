import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_dubber_mobile/services/app_state.dart';
import 'package:khmer_dubber_mobile/services/license/license_controller.dart';
import 'package:khmer_dubber_mobile/services/license/license_service.dart';
import 'package:khmer_dubber_mobile/services/license/license_status.dart';
import 'package:khmer_dubber_mobile/services/license/license_store.dart';

/// In-memory stand-in for `flutter_secure_storage`, mirroring the fake in
/// `license_service_test.dart` with an extra failure switch so the cold-start
/// read can be made to blow up.
class FakeLicenseStore implements LicenseStore {
  FakeLicenseStore({this.code, this.lastVerifiedAt});

  String? code;
  int? lastVerifiedAt;
  bool throwOnRead = false;

  @override
  Future<String?> readCode() async {
    if (throwOnRead) throw Exception('keystore unavailable');
    return code;
  }

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
    code = null;
    lastVerifiedAt = null;
  }
}

const String kKey = 'KD-7F3A9C21-B84E55D0';

/// Controller + fakes for one test; the AppState is disposed via tearDown.
class Harness {
  Harness({
    String? code,
    int? lastVerifiedAt,
    bool offline = false,
    bool throwOnRead = false,
  })  : store = FakeLicenseStore(code: code, lastVerifiedAt: lastVerifiedAt)
          ..throwOnRead = throwOnRead,
        firestore = FakeFirebaseFirestore(),
        state = AppState() {
    addTearDown(state.dispose);
    controller = LicenseController(
      service: LicenseService(
        store: store,
        firestore: firestore,
        deviceIdResolver: () async {
          if (offline) throw Exception('network unreachable');
          return 'device-uid-1';
        },
      ),
      state: state,
      store: store,
    );
  }

  final FakeLicenseStore store;
  final FakeFirebaseFirestore firestore;
  final AppState state;
  late final LicenseController controller;
}

/// Covers the launch sequence: the local read settles the gate on its own,
/// and the Firestore check is a separate step run after Firebase is ready.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bootstrap (local read, no network)', () {
    test('a stored key unlocks the app without consulting Firestore', () async {
      // lastVerifiedAt is null, so a daily check *would* be due: if bootstrap
      // still ran it, the missing Firestore document would clear the key.
      final h = Harness(code: kKey);

      await h.controller.bootstrap();

      expect(h.state.licenseStatus, LicenseStatus.valid);
      expect(h.state.showLicenseGate, isFalse);
      expect(h.store.code, kKey);
    });

    test('no stored key locks the app and mounts the gate', () async {
      final h = Harness();

      await h.controller.bootstrap();

      expect(h.state.licenseStatus, LicenseStatus.locked);
      expect(h.state.showLicenseGate, isTrue);
      // First-run lock: there is no reactivation story to tell yet.
      expect(h.state.licenseLockReason, isNull);
    });

    test('a secure-storage failure is treated as "no license"', () async {
      final h = Harness(throwOnRead: true);

      await h.controller.bootstrap();

      expect(h.state.licenseStatus, LicenseStatus.locked);
      expect(h.state.showLicenseGate, isTrue);
    });
  });

  group('checkOnForeground (the once-a-day Firestore check)', () {
    test('a passing due check keeps the app valid and refreshes the stamp',
        () async {
      final h = Harness(
        code: kKey,
        lastVerifiedAt: DateTime.now()
            .subtract(const Duration(days: 2))
            .toUtc()
            .millisecondsSinceEpoch,
      );
      await h.firestore
          .collection(LicenseService.collectionName)
          .doc(kKey)
          .set({'revoked': false, 'deviceId': 'device-uid-1'});
      await h.controller.bootstrap();

      await h.controller.checkOnForeground();

      expect(h.state.licenseStatus, LicenseStatus.valid);
      expect(h.state.showLicenseGate, isFalse);
      final refreshed = DateTime.fromMillisecondsSinceEpoch(
        h.store.lastVerifiedAt!,
        isUtc: true,
      );
      expect(
        DateTime.now().toUtc().difference(refreshed).inMinutes.abs(),
        lessThan(5),
      );
    });

    test('a rejection locks with the reactivation reason and clears the key',
        () async {
      final h = Harness(code: kKey, lastVerifiedAt: 0);
      await h.controller.bootstrap();

      await h.controller.checkOnForeground();

      expect(h.state.licenseStatus, LicenseStatus.locked);
      expect(
        h.state.licenseLockReason,
        LicenseController.reactivationReason,
      );
      expect(h.state.showLicenseGate, isTrue);
      expect(h.store.code, isNull);
    });

    test('offline never locks a paying user out', () async {
      final h = Harness(code: kKey, lastVerifiedAt: 0, offline: true);
      await h.controller.bootstrap();

      await h.controller.checkOnForeground();

      expect(h.state.licenseStatus, LicenseStatus.valid);
      expect(h.store.code, kKey);
      // The stale stamp is kept so the next launch retries.
      expect(h.store.lastVerifiedAt, 0);
    });

    test('a fresh stamp means no check is attempted at all', () async {
      // Nothing is seeded in Firestore: had a check run, it would have found
      // no document and locked the app.
      final h = Harness(
        code: kKey,
        lastVerifiedAt: DateTime.now().toUtc().millisecondsSinceEpoch,
      );
      await h.controller.bootstrap();

      await h.controller.checkOnForeground();

      expect(h.state.licenseStatus, LicenseStatus.valid);
      expect(h.store.code, kKey);
    });
  });
}