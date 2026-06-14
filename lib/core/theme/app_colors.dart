import 'package:flutter/material.dart';

class AppColors {
  static const primaryBg = Color(0xFF06080D);
  static const secondaryBg = Color(0xFF101722);
  static const cardBg = Color(0xFF151E2B);
  static const border = Color(0xFF283547);
  static const gold = Color(0xFFFFC857);
  static const goldDark = Color(0xFFB38000); // Darker, readable gold for light mode
  static const goldGlow = Color(0x33FFC857);
  static const neonBlue = Color(0xFF24C6FF);
  static const success = Color(0xFF00D084);
  static const error = Color(0xFFFF4D67);
  static const white = Color(0xFFFFFFFF);
  static const muted = Color(0xFFA7B3C4);
  static const disabled = Color(0xFF556172);
  static const lightBg = Color(0xFFF4F7FB);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFEAF1F8);
  static const lightBorder = Color(0xFFD2DDEA);
  static const lightText = Color(0xFF101827);
  static const lightMuted = Color(0xFF66758A);
  static const violet = Color(0xFF8B5CF6);
  static const rose = Color(0xFFFF5C8A);

  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  static Color bg(BuildContext context) => isDark(context) ? primaryBg : lightBg;
  static Color surface(BuildContext context) => isDark(context) ? secondaryBg : lightSurface;
  static Color card(BuildContext context) => isDark(context) ? cardBg : lightCard;
  static Color line(BuildContext context) => isDark(context) ? border : lightBorder;
  static Color text(BuildContext context) => isDark(context) ? white : lightText;
  static Color mutedText(BuildContext context) => isDark(context) ? muted : lightMuted;
  static Color themeGold(BuildContext context) => isDark(context) ? gold : goldDark;
  static LinearGradient pageGradient(BuildContext context) => isDark(context)
      ? const LinearGradient(
          colors: [Color(0xFF06080D), Color(0xFF0B1220), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : const LinearGradient(
          colors: [Color(0xFFFDFEFF), Color(0xFFF1F6FC), Color(0xFFEAF4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
  static LinearGradient premiumGradient(BuildContext context) => const LinearGradient(
        colors: [gold, Color(0xFFFFE08A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  static LinearGradient accentGradient(BuildContext context) => const LinearGradient(
        colors: [neonBlue, violet],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
