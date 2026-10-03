import 'package:flutter/material.dart';

/// Obsidian Cinema AI Color Palette for Khmer Video Dubber Studio
class AppColors {
  AppColors._();

  // Canvas & Surfaces
  static const Color canvasBase = Color(0xFF0B0F17); // Deep Obsidian
  static const Color surface = Color(0xFF0F131C);
  static const Color surfaceDim = Color(0xFF0F131C);
  static const Color surfaceBright = Color(0xFF353942);
  static const Color surfaceContainerLowest = Color(0xFF0A0E16);
  static const Color surfaceContainerLow = Color(0xFF181C24);
  static const Color surfaceContainer = Color(0xFF1C2028);
  static const Color surfaceContainerHigh = Color(0xFF262A33);
  static const Color surfaceContainerHighest = Color(0xFF31353E);
  static const Color surfaceVariant = Color(0xFF31353E);

  // Content & Neutrals
  static const Color onSurface = Color(0xFFDFE2EE); // 98% luminance slate
  static const Color onSurfaceVariant = Color(0xFFCCC3D8);
  static const Color onBackground = Color(0xFFDFE2EE);
  static const Color inverseSurface = Color(0xFFDFE2EE);
  static const Color inverseOnSurface = Color(0xFF2C3039);
  static const Color outline = Color(0xFF958DA1);
  static const Color outlineVariant = Color(0xFF4A4455);
  static const Color borderSubtle = Color(0x1AFFFFFF); // 10% white
  static const Color borderActive = Color(0x667C3AED); // 40% violet

  // Primary Signals (Electric Violet AI Compute)
  static const Color primary = Color(0xFFD2BBFF);
  static const Color primaryContainer = Color(0xFF7C3AED); // Electric Violet
  static const Color onPrimary = Color(0xFF3F008E);
  static const Color onPrimaryContainer = Color(0xFFEDE0FF);
  static const Color inversePrimary = Color(0xFF732EE4);
  static const Color primaryFixed = Color(0xFFEADDFF);
  static const Color primaryFixedDim = Color(0xFFD2BBFF);

  // Secondary Signals (Cyber Cyan Acoustics & Waveforms)
  static const Color secondary = Color(0xFF4CD7F6);
  static const Color secondaryContainer = Color(0xFF03B5D3);
  static const Color onSecondary = Color(0xFF003640);
  static const Color onSecondaryContainer = Color(0xFF00424E);
  static const Color secondaryFixed = Color(0xFFACEDFF);
  static const Color secondaryFixedDim = Color(0xFF4CD7F6);

  // Tertiary Signals (Hyper Emerald Completion & Quota)
  static const Color tertiary = Color(0xFF4EDEA3);
  static const Color tertiaryContainer = Color(0xFF007650);
  static const Color onTertiary = Color(0xFF003824);
  static const Color onTertiaryContainer = Color(0xFF76FFC2);
  static const Color tertiaryFixed = Color(0xFF6FFBBE);
  static const Color tertiaryFixedDim = Color(0xFF4EDEA3);

  // Warning & Errors
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningContainer = Color(0x33F59E0B);
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onError = Color(0xFF690005);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // Cinematic Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF6366F1), Color(0xFF03B5D3)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient violetGlowGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF5A00C6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGlowGradient = LinearGradient(
    colors: [Color(0xFF03B5D3), Color(0xFF4CD7F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceCardGradient = LinearGradient(
    colors: [Color(0xFF262A33), Color(0xFF1C2028)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glow Shadows
  static const List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: Color(0x667C3AED),
      blurRadius: 24,
      spreadRadius: 2,
    ),
  ];

  static const List<BoxShadow> cyanGlow = [
    BoxShadow(
      color: Color(0x4D06B6D4),
      blurRadius: 18,
      spreadRadius: 1,
    ),
  ];

  static const List<BoxShadow> emeraldGlow = [
    BoxShadow(
      color: Color(0x4D10B981),
      blurRadius: 16,
      spreadRadius: 1,
    ),
  ];
}
