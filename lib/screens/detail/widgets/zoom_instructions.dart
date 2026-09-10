import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ZoomInstructions extends StatelessWidget {
  const ZoomInstructions({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.emeraldGreen;
    final textColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.06 : 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          _Hint(
            icon: Icons.pinch_rounded,
            text: 'استخدم إصبعين للتكبير والتصغير',
            accent: accent,
            textColor: textColor,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              height: 1,
              thickness: 1,
              color: accent.withValues(alpha: 0.12),
            ),
          ),
          _Hint(
            icon: Icons.touch_app_rounded,
            text: 'انقر نقرتين للعودة للحجم الافتراضي',
            accent: accent,
            textColor: textColor,
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({
    required this.icon,
    required this.text,
    required this.accent,
    required this.textColor,
  });

  final IconData icon;
  final String text;
  final Color accent;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: accent, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'ScheherazadeNew',
              color: textColor,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
