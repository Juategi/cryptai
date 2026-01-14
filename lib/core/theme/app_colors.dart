import 'package:flutter/material.dart';

/// CryptAI color palette
class AppColors {
  AppColors._();

  // Base
  static const Color white = Color(0xFFFDFDFD);

  // Brand / Primary
  static const Color blueDark = Color(0xFF013251); // Primary strong
  static const Color blueDeep = Color(0xFF05647F); // Buttons / headers
  static const Color turquoise = Color(0xFF0A8DA8); // Accent / CTA
  static const Color blueLight = Color(0xFF27A7D7); // Highlights
  static const Color blueSoft = Color(0xFF9CC6D2); // Borders / backgrounds

  // Aliases for easier usage
  static const Color primary = blueDark;
  static const Color primaryLight = blueLight;
  static const Color primaryDark = blueDark;
  static const Color secondary = turquoise;
  static const Color secondaryLight = blueLight;
  static const Color accent = turquoise;

  // Surface colors
  static const Color background = white;
  static const Color surface = white;
  static const Color surfaceVariant = Color(0xFFF0F7FA);

  // Dark theme colors
  static const Color backgroundDark = blueDark;
  static const Color surfaceDark = blueDeep;
  static const Color surfaceVariantDark = Color(0xFF074A61);

  // Text colors
  static const Color textPrimary = blueDark;
  static const Color textSecondary = blueDeep;
  static const Color textOnDark = white;
  static const Color textPrimaryDark = white;
  static const Color textSecondaryDark = blueSoft;

  // Chat bubble colors
  static const Color userBubble = turquoise;
  static const Color userBubbleText = white;
  static const Color assistantBubble = Color(0xFFE8F4F8);
  static const Color assistantBubbleText = blueDark;
  static const Color assistantBubbleDark = blueDeep;
  static const Color assistantBubbleTextDark = white;

  // Status colors
  static const Color success = turquoise;
  static const Color info = blueLight;
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color disabled = blueSoft;

  // Logo gradient
  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      blueDark,
      blueDeep,
      turquoise,
      blueLight,
    ],
  );
}
