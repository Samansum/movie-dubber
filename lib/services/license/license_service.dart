import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'license_result.dart';
import 'license_store.dart';

/// How long a successful verification is trusted before Firestore is consulted
/// again.
const Duration kLicenseCheckInterval = Duration(hours: 24);

/// Whether a stored license needs to be re-checked against Firestore.
///
/// Pure and side-effect free so the daily-check policy can be unit-tested
/// without any plugin channels:
///
/// * `null` [lastVerifiedAt] (never checked, or the timestamp was corrupted)
///   is always due.
/// * Less than [interval] old is **not** due — this is what keeps opening and
///   closing the app repeatedly within a day from producing a request each time.
/// * A timestamp in the *future* means the device clock moved, so it is due
///   rather than trusted.
bool isDue({
  required DateTime now,
  required int? lastVerifiedAt,
  Duration interval = kLicenseCheckInterval,
}) {
  if (lastVerifiedAt == null) return true;

  final lastVerified =
      DateTime.fromMillisecondsSinceEpoch(lastVerifiedAt, isUtc: true);
  final elapsed = now.toUtc().difference(lastVerified);

  // A clock change can put the stamp in the future. Trusting it would stall
  // checks indefinitely, so treat the negative elapsed time as "due now".
  if (elapsed.isNegative) return true;

  return elapsed >= interval;
}

/// Validates license keys against the `licenses` collection in Firestore.
///
/// The document id *is* the key, so a key is validated with a single document
/// read. The device identity is the Firebase Anonymous Auth uid: the app signs
/// in lazily on first use and reuses that user for its whole lifetime.
class LicenseService {
  LicenseService({
    required LicenseStore store,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseFirestore Function()? firestoreFactory,
    Future<String?> Function()? deviceIdResolver,
  })  : _store = store,
        _firestore = firestore,
        _auth = auth,
        _firestoreFactory = firestoreFactory,
        _deviceIdResolver = deviceIdResolver;

  /// Collection holding one document per license key.
  static const String collectionName = 'licenses';

  final LicenseStore _store;
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;
  final FirebaseFirestore Function()? _firestoreFactory;

  /// Overrides how the device id is obtained.
  ///
  /// Production leaves this `null` and falls back to Firebase Anonymous Auth.
  /// Tests inject a fixed uid so they exercise the Firestore rules without
  /// standing up an Auth backend.
  final Future<String?> Function()? _deviceIdResolver;

  /// Resolves the Firestore instance lazily.
  ///
  /// Deferring this keeps construction side-effect free, so [LicenseService]
  /// can be built before `Firebase.initializeApp()` has finished and so tests
  /// can inject a `FakeFirebaseFirestore` without touching Firebase at all.
  FirebaseFirestore get _db =>
      _firestore ?? (_firestoreFactory?.call() ?? FirebaseFirestore.instance);

  /// Reads the stored license code, or `null` when the app was never activated.
  Future<String?> storedCode() => _store.readCode();

  /// Reads the stored last-verification timestamp in UTC epoch milliseconds.
  Future<int?> lastVerifiedAt() => _store.readLastVerifiedAt();

  /// Claims [rawCode] for this device.
  ///
  /// Runs inside a Firestore transaction so two devices racing for the same
  /// unclaimed key cannot both win: the read that decides "unclaimed" and the
  /// write that claims it happen in one atomic step.
  ///
  /// On [LicenseResult.valid] the key and the verification timestamp are
  /// persisted, so a later cold start can trust them.
  Future<LicenseResult> activate(String rawCode) async {
    final code = _normalize(rawCode);
    if (code.isEmpty) return LicenseResult.invalid;

    try {
      final deviceId = await _resolveDeviceId();
      if (deviceId == null) return LicenseResult.networkError;

      final docRef = _db.collection(collectionName).doc(code);

      final result = await _db.runTransaction<LicenseResult>((transaction) async {
        final snapshot = await transaction.get(docRef);
        final data = snapshot.data();

        // A missing document is an unknown key, not a connectivity problem.
        if (!snapshot.exists || data == null) return LicenseResult.invalid;

        if (data['revoked'] == true) return LicenseResult.revoked;

        final boundDevice = data['deviceId'] as String?;

        if (boundDevice != null) {
          // Already claimed: only the original device may keep using it.
          return boundDevice == deviceId
              ? LicenseResult.valid
              : LicenseResult.usedByOther;
        }

        // Unclaimed key — bind it to this device.
        transaction.update(docRef, <String, Object?>{
          'deviceId': deviceId,
          'activatedDate': FieldValue.serverTimestamp(),
        });
        return LicenseResult.valid;
      });

      if (result == LicenseResult.valid) {
        await _store.writeCode(code, DateTime.now());
      }
      return result;
    } catch (error) {
      return _mapError(error);
    }
  }

  /// Re-validates the stored license, but only when one is actually due.
  ///
  /// Returns `null` when there is nothing to do — either no license is stored
  /// or [isDue] says the stored state is still fresh. In that case **no
  /// Firestore request is made at all**, which is what makes repeatedly opening
  /// the app within a day free.
  ///
  /// The stored values are only cleared on a decisive rejection
  /// ([LicenseResult.isFatal]); a [LicenseResult.networkError] leaves them
  /// untouched so the check is retried on the next launch instead of locking
  /// the user out on a bad connection.
  Future<LicenseResult?> verifyIfDue({DateTime? now}) async {
    final code = _normalize(await _store.readCode() ?? '');
    if (code.isEmpty) return null;

    final at = (now ?? DateTime.now()).toUtc();
    if (!isDue(now: at, lastVerifiedAt: await _store.readLastVerifiedAt())) {
      return null;
    }

    final LicenseResult result;
    try {
      final deviceId = await _resolveDeviceId();
      if (deviceId == null) return LicenseResult.networkError;

      final snapshot = await _db.collection(collectionName).doc(code).get();
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        result = LicenseResult.invalid;
      } else if (data['revoked'] == true) {
        result = LicenseResult.revoked;
      } else if (data['deviceId'] != deviceId) {
        // Covers both "claimed by another device" and "released" (null), which
        // is as fatal as a wrong binding.
        result = LicenseResult.usedByOther;
      } else {
        result = LicenseResult.valid;
      }
    } catch (error) {
      return _mapError(error);
    }

    if (result == LicenseResult.valid) {
      // Only a confirmed pass refreshes the clock, so a flaky connection is
      // retried instead of being cached for a whole day.
      await _store.writeLastVerifiedAt(at);
    } else if (result.isFatal) {
      await _store.clear();
    }

    return result;
  }

  /// Returns the Firebase Anonymous Auth uid, signing in on first use.
  ///
  /// Returning `null` when Auth is unavailable lets callers degrade to
  /// [LicenseResult.networkError] instead of crashing on a missing plugin.
  Future<String?> _resolveDeviceId() async {
    final override = _deviceIdResolver;
    if (override != null) return override();

    final auth = _auth ?? FirebaseAuth.instance;
    final current = auth.currentUser;
    if (current != null) return current.uid;

    final credential = await auth.signInAnonymously();
    return credential.user?.uid;
  }

  /// Normalises user input into the exact document id used in Firestore.
  ///
  /// Keys are stored upper-case; trimming and upper-casing the input means a
  /// key pasted from an email still matches its document.
  static String _normalize(String raw) => raw.trim().toUpperCase();

  /// Translates a thrown Firestore/Auth error into a [LicenseResult].
  ///
  /// Anything that escapes the happy path is treated as a connectivity problem.
  /// A permission error or a transient server fault must not destroy a license
  /// the user legitimately owns.
  static LicenseResult _mapError(Object error) => LicenseResult.networkError;
}