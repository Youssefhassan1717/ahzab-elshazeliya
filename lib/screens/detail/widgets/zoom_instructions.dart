import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ZoomInstructions extends StatelessWidget {
  const ZoomInstructions({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.emeraldGreen.withValues(alpha: isDark ? 0.1 : 0.05),
            Colors.transparent,
          ],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.emeraldGreen.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.emeraldGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.touch_app,
              color: AppColors.emeraldGreen,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'استخدم إصبعين للتكبير • انقر نقرتين للعودة للحجم الافتراضي',
              style: TextStyle(
                fontFamily: 'NotoNaskhArabic',
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
