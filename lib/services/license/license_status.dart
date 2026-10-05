/// Where the app currently stands with respect to licensing.
///
/// [unknown] is the brief window between launch and the first secure-storage
/// read; it is treated as *blocked* so no screen is ever reachable before the
/// stored license has been looked at.
enum LicenseStatus {
  /// The stored license has not been read yet.
  unknown,

  /// A license code is stored and either verified or not yet due for a check.
  valid,

  /// The app is gated until a usable key is entered.
  locked,
}