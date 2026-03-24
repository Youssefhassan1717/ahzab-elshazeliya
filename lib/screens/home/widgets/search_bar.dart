import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class HizbSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const HizbSearchBar({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'ابحث في الأحزاب...',
          hintStyle: TextStyle(
            fontFamily: 'ScheherazadeNew',
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            fontSize: 16,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.emeraldGreen,
            size: 24,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
        style: TextStyle(
          fontFamily: 'ScheherazadeNew',
          fontSize: 16,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        onChanged: (value) => onChanged(value.trim()),
      ),
    );
  }
}
