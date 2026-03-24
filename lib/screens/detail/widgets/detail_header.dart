import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/islamic_icon.dart';

class DetailHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double fontSize;

  const DetailHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.emeraldGreen.withValues(alpha: 0.2),
                  AppColors.darkSurface,
                ]
              : [
                  const Color(0xFFE8F5E9),
                  AppColors.lightSurface,
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.emeraldGreen.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        children: [
          // Islamic icon circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryGreen, AppColors.emeraldGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.emeraldGreen.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const IslamicIcon(size: 36, color: Colors.white),
          ),
          const SizedBox(height: 18),

          // Title
          SelectableText(
            title,
            style: TextStyle(
              fontFamily: 'Amiri',
              color: AppColors.emeraldGreen,
              fontSize: math.max(26, fontSize * 1.3),
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          // Subtitle
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            SelectableText(
              subtitle!,
              style: TextStyle(
                fontFamily: 'NotoNaskhArabic',
                color: AppColors.emeraldGreen.withValues(alpha: 0.8),
                fontSize: math.max(16, fontSize * 0.8),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 18),

          // Islamic ornamental divider
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dot(),
              const SizedBox(width: 12),
              const Text(
                '۞',
                style: TextStyle(
                  color: AppColors.emeraldGreen,
                  fontSize: 28,
                  height: 1,
                ),
              ),
              const SizedBox(width: 12),
              _dot(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.emeraldGreen,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
