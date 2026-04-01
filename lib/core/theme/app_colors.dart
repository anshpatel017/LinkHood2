import 'package:flutter/material.dart';

/// RentNear color palette
class AppColors {
  AppColors._();

  // Primary brand colors
  static const Color primary = Color(0xFF4F46E5);       // Indigo
  static const Color primaryLight = Color(0xFF818CF8);   // Light indigo
  static const Color primaryDark = Color(0xFF3730A3);    // Dark indigo

  // Secondary / Accent
  static const Color accent = Color(0xFF10B981);         // Emerald green
  static const Color accentLight = Color(0xFF6EE7B7);
  static const Color accentDark = Color(0xFF059669);

  // Backgrounds
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Rental status colors
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusAccepted = Color(0xFF3B82F6);
  static const Color statusActive = Color(0xFF10B981);
  static const Color statusCompleted = Color(0xFF6B7280);
  static const Color statusCancelled = Color(0xFFEF4444);
  static const Color statusDisputed = Color(0xFFDC2626);

  // Borders and dividers
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // Rating
  static const Color starFilled = Color(0xFFFBBF24);
  static const Color starEmpty = Color(0xFFD1D5DB);

  // Shadow
  static const Color shadow = Color(0x1A000000);
}
