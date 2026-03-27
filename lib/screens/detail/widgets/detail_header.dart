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
    final accentColor = isDark ? AppColors.gold : AppColors.emeraldGreen;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF132E1C),
                  const Color(0xFF0D1F14),
                  const Color(0xFF132E1C),
                ]
              : [
                  const Color(0xFFF5FAF6),
                  Colors.white,
                  const Color(0xFFF5FAF6),
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.25 : 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : AppColors.emeraldGreen.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Islamic geometric pattern overlay
            Positioned.fill(
              child: CustomPaint(
                painter: _IslamicPatternPainter(
                  color: accentColor.withValues(alpha: isDark ? 0.04 : 0.025),
                ),
              ),
            ),

            // Corner arch ornaments
            ..._buildCornerArches(accentColor, isDark),

            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Column(
                children: [
                  // Top arabesque band
                  _arabesqueBand(accentColor, isDark),
                  const SizedBox(height: 8),

                  // بسم الله
                  Text(
                    'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                    style: TextStyle(
                      fontFamily: 'ScheherazadeNew',
                      color: accentColor.withValues(alpha: 0.65),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      color: accentColor,
                      fontSize: math.max(28, fontSize * 1.4),
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Subtitle
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
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

                  const SizedBox(height: 10),

                  // Bottom arabesque band
                  _arabesqueBand(accentColor, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCornerArches(Color color, bool isDark) {
    final ornamentColor = color.withValues(alpha: isDark ? 0.1 : 0.06);
    return [
      Positioned(top: 0, left: 0, child: _archCorner(ornamentColor, 0)),
      Positioned(top: 0, right: 0, child: _archCorner(ornamentColor, 1)),
      Positioned(bottom: 0, left: 0, child: _archCorner(ornamentColor, 2)),
      Positioned(bottom: 0, right: 0, child: _archCorner(ornamentColor, 3)),
    ];
  }

  Widget _archCorner(Color color, int corner) {
    return SizedBox(
      width: 60,
      height: 60,
      child: CustomPaint(
        painter: _ArchCornerPainter(color: color, corner: corner),
      ),
    );
  }

  Widget _buildMedallion(bool isDark, Color accentColor) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer octagonal ring
          CustomPaint(
            size: const Size(88, 88),
            painter: _OctagonPainter(
              color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
              strokeWidth: 1.5,
            ),
          ),
          // Middle circle
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
                width: 1.0,
              ),
            ),
          ),
          // Inner gradient circle
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: isDark
                    ? [
                        AppColors.gold.withValues(alpha: 0.9),
                        const Color(0xFFAA8844),
                      ]
                    : [
                        AppColors.primaryGreen,
                        AppColors.deepGreen,
                      ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: isDark ? 0.3 : 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '۞',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _arabesqueBand(Color color, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.0),
                  color.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _miniStar(color, 4),
        const SizedBox(width: 8),
        Text(
          '﴾',
          style: TextStyle(
            color: color.withValues(alpha: 0.45),
            fontSize: 18,
            fontFamily: 'ScheherazadeNew',
            height: 1,
          ),
        ),
        const SizedBox(width: 4),
        _miniStar(color, 6),
        const SizedBox(width: 4),
        Text(
          '﴿',
          style: TextStyle(
            color: color.withValues(alpha: 0.45),
            fontSize: 18,
            fontFamily: 'ScheherazadeNew',
            height: 1,
          ),
        ),
        const SizedBox(width: 8),
        _miniStar(color, 4),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.35),
                  color.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniStar(Color color, double size) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

/// Draws an octagon (8-sided polygon)
class _OctagonPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  _OctagonPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 2;
    final path = Path();

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - math.pi / 8;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Draws arch-style corner ornaments (Islamic mihrab motif)
class _ArchCornerPainter extends CustomPainter {
  final Color color;
  final int corner; // 0=topLeft, 1=topRight, 2=bottomLeft, 3=bottomRight
  _ArchCornerPainter({required this.color, required this.corner});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.save();

    // Rotate/flip based on corner
    switch (corner) {
      case 1: // top-right
        canvas.translate(size.width, 0);
        canvas.scale(-1, 1);
        break;
      case 2: // bottom-left
        canvas.translate(0, size.height);
        canvas.scale(1, -1);
        break;
      case 3: // bottom-right
        canvas.translate(size.width, size.height);
        canvas.scale(-1, -1);
        break;
    }

    // Outer arch
    final p1 = Path()
      ..moveTo(0, size.height * 0.85)
      ..quadraticBezierTo(0, 0, size.width * 0.85, 0);
    canvas.drawPath(p1, paint);

    // Inner arch
    final p2 = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(0, 0, size.width * 0.6, 0);
    canvas.drawPath(p2, paint..color = color.withValues(alpha: color.a * 0.5));

    // Small dot
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.15),
      2,
      Paint()..color = color.withValues(alpha: color.a * 0.6),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Subtle Islamic geometric background pattern
class _IslamicPatternPainter extends CustomPainter {
  final Color color;
  _IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    final cols = (size.width / spacing).ceil() + 1;
    final rows = (size.height / spacing).ceil() + 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cx = c * spacing + (r.isOdd ? spacing / 2 : 0);
        final cy = r * spacing;
        _drawStarShape(canvas, Offset(cx, cy), 8, paint);
      }
    }
  }

  void _drawStarShape(Canvas canvas, Offset center, double radius, Paint paint) {
    // Small 8-pointed star
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final outerAngle = (i * math.pi / 4) - math.pi / 8;
      final innerAngle = outerAngle + math.pi / 8;
      final ox = center.dx + radius * math.cos(outerAngle);
      final oy = center.dy + radius * math.sin(outerAngle);
      final ix = center.dx + (radius * 0.4) * math.cos(innerAngle);
      final iy = center.dy + (radius * 0.4) * math.sin(innerAngle);

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
