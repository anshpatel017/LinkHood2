import 'package:flutter/material.dart';

/// RentNear (LinkHood) color palette
class AppColors {
  AppColors._();

  // Primary brand colors
  static const Color primary = Color(0xFF5044E3);        // Soft indigo
  static const Color primaryLight = Color(0xFFBDBAFF);   // Primary container
  static const Color primaryDark = Color(0xFF4335D6);    // Dim

  // Secondary / Accent
  static const Color accent = Color(0xFF286C34);         // Sage green
  static const Color accentLight = Color(0xFFB4FDB4);
  static const Color accentDark = Color(0xFF1A5F29);

  // Backgrounds & Surfaces (Tonal Layering)
  static const Color background = Color(0xFFFBF9F5);     // Warm soft cream
  static const Color surface = Color(0xFFFBF9F5);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF5F3EF);
  static const Color surfaceContainer = Color(0xFFEFEEE9);
  static const Color surfaceContainerHigh = Color(0xFFE9E8E3);
  static const Color surfaceContainerHighest = Color(0xFFE3E3DD);
  static const Color surfaceVariant = Color(0xFFE3E3DD);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF31332F);    // On-surface (No pure black)
  static const Color textSecondary = Color(0xFF5E605B);  // On-surface variant
  static const Color textTertiary = Color(0xFF9E9D99);   // Inverse on-surface
  static const Color textOnPrimary = Color(0xFFFBF7FF);

  // Status colors
  static const Color success = Color(0xFF286C34);
  static const Color warning = Color(0xFF745C00);        // Tertiary (warm yellow)
  static const Color error = Color(0xFFAC3149);          // Soft coral
  static const Color info = Color(0xFF3B82F6);

  // Rental status colors
  static const Color statusPending = Color(0xFFFDD34D);
  static const Color statusAccepted = Color(0xFF5044E3);
  static const Color statusActive = Color(0xFF286C34);
  static const Color statusCompleted = Color(0xFF5E605B);
  static const Color statusCancelled = Color(0xFFAC3149);
  static const Color statusDisputed = Color(0xFF770326);

  // Borders and dividers (Ghost borders)
  static const Color border = Color(0x26B2B2AD);         // Outline variant @ 15% opacity
  static const Color divider = Color(0xFFE3E3DD);        // Surface Variant

  // Rating
  static const Color starFilled = Color(0xFFFDD34D);
  static const Color starEmpty = Color(0xFFE3E3DD);

  // Shadow (Ambient Depth)
  static const Color shadow = Color(0x0F31332F);         // 6% of On-surface text
}
