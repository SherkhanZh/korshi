import 'package:flutter/material.dart';

/// Central color palette for Korshi, derived from the MVP screen designs.
class AppColors {
  AppColors._();

  // Brand greens
  static const Color primary = Color(0xFF1E6B4F); // deep forest / emerald
  static const Color primaryDark = Color(0xFF15573E);
  static const Color primaryLight = Color(0xFF2E8463);

  // Backgrounds / surfaces
  static const Color scaffold = Color(0xFFF6F5F0); // warm cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F0EA);
  static const Color surfaceGreenTint = Color(0xFFEDF2EC);

  // Text
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF6E6E73);
  static const Color textTertiary = Color(0xFF9A9A9F);

  // Borders / dividers
  static const Color border = Color(0xFFE6E5DF);
  static const Color divider = Color(0xFFEDECE6);

  // Category accent colors
  static const Color water = Color(0xFF3B9BE0);
  static const Color roads = Color(0xFF4A4A4F);
  static const Color lights = Color(0xFFF5B81E);
  static const Color garbage = Color(0xFF3FA45F);
  static const Color safety = Color(0xFF6C63C7);
  static const Color other = Color(0xFFB07A4A);

  // Status / badge colors
  static const Color resolvedBg = Color(0xFFE2F0E8);
  static const Color resolvedText = Color(0xFF1E6B4F);

  static const Color upcomingBg = Color(0xFFFBEFD6);
  static const Color upcomingText = Color(0xFFC9881C);

  static const Color eventBg = Color(0xFFE2F0E8);
  static const Color eventText = Color(0xFF1E6B4F);

  static const Color updateBg = Color(0xFFECE7F7);
  static const Color updateText = Color(0xFF6C63C7);

  static const Color waitingBg = Color(0xFFE3ECF8);
  static const Color waitingText = Color(0xFF3A6FB0);

  static const Color rejectedBg = Color(0xFFFBE6E1);
  static const Color rejectedText = Color(0xFFC0492E);

  static const Color emergencyBg = Color(0xFFFBE6E1);
  static const Color emergencyText = Color(0xFFC0492E);

  static const Color partnerBadge = Color(0xFF8A7A53);

  // Misc
  static const Color star = Color(0xFFF5B81E);
  static const Color logout = Color(0xFFD64A3A);
  static const Color shadow = Color(0x14000000);
}
