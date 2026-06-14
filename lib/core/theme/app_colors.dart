import 'package:flutter/material.dart';

class AppColors {
  static const primaryBg = Color(0xFF0A0A0A);
  static const secondaryBg = Color(0xFF111111);
  static const cardBg = Color(0xFF1A1A1A);
  static const border = Color(0xFF2A2A2A);
  static const gold = Color(0xFFFFD700);
  static const goldDark = Color(0xFFE6C200);
  static const goldGlow = Color(0x26FFD700);
  static const neonBlue = Color(0xFF00B8FF);
  static const success = Color(0xFF00C853);
  static const error = Color(0xFFFF1744);
  static const white = Color(0xFFFFFFFF);
  static const muted = Color(0xFF888888);
  static const disabled = Color(0xFF444444);
  static const lightBg = Color(0xFFF7F8FA);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFEFF3F7);
  static const lightBorder = Color(0xFFD9DEE7);
  static const lightText = Color(0xFF111111);
  static const lightMuted = Color(0xFF647084);

  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  static Color bg(BuildContext context) => isDark(context) ? primaryBg : lightBg;
  static Color surface(BuildContext context) => isDark(context) ? secondaryBg : lightSurface;
  static Color card(BuildContext context) => isDark(context) ? cardBg : lightCard;
  static Color line(BuildContext context) => isDark(context) ? border : lightBorder;
  static Color text(BuildContext context) => isDark(context) ? white : lightText;
  static Color mutedText(BuildContext context) => isDark(context) ? muted : lightMuted;
}
