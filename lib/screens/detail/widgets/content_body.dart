import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ContentBody extends StatelessWidget {
  final String content;
  final double fontSize;
  final bool isDark;

  const ContentBody({
    super.key,
    required this.content,
    required this.fontSize,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE0E0E0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: content.isNotEmpty
          ? SelectableText(
              content,
              style: TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: fontSize,
                height: 2.1,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.justify,
            )
          : _buildEmptyState(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_outlined,
              size: 40,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لا يوجد محتوى متاح حاليًا',
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم إضافة المحتوى قريبًا إن شاء الله',
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              color: isDark
                  ? AppColors.darkTextSecondary.withValues(alpha: 0.7)
                  : AppColors.lightTextSecondary.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
