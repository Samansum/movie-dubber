import 'dart:async';

import 'package:flutter/widgets.dart';

import '../app_state.dart';
import 'license_result.dart';
import 'license_service.dart';
import 'license_status.dart';
import 'license_store.dart';

/// Owns the licensing lifecycle and keeps [AppState.licenseStatus] in sync.
///
/// Responsibilities, in order:
///  * decide whether the app may be used, from secure storage alone;
///  * run the once-a-day Firestore check at most once per 24h, including when
///    the app returns to the foreground;
///  * flip the app back to locked when a license stops being valid.
///
/// The check is deliberately fire-and-forget from the caller's point of view: a
/// licensed user is let in immediately and is never shown a spinner for it.
class LicenseController with WidgetsBindingObserver {
  LicenseController({
    required this.service,
    required this.state,
    this.store,
  });

  /// Validation and the daily check.
  final LicenseService service;

  /// App-wide state whose [AppState.licenseStatus] this controller drives.
  final AppState state;

  /// Secure storage handle, used for the cold-start read. Defaults to the
  /// service's own store when it is a [SecureLicenseStore].
  final LicenseStore? store;

  /// Guards against two overlapping checks — e.g. a foreground check starting
  /// while the cold-start check is still in flight.
  bool _checkInFlight = false;

  LicenseStore get _store => store ?? SecureLicenseStore();

  /// Copy shown when a stored license stopped being valid.
  static const String reactivationReason =
      'Your license is no longer valid. Enter a valid key to continue.';

  /// Reads the stored license and resolves the app to its status.
  ///
  /// Deliberately local-only: it settles the gate decision without waiting on
  /// Firebase or the network, so the launcher can run it before
  /// `Firebase.initializeApp()`. The Firestore verification is the separate
  /// [checkOnForeground] step, run once Firebase is ready.
  ///
  /// A stored key is enough to let the user in — it is trusted until proven
  /// otherwise — so a licensed user never waits on the network to start.
  Future<void> bootstrap() async {
    final code = await _readStoredCode();
    if (code == null || code.isEmpty) {
      state.setLicenseStatus(LicenseStatus.locked);
      return;
    }

    // Let the user straight in — the stored key is trusted until proven
    // otherwise, so a licensed user never waits on the network to start.
    state.setLicenseStatus(LicenseStatus.valid);
  }

  /// Runs the daily check if one is due, and locks the app when it fails.
  ///
  /// Called at launch — immediately after Firebase initialises — and whenever
  /// the app returns to the foreground. Safe to call repeatedly: overlapping
  /// invocations are dropped and a not-due check performs no I/O at all.
  Future<void> checkOnForeground() => _runBackgroundCheck();

  /// Raw Firebase detail for the most recent failure, for the gate to display.
  String? get lastErrorDetail => service.lastErrorDetail;

  /// Submits [code] from the activation gate.
  ///
  /// Only [LicenseResult.valid] moves the app out of the locked state; every
  /// other outcome is returned so the gate can explain it in place.
  Future<LicenseResult> activate(String code) async {
    final result = await service.activate(code);
    if (result == LicenseResult.valid) {
      state.setLicenseStatus(LicenseStatus.valid);
    }
    return result;
  }

  /// Verifies the stored license when due and applies the outcome.
  Future<void> _runBackgroundCheck() async {
    if (_checkInFlight) return;
    _checkInFlight = true;
    try {
      final result = await service.verifyIfDue();
      // `null` means nothing was due (or nothing stored) — the current status
      // already reflects reality, so leave it alone.
      if (result == null) return;

      switch (result) {
        case LicenseResult.valid:
          state.setLicenseStatus(LicenseStatus.valid);
        case LicenseResult.networkError:
          // Offline must never lock a paying user out, and the timestamp is
          // deliberately not refreshed, so the next launch retries.
          debugPrint('[License] Background check skipped: offline.');
        case LicenseResult.invalid:
        case LicenseResult.revoked:
        case LicenseResult.usedByOther:
          // The stored values are already cleared by the service; re-gate with
          // an explanation instead of dropping the user on a blank key field.
          debugPrint('[License] Background check failed: ${result.name}');
          state.setLicenseStatus(
            LicenseStatus.locked,
            reason: reactivationReason,
          );
      }
    } catch (error) {
      // Never let an unexpected error lock the app: keep the current status.
      debugPrint('[License] Background check error: $error');
    } finally {
      _checkInFlight = false;
    }
  }

  /// Reads the stored code, treating a storage failure as "no license".
  Future<String?> _readStoredCode() async {
    try {
      final code = await _store.readCode();
      return code?.trim().toUpperCase();
    } catch (error) {
      debugPrint('[License] Could not read stored license: $error');
      return null;
    }
  }

  /// Starts observing app lifecycle changes for foreground re-checks.
  void start() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Stops observing lifecycle changes.
  void stop() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Returning to the foreground is the moment an app left open for days must
    // re-check; `_runBackgroundCheck` still short-circuits when not due.
    if (state == AppLifecycleState.resumed) {
      unawaited(_runBackgroundCheck());
    }
  }
}