/// Where the app currently stands with respect to licensing.
///
/// [unknown] is the brief window between launch and the first secure-storage
/// read. The app UI renders during it — otherwise a licensed user would see
/// the activation gate flash on every launch — while `AppState.isLicenseBlocked`
/// keeps the dubbing pipeline blocked until the read resolves.
enum LicenseStatus {
  /// The stored license has not been read yet: the UI renders, the pipeline
  /// stays blocked.
  unknown,

  /// A license code is stored and either verified or not yet due for a check.
  valid,

  /// The app is gated until a usable key is entered.
  locked,
}