import 'dart:math' as math;
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
    final accentColor = isDark ? AppColors.gold : AppColors.emeraldGreen;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.95)
            : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Subtle side borders (Islamic frame feel)
            Positioned(
              top: 20,
              bottom: 20,
              left: 0,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accentColor.withValues(alpha: 0.0),
                      accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
                      accentColor.withValues(alpha: 0.0),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Positioned(
              top: 20,
              bottom: 20,
              right: 0,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accentColor.withValues(alpha: 0.0),
                      accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
                      accentColor.withValues(alpha: 0.0),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: content.isNotEmpty
                  ? _buildContent()
                  : _buildEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  static final _sectionPattern = RegExp(r'§SECTION§(.+?)§SECTION§');

  Widget _buildContent() {
    if (!content.contains('§SECTION§')) {
      return _buildBodyText(content);
    }

    final parts = <Widget>[];
    int lastEnd = 0;

    for (final match in _sectionPattern.allMatches(content)) {
      final before = content.substring(lastEnd, match.start).trim();
      if (before.isNotEmpty) {
        parts.add(_buildBodyText(before));
      }
      parts.add(_buildSectionHeader(match.group(1)!));
      lastEnd = match.end;
    }

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
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // Top ornamental line with star
          Row(
            children: [
              Expanded(child: _gradientLine(headerColor, true)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _eightPointStar(headerColor, 10),
              ),
              Text(
                '۞',
                style: TextStyle(
                  fontSize: fontSize * 0.7,
                  color: headerColor.withValues(alpha: 0.6),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _eightPointStar(headerColor, 10),
              ),
              Expanded(child: _gradientLine(headerColor, false)),
            ],
          ),
          const SizedBox(height: 12),

          // Section title
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

          const SizedBox(height: 12),

          // Bottom ornamental line
          Row(
            children: [
              Expanded(child: _gradientLine(headerColor, true)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '﴾ ﴿',
                  style: TextStyle(
                    color: headerColor.withValues(alpha: 0.4),
                    fontSize: 14,
                    fontFamily: 'ScheherazadeNew',
                  ),
                ),
              ),
              Expanded(child: _gradientLine(headerColor, false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gradientLine(Color color, bool leftToRight) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: leftToRight
              ? [color.withValues(alpha: 0.0), color.withValues(alpha: 0.4)]
              : [color.withValues(alpha: 0.4), color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }

  Widget _eightPointStar(Color color, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MiniStarPainter(color: color.withValues(alpha: 0.4)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.description_outlined,
              size: 48,
              color: isDark
                  ? AppColors.darkTextSecondary.withValues(alpha: 0.4)
                  : AppColors.lightTextSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'لا يوجد محتوى',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStarPainter extends CustomPainter {
  final Color color;
  _MiniStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final path = Path();

    for (int i = 0; i < 8; i++) {
      final outerAngle = (i * math.pi / 4) - math.pi / 8;
      final innerAngle = outerAngle + math.pi / 8;
      final ox = cx + r * math.cos(outerAngle);
      final oy = cy + r * math.sin(outerAngle);
      final ix = cx + (r * 0.38) * math.cos(innerAngle);
      final iy = cy + (r * 0.38) * math.sin(innerAngle);

      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
