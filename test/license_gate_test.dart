import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_dubber_mobile/services/license/license_result.dart';
import 'package:khmer_dubber_mobile/widgets/license_gate.dart';

/// Verifies the gate really is blocking: no input reaches the app underneath,
/// the key field normalises input, and failures are reported in place.
void main() {
  Future<void> pumpGate(
    WidgetTester tester, {
    required Future<LicenseResult> Function(String) onActivate,
    String? lockReason,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LicenseGate(
          lockReason: lockReason,
          onActivate: onActivate,
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('UNDERNEATH'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the app underneath cannot be tapped while locked',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: LicenseGate(
          onActivate: (_) async => LicenseResult.invalid,
          child: Builder(
            builder: (context) => Scaffold(
              body: GestureDetector(
                onTap: () => taps++,
                child: const Center(child: Text('UNDERNEATH')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('UNDERNEATH'), warnIfMissed: false);
    await tester.pump();

    expect(taps, 0, reason: 'AbsorbPointer must swallow taps while locked');
  });

  testWidgets('shows the reason the app was locked', (tester) async {
    await pumpGate(
      tester,
      lockReason: 'Your license is no longer valid. '
          'Enter a valid key to continue.',
      onActivate: (_) async => LicenseResult.invalid,
    );

    expect(
      find.textContaining('no longer valid'),
      findsOneWidget,
    );
  });

  testWidgets('a rejected key is reported inline and the gate stays up',
      (tester) async {
    await pumpGate(
      tester,
      onActivate: (_) async => LicenseResult.usedByOther,
    );

    await tester.enterText(find.byType(TextField), 'KD-TEST');
    await tester.tap(find.text('Activate'));
    await tester.pumpAndSettle();

    expect(find.text('This key is already used on another device'),
        findsOneWidget);
    // Still gated — the dialog must not close on failure.
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('the submitted key is trimmed and upper-cased',
      (tester) async {
    String? submitted;
    await pumpGate(
      tester,
      onActivate: (code) async {
        submitted = code;
        return LicenseResult.invalid;
      },
    );

    await tester.enterText(find.byType(TextField), '  kd-abc-123  ');
    await tester.tap(find.text('Activate'));
    await tester.pumpAndSettle();

    expect(submitted, 'KD-ABC-123');
  });

  testWidgets('an empty submission is rejected without calling the service',
      (tester) async {
    var calls = 0;
    await pumpGate(
      tester,
      onActivate: (_) async {
        calls++;
        return LicenseResult.valid;
      },
    );

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Activate'));
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(find.text('Enter your license key to continue.'), findsOneWidget);
  });

  testWidgets('the back button cannot dismiss the gate', (tester) async {
    await pumpGate(
      tester,
      onActivate: (_) async => LicenseResult.invalid,
    );

    // PopScope(canPop: false) is what makes the system back button inert.
    // Located by widget predicate rather than by exact generic type, which
    // varies between Flutter versions.
    final popScope = tester.widget<PopScope<dynamic>>(
      find.byWidgetPredicate(
        (widget) => widget is PopScope && !widget.canPop,
      ),
    );
    expect(popScope.canPop, isFalse);
  });
}