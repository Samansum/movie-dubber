/// Outcome of a license check performed against the `licenses` collection.
///
/// Every value except [valid] and [networkError] means the stored license can no
/// longer be used and the user has to enter a different key.
enum LicenseResult {
  /// The key exists, is not revoked and is bound to this device.
  valid,

  /// No document exists for the entered key.
  invalid,

  /// The key exists but has been flagged as revoked.
  revoked,

  /// The key is already bound to a different device id.
  usedByOther,

  /// Firestore could not be reached.
  ///
  /// This is deliberately *not* treated as a rejection: a flaky connection must
  /// never lock a paying user out of the app.
  networkError,
}

/// User-facing copy for a [LicenseResult].
///
/// Lives next to the enum so a new outcome cannot be added without deciding what
/// the user is told about it.
extension LicenseResultMessage on LicenseResult {
  String get message {
    switch (this) {
      case LicenseResult.valid:
        return 'License activated';
      case LicenseResult.invalid:
        return 'Invalid license key';
      case LicenseResult.revoked:
        return 'This license has been revoked';
      case LicenseResult.usedByOther:
        return 'This key is already used on another device';
      case LicenseResult.networkError:
        return 'No internet connection, please try again';
    }
  }

  /// Whether this outcome means the stored license must be thrown away.
  ///
  /// [networkError] is excluded on purpose — see [LicenseResult.networkError].
  bool get isFatal {
    switch (this) {
      case LicenseResult.valid:
      case LicenseResult.networkError:
        return false;
      case LicenseResult.invalid:
      case LicenseResult.revoked:
      case LicenseResult.usedByOther:
        return true;
    }
  }
}