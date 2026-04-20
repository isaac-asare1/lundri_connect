import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // static const Color primary = Color(0xFF7C3AED);
  static const Color primary = Color(0xFFF06292);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF5B21B6);

  static const Color accentPink = Color(0xFFE74D88);
  static const Color softPink = Color(0xFFF8E9EF);
  static const Color scaffoldBackground = Color(0xFFF6F1F4);

  static const Color white = Colors.white;
  static const Color black = Color(0xFF111827);

  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFEEE7EA);

  static const Color success = Color(0xFF22C55E);
  static const Color successBg = Color(0xFFE8F8EE);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3E2);

  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFDECEC);

  static const Color pendingBg = Color(0xFFF3EEF0);
  static const Color iconMuted = Color(0xFF667085);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
  );

  static const LinearGradient pinkGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFE74D88), Color(0xFFF06292)],
  );
}
