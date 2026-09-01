import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class HizbSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const HizbSearchBar({super.key, required this.onChanged});

  @override
  State<HizbSearchBar> createState() => _HizbSearchBarState();
}

class _HizbSearchBarState extends State<HizbSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty != _hasText) {
      setState(() => _hasText = trimmed.isNotEmpty);
    }
    widget.onChanged(trimmed);
  }

  void _clear() {
    _controller.clear();
    setState(() => _hasText = false);
    widget.onChanged('');
    FocusScope.of(context).unfocus();
  }

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
        controller: _controller,
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
          suffixIcon: _hasText
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  tooltip: 'مسح البحث',
                  onPressed: _clear,
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
        style: TextStyle(
          fontFamily: 'ScheherazadeNew',
          fontSize: 16,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        onChanged: _handleChanged,
      ),
    );
  }
}
