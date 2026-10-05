import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/license/license_result.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Full-screen gate shown whenever the app is license-locked.
///
/// Rendered as a [Stack] overlay above the whole app rather than via
/// `showDialog` so the lock is a property of the root widget tree: no route,
/// screen or floating element can sit on top of it or receive input. The
/// [AbsorbPointer] makes the app underneath untappable and the [PopScope] stops
/// the system back button from dismissing it.
class LicenseGate extends StatefulWidget {
  final Widget child;

  /// Invoked when the user submits a key. Resolves to the outcome, which is
  /// shown inline; the gate only lets the user through on
  /// [LicenseResult.valid].
  final Future<LicenseResult> Function(String code) onActivate;

  /// Copy explaining why the app is locked. `null` on a first-run activation.
  final String? lockReason;

  const LicenseGate({
    super.key,
    required this.child,
    required this.onActivate,
    this.lockReason,
  });

  @override
  State<LicenseGate> createState() => _LicenseGateState();
}

class _LicenseGateState extends State<LicenseGate> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;

    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Enter your license key to continue.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await widget.onActivate(code);

    // The gate can be torn down by an in-flight request (the app moved to
    // `valid`, or the widget was disposed), so never touch the tree afterwards.
    if (!mounted) return;

    setState(() {
      _loading = false;
      // On success the gate disappears, so there is nothing left to report;
      // every other outcome keeps the gate up with a reason.
      _error = result == LicenseResult.valid ? null : result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // The lock is not dismissible: back does nothing at all.
      canPop: false,
      child: Stack(
        children: [
          // The app underneath stays mounted but receives no pointer events.
          AbsorbPointer(child: widget.child),

          // Opaque scrim so nothing below is visible or legible.
          const Positioned.fill(
            child: ColoredBox(color: AppColors.canvasBase),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _LicensePanel(
                  controller: _controller,
                  focusNode: _focusNode,
                  loading: _loading,
                  error: _error,
                  lockReason: widget.lockReason,
                  onSubmit: _submit,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The card contents of the lock screen.
class _LicensePanel extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final String? error;
  final String? lockReason;
  final VoidCallback onSubmit;

  const _LicensePanel({
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.error,
    required this.lockReason,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    // The gate is rendered above the Navigator by `MaterialApp.builder`, so it
    // sits outside the Scaffold's Material — an explicit `Material` is
    // required for the TextField's ink/underline and text selection to work.
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppColors.surfaceCardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: AppColors.primaryGlow,
        ),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: AppColors.primaryGlow,
              ),
              child: const Icon(
                Icons.vpn_key_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Activate CineDub AI',
            textAlign: TextAlign.center,
            style: AppTypography.headlineMd,
          ),
          const SizedBox(height: 8),
          Text(
            lockReason ??
                'Enter the license key you received to activate this device.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: 24),

          TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: !loading,
            autofocus: true,
            textInputAction: TextInputAction.go,
            autocorrect: false,
            // Keys are issued in caps; the value is normalised on submit, so
            // showing it as typed keeps a pasted lowercase key recognisable.
            textCapitalization: TextCapitalization.characters,
            style: AppTypography.bodyMd,
            inputFormatters: [LengthLimitingTextInputFormatter(64)],
            decoration: InputDecoration(
              labelText: 'License key',
              hintText: 'KD-XXXX-XXXX-XXXX',
              errorText: error,
            ),
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 20),

          // Disabled while loading so a slow transaction cannot be fired twice
          // and end up claiming two different keys.
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: loading ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimaryContainer,
                disabledBackgroundColor: AppColors.surfaceContainerHigh,
                disabledForegroundColor: AppColors.outline,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimaryContainer,
                      ),
                    )
                  : const Text('Activate', style: AppTypography.labelLg),
            ),
          ),
        ],
        ),
      ),
    );
  }
}