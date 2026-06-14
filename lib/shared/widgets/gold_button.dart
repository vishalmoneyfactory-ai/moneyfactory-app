import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class GoldButton extends StatelessWidget {
  const GoldButton({super.key, required this.label, required this.onPressed, this.icon, this.color});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, color: color == AppColors.success ? AppColors.white : AppColors.primaryBg),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.gold,
          foregroundColor: color == AppColors.success ? AppColors.white : AppColors.primaryBg,
          disabledBackgroundColor: AppColors.disabled,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          shadowColor: (color ?? AppColors.gold).withValues(alpha: .35),
          elevation: 6,
        ),
      ),
    );
  }
}
