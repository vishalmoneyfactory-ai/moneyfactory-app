import 'package:flutter/material.dart';

class AppColors {
  static const primaryBg = Color(0xFF05070C);
  static const secondaryBg = Color(0x99101722); // 60% opacity for surface bleed
  static const cardBg = Color(0xB3151E2B); // 70% opacity for glass bleed
  static const border = Color(0x80283547); // 50% opacity border
  static const gold = Color(0xFFFFC857);
  static const goldDark = Color(0xFF1A365D); // Deep navy blue for light mode
  static const buttonBlueLight = Color(0xFF3B82F6); // Lighter blue for buttons in light mode
  static const goldGlow = Color(0x33FFC857);
  static const neonBlue = Color(0xFF24C6FF);
  static const success = Color(0xFF00D084);
  static const successDark = Color(0xFF15803D); // Darker green for light mode
  static const error = Color(0xFFFF4D67);
  static const white = Color(0xFFFFFFFF);
  static const muted = Color(0xFFA7B3C4);
  static const disabled = Color(0xFF556172);
  static const lightBg = Color(0xFFFDFDFE);
  static const lightCard = Color(0xD9FFFFFF); // 85% opacity for premium glass bleed
  static const lightSurface = Color(0xB3FFFFFF); // 70% opacity for surface bleed
  static const lightBorder = Color(0x1F0F172A); // 12% deep slate for crisp glass edges
  static const lightText = Color(0xFF0F172A);
  static const lightMuted = Color(0xFF64748B);
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
  static Color themeButtonColor(BuildContext context) => isDark(context) ? gold : buttonBlueLight;
  static Color themeButtonText(BuildContext context) => isDark(context) ? primaryBg : white;
  static Color themeSuccess(BuildContext context) => isDark(context) ? success : successDark;
  static Color themeGoldGlow(BuildContext context) => isDark(context) ? goldGlow : goldDark.withValues(alpha: .2);
  
  static LinearGradient pageGradient(BuildContext context) => isDark(context)
      ? const LinearGradient(
          colors: [
            Color(0xFF05070C), // Deepest midnight at top left
            Color(0xFF0B1221), // Dark slate blue
            Color(0xFF0C142A), // Deep neon-blue shadow
            Color(0xFF161026), // Deep violet shadow at bottom right
          ],
          stops: [0.0, 0.4, 0.75, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : const LinearGradient(
          colors: [
            Color(0xFFFFFFFF), // Pure white at top left
            Color(0xFFF0F5FF), // Soft icy neon-blue wash
            Color(0xFFF4F0FD), // Soft violet pearl transition
            Color(0xFFE8EEF8), // Crisp slate-blue at bottom right
          ],
          stops: [0.0, 0.35, 0.75, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
  static LinearGradient premiumGradient(BuildContext context) => isDark(context)
      ? const LinearGradient(
          colors: [gold, Color(0xFFFFE08A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : const LinearGradient(
          colors: [goldDark, Color(0xFF2B6CB0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
  static LinearGradient accentGradient(BuildContext context) => const LinearGradient(
        colors: [neonBlue, violet],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
