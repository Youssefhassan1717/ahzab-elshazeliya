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
          ? _buildContent()
          : _buildEmptyState(),
    );
  }

  static final _sectionPattern = RegExp(r'§SECTION§(.+?)§SECTION§');

  Widget _buildContent() {
    // Check if content has section headers
    if (!content.contains('§SECTION§')) {
      return _buildBodyText(content);
    }

    // Split content by section markers
    final parts = <Widget>[];
    int lastEnd = 0;

    for (final match in _sectionPattern.allMatches(content)) {
      // Text before this section header
      final before = content.substring(lastEnd, match.start).trim();
      if (before.isNotEmpty) {
        parts.add(_buildBodyText(before));
      }

      // Section header
      parts.add(_buildSectionHeader(match.group(1)!));
      lastEnd = match.end;
    }

    // Remaining text after last section header
    final after = content.substring(lastEnd).trim();
    if (after.isNotEmpty) {
      parts.add(_buildBodyText(after));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: parts,
    );
  }

  Widget _buildBodyText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'ScheherazadeNew',
        fontSize: fontSize,
        height: 2.2,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
      ),
      textAlign: TextAlign.justify,
    );
  }

  Widget _buildSectionHeader(String title) {
    final headerColor = isDark ? AppColors.gold : AppColors.emeraldGreen;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Ornamental divider
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        headerColor.withValues(alpha: 0.0),
                        headerColor.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '۞',
                  style: TextStyle(
                    fontSize: fontSize * 0.8,
                    color: headerColor,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        headerColor.withValues(alpha: 0.5),
                        headerColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Title
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: fontSize * 1.15,
              fontWeight: FontWeight.w700,
              color: headerColor,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          // Bottom ornamental divider
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        headerColor.withValues(alpha: 0.0),
                        headerColor.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '۞',
                  style: TextStyle(
                    fontSize: fontSize * 0.8,
                    color: headerColor,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        headerColor.withValues(alpha: 0.5),
                        headerColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
              fontFamily: 'ScheherazadeNew',
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
              fontFamily: 'ScheherazadeNew',
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
