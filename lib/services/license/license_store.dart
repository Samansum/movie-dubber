import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistence for the two values that let a license survive a restart.
///
/// Declared as an interface so the license logic can be unit-tested against an
/// in-memory map, and so a future migration off `flutter_secure_storage` does
/// not ripple into [LicenseService].
abstract class LicenseStore {
  /// The stored license key, or `null` when the app has never been activated.
  Future<String?> readCode();

  /// UTC epoch milliseconds of the last *successful* verification, or `null`
  /// when the license has never been checked.
  Future<int?> readLastVerifiedAt();

  /// Persists [code] and stamps the verification time to [verifiedAt].
  Future<void> writeCode(String code, DateTime verifiedAt);

  /// Stamps the last verification time without touching the stored code.
  Future<void> writeLastVerifiedAt(DateTime verifiedAt);

  /// Drops both values, returning the device to the "never activated" state.
  Future<void> clear();
}

/// [LicenseStore] backed by the platform keystore via `flutter_secure_storage`.
///
/// The key is not a secret in the cryptographic sense — it is a seat on one
/// device — but it is the only thing standing between a free install and the
/// whole Gemini/FFmpeg pipeline, so it does not belong in plain
/// `SharedPreferences` where a device backup can read it.
class SecureLicenseStore implements LicenseStore {
  SecureLicenseStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Key holding the license code entered by the user.
  static const String codeKey = 'license_code';

  /// Key holding the UTC epoch milliseconds of the last successful check.
  static const String lastVerifiedKey = 'license_last_verified_at';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readCode() => _storage.read(key: codeKey);

  @override
  Future<int?> readLastVerifiedAt() async {
    final raw = await _storage.read(key: lastVerifiedKey);
    // A corrupted or hand-edited value must degrade to "never verified" so the
    // next launch performs a check, rather than throwing and blocking the app.
    return int.tryParse(raw ?? '');
  }

  @override
  Future<void> writeCode(String code, DateTime verifiedAt) async {
    await _storage.write(key: codeKey, value: code);
    await writeLastVerifiedAt(verifiedAt);
  }

  @override
  Future<void> writeLastVerifiedAt(DateTime verifiedAt) {
    return _storage.write(
      key: lastVerifiedKey,
      value: verifiedAt.toUtc().millisecondsSinceEpoch.toString(),
    );
  }

  @override
  Future<void> clear() async {
    // Scoped to the two license keys rather than `deleteAll()` so an unrelated
    // secret added later is never wiped by a license reset.
    await _storage.delete(key: codeKey);
    await _storage.delete(key: lastVerifiedKey);
  }
}