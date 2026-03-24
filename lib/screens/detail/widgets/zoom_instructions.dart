import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ZoomInstructions extends StatelessWidget {
  const ZoomInstructions({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.gold : AppColors.emeraldGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.06 : 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.touch_app_rounded,
              color: accentColor.withValues(alpha: 0.6),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'استخدم إصبعين للتكبير • انقر نقرتين للعودة للحجم الافتراضي',
              style: TextStyle(
                fontFamily: 'ScheherazadeNew',
                color: AppColors.emeraldGreen,
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
