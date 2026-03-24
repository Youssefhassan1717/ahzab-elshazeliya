import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

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
                  const Color(0xFF1A3A25),
                  const Color(0xFF0F2418),
                  const Color(0xFF1A3A25),
                ]
              : [
                  const Color(0xFFF0F7F2),
                  Colors.white,
                  const Color(0xFFF0F7F2),
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.gold.withValues(alpha: 0.2)
              : AppColors.emeraldGreen.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppColors.emeraldGreen.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          if (!isDark)
            BoxShadow(
              color: AppColors.emeraldGreen.withValues(alpha: 0.04),
              blurRadius: 40,
              spreadRadius: 5,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Subtle corner ornaments
            Positioned(
              top: -8,
              left: -8,
              child: _cornerOrnament(isDark),
            ),
            Positioned(
              top: -8,
              right: -8,
              child: Transform.flip(
                flipX: true,
                child: _cornerOrnament(isDark),
              ),
            ),
            Positioned(
              bottom: -8,
              left: -8,
              child: Transform.flip(
                flipY: true,
                child: _cornerOrnament(isDark),
              ),
            ),
            Positioned(
              bottom: -8,
              right: -8,
              child: Transform.flip(
                flipX: true,
                flipY: true,
                child: _cornerOrnament(isDark),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                children: [
                  // Top ornamental line
                  _ornamentalDivider(isDark, isTop: true),

                  const SizedBox(height: 14),

                  // Premium icon with double ring
                  _buildPremiumIcon(isDark),

                  const SizedBox(height: 14),

                  // بسم الله
                  Text(
                    'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                    style: TextStyle(
                      fontFamily: 'ScheherazadeNew',
                      color: isDark
                          ? AppColors.gold.withValues(alpha: 0.7)
                          : AppColors.emeraldGreen.withValues(alpha: 0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.8,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Title — Amiri Bold for clarity + size
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      color: isDark
                          ? AppColors.gold
                          : AppColors.emeraldGreen,
                      fontSize: math.max(32, fontSize * 1.5),
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Subtitle
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: 'ScheherazadeNew',
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontSize: math.max(16, fontSize * 0.8),
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Bottom ornamental divider
                  _ornamentalDivider(isDark, isTop: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumIcon(bool isDark) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? AppColors.gold.withValues(alpha: 0.3)
              : AppColors.emeraldGreen.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.gold.withValues(alpha: 0.9), const Color(0xFFAA8844)]
                  : [AppColors.primaryGreen, AppColors.emeraldGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? AppColors.gold.withValues(alpha: 0.25)
                    : AppColors.emeraldGreen.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '۞',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ornamentalDivider(bool isDark, {required bool isTop}) {
    final color = isDark ? AppColors.gold : AppColors.emeraldGreen;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.0),
                  color.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _miniDiamond(color),
        const SizedBox(width: 6),
        Text(
          isTop ? '﷽' : '❊',
          style: TextStyle(
            color: color.withValues(alpha: 0.5),
            fontSize: isTop ? 10 : 16,
            height: 1,
          ),
        ),
        const SizedBox(width: 6),
        _miniDiamond(color),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniDiamond(Color color) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _cornerOrnament(bool isDark) {
    final color = isDark ? AppColors.gold : AppColors.emeraldGreen;
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(
        painter: _CornerPainter(color: color.withValues(alpha: 0.12)),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Curved corner flourish
    final path = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(0, 0, size.width * 0.8, 0);

    final path2 = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(0, 0, size.width * 0.6, 0);

    canvas.drawPath(path, paint);
    canvas.drawPath(path2, paint..color = color.withValues(alpha: color.a * 0.5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
