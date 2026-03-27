import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/arabic_normalizer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/bookmarks_provider.dart';

class ContentBody extends StatelessWidget {
  final String content;
  final double fontSize;
  final bool isDark;
  final String searchQuery;
  final int activeSearchMatchIndex;
  final List<Bookmark> bookmarks; // full bookmark objects with matchIndex
  final String? highlightText;
  final int highlightMatchIndex; // which occurrence to flash-highlight
  final double highlightOpacity;

  const ContentBody({
    super.key,
    required this.content,
    required this.fontSize,
    required this.isDark,
    this.searchQuery = '',
    this.activeSearchMatchIndex = 0,
    this.bookmarks = const [],
    this.highlightText,
    this.highlightMatchIndex = 0,
    this.highlightOpacity = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.gold : AppColors.emeraldGreen;
    final accentSoft = accent.withValues(alpha: isDark ? 0.18 : 0.12);
    final accentFaint = accent.withValues(alpha: isDark ? 0.08 : 0.05);

    return Container(
      // Outer frame
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.25 : 0.15),
          width: 1.5,
        ),
        boxShadow: [
          // Deep shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          // Mid shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          // Accent glow
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.06 : 0.03),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface
                : AppColors.lightSurface,
          ),
          child: Stack(
            children: [
              // Subtle radial glow at top
              Positioned(
                top: -60,
                left: 0,
                right: 0,
                height: 200,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.2,
                      colors: [
                        accent.withValues(alpha: isDark ? 0.06 : 0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Left side ornamental border
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                child: _sideOrnament(accent, isDark),
              ),
              // Right side ornamental border
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: _sideOrnament(accent, isDark),
              ),

              // Corner ornaments
              for (final corner in _Corner.values)
                Positioned(
                  top: corner.isTop ? 0 : null,
                  bottom: corner.isTop ? null : 0,
                  left: corner.isLeft ? 0 : null,
                  right: corner.isLeft ? null : 0,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: CustomPaint(
                      painter: _CornerPainter(
                        color: accent.withValues(alpha: isDark ? 0.35 : 0.20),
                        corner: corner,
                      ),
                    ),
                  ),
                ),

              // Main content column
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top ornamental band
                  _ornamentalBand(accent, accentSoft, accentFaint),

                  // Inner frame with content
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        vertical: BorderSide(
                          color: accentFaint,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 24,
                      ),
                      child: content.isNotEmpty
                          ? _buildContent()
                          : _buildEmptyState(),
                    ),
                  ),

                  // Bottom ornamental band
                  _ornamentalBand(accent, accentSoft, accentFaint),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Decorative band at top/bottom of the frame
  Widget _ornamentalBand(Color accent, Color accentSoft, Color accentFaint) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: accentFaint,
        border: Border(
          bottom: BorderSide(color: accentSoft, width: 0.5),
          top: BorderSide(color: accentSoft, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(child: _gradientLine(accent, true)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _eightPointStar(accent, 7),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _eightPointStar(accent, 5),
          ),
          Text(
            ' ۞ ',
            style: TextStyle(
              fontSize: 14,
              color: accent.withValues(alpha: 0.45),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _eightPointStar(accent, 5),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _eightPointStar(accent, 7),
          ),
          Expanded(child: _gradientLine(accent, false)),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  /// Side border with repeating diamond dots
  Widget _sideOrnament(Color accent, bool isDark) {
    return SizedBox(
      width: 10,
      child: CustomPaint(
        painter: _SideBorderPainter(
          color: accent.withValues(alpha: isDark ? 0.12 : 0.07),
          dotColor: accent.withValues(alpha: isDark ? 0.20 : 0.10),
        ),
      ),
    );
  }

  static final _sectionPattern = RegExp(r'§SECTION§(.+?)§SECTION§');

  Widget _buildContent() {
    int globalSearchOffset = 0;

    Widget buildText(String text) {
      final result = _buildBodyText(text, globalSearchOffset);
      // Count search matches in this chunk to advance the offset
      if (searchQuery.isNotEmpty) {
        final normalizedQuery = normalizeArabic(searchQuery);
        globalSearchOffset += findNormalizedMatches(text, normalizedQuery).length;
      }
      return result;
    }

    if (!content.contains('§SECTION§')) {
      return buildText(content);
    }

    final parts = <Widget>[];
    int lastEnd = 0;

    for (final match in _sectionPattern.allMatches(content)) {
      final before = content.substring(lastEnd, match.start).trim();
      if (before.isNotEmpty) {
        parts.add(buildText(before));
      }
      parts.add(_buildSectionHeader(match.group(1)!));
      lastEnd = match.end;
    }

    final after = content.substring(lastEnd).trim();
    if (after.isNotEmpty) {
      parts.add(buildText(after));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: parts,
    );
  }

  Widget _buildBodyText(String rawText, int searchMatchOffset) {
    // Replace newlines with spaces so text flows naturally within available width
    final text = rawText.replaceAll('\n', ' ').replaceAll(RegExp(r' {2,}'), ' ').trim();

    final baseStyle = TextStyle(
      fontFamily: 'ScheherazadeNew',
      fontSize: fontSize,
      height: 1.9,
      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
    );

    final accentColor = isDark ? AppColors.gold : AppColors.emeraldGreen;

    // Collect all highlight ranges: search matches + bookmark matches + flash highlight
    final allRanges = <_HighlightRange>[];

    // Search highlighting — track global match index for active highlight
    int searchMatchCount = 0;
    if (searchQuery.isNotEmpty) {
      final normalizedQuery = normalizeArabic(searchQuery);
      for (final (start, end) in findNormalizedMatches(text, normalizedQuery)) {
        final globalIdx = searchMatchOffset + searchMatchCount;
        final isActive = globalIdx == activeSearchMatchIndex;
        allRanges.add(_HighlightRange(start, end,
            isActive ? _HighlightType.searchActive : _HighlightType.search));
        searchMatchCount++;
      }
    }

    // Flash highlight from bookmark navigation — use exact match index
    if (highlightText != null && highlightOpacity > 0) {
      final normQ = normalizeArabic(highlightText!);
      final flashMatches = findNormalizedMatches(text, normQ);
      if (flashMatches.length > highlightMatchIndex) {
        final (start, end) = flashMatches[highlightMatchIndex];
        allRanges.add(_HighlightRange(start, end, _HighlightType.flash));
      } else if (flashMatches.isNotEmpty) {
        final (start, end) = flashMatches.first;
        allRanges.add(_HighlightRange(start, end, _HighlightType.flash));
      }
    }

    // Bookmark highlighting (subtle) — use exact match index per bookmark
    for (final bookmark in bookmarks) {
      final normQ = normalizeArabic(bookmark.text);
      final bMatches = findNormalizedMatches(text, normQ);
      if (bMatches.length > bookmark.matchIndex) {
        final (start, end) = bMatches[bookmark.matchIndex];
        allRanges.add(_HighlightRange(start, end, _HighlightType.bookmark));
      } else if (bMatches.isNotEmpty) {
        final (start, end) = bMatches.first;
        allRanges.add(_HighlightRange(start, end, _HighlightType.bookmark));
      }
    }

    if (allRanges.isEmpty) {
      return Text(text, style: baseStyle, textAlign: TextAlign.justify);
    }

    // Sort by start position, then by priority (search > flash > bookmark)
    allRanges.sort((a, b) {
      final cmp = a.start.compareTo(b.start);
      if (cmp != 0) return cmp;
      return a.type.index.compareTo(b.type.index);
    });

    // Build spans, resolving overlaps by priority
    final spans = <TextSpan>[];
    int cursor = 0;

    // Deduplicate: for overlapping ranges, keep highest priority
    final effectiveRanges = <_HighlightRange>[];
    for (final range in allRanges) {
      if (effectiveRanges.isEmpty || range.start >= effectiveRanges.last.end) {
        effectiveRanges.add(range);
      } else if (range.type.index < effectiveRanges.last.type.index) {
        // Higher priority overwrites
        effectiveRanges[effectiveRanges.length - 1] = range;
      }
    }

    for (final range in effectiveRanges) {
      if (range.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, range.start)));
      }

      TextStyle hlStyle;
      switch (range.type) {
        case _HighlightType.searchActive:
          hlStyle = TextStyle(
            color: isDark ? AppColors.darkBackground : Colors.white,
            fontWeight: FontWeight.w700,
            backgroundColor: accentColor.withValues(alpha: 0.9),
          );
        case _HighlightType.search:
          hlStyle = TextStyle(
            backgroundColor: accentColor.withValues(alpha: 0.25),
          );
        case _HighlightType.flash:
          // Soft glow that fades — starts strong and fades out
          final opacity = highlightOpacity;
          hlStyle = TextStyle(
            fontWeight: FontWeight.w700,
            color: opacity > 0.5
                ? (isDark ? AppColors.darkBackground : Colors.white)
                : null,
            backgroundColor: accentColor.withValues(alpha: 0.7 * opacity),
          );
        case _HighlightType.bookmark:
          hlStyle = TextStyle(
            backgroundColor: accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
          );
      }

      spans.add(TextSpan(
        text: text.substring(range.start, range.end),
        style: hlStyle,
      ));
      cursor = range.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      textAlign: TextAlign.justify,
    );
  }

  Widget _buildSectionHeader(String title) {
    final headerColor = isDark ? AppColors.gold : AppColors.emeraldGreen;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          // Top line with triple star
          Row(
            children: [
              Expanded(child: _gradientLine(headerColor, true)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _eightPointStar(headerColor, 6),
              ),
              _eightPointStar(headerColor, 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _eightPointStar(headerColor, 6),
              ),
              Expanded(child: _gradientLine(headerColor, false)),
            ],
          ),
          const SizedBox(height: 14),

          // Title in ornamental frame
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: headerColor.withValues(alpha: isDark ? 0.08 : 0.04),
              border: Border.all(
                color: headerColor.withValues(alpha: isDark ? 0.15 : 0.08),
                width: 0.5,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '﴾  $title  ﴿',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: fontSize * 1.15,
                  fontWeight: FontWeight.w700,
                  color: headerColor,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Bottom line
          Row(
            children: [
              Expanded(child: _gradientLine(headerColor, true)),
              Text(
                '  ۞  ',
                style: TextStyle(
                  color: headerColor.withValues(alpha: 0.35),
                  fontSize: 12,
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

/// Paints decorative corner flourish (L-shape with curves)
enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

extension on _Corner {
  bool get isTop => this == _Corner.topLeft || this == _Corner.topRight;
  bool get isLeft => this == _Corner.topLeft || this == _Corner.bottomLeft;
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final _Corner corner;
  _CornerPainter({required this.color, required this.corner});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    canvas.save();

    // Rotate depending on corner
    switch (corner) {
      case _Corner.topLeft:
        break; // default orientation
      case _Corner.topRight:
        canvas.translate(w, 0);
        canvas.scale(-1, 1);
        break;
      case _Corner.bottomLeft:
        canvas.translate(0, h);
        canvas.scale(1, -1);
        break;
      case _Corner.bottomRight:
        canvas.translate(w, h);
        canvas.scale(-1, -1);
        break;
    }

    // Draw an L-shaped arc flourish
    final path = Path();
    // Outer L
    path.moveTo(4, 24);
    path.quadraticBezierTo(4, 4, 24, 4);
    canvas.drawPath(path, paint);

    // Inner L (smaller)
    final inner = Path();
    inner.moveTo(8, 18);
    inner.quadraticBezierTo(8, 8, 18, 8);
    canvas.drawPath(inner, paint..strokeWidth = 1.0);

    // Small dot at corner
    canvas.drawCircle(
      const Offset(6, 6),
      1.5,
      Paint()..color = color..style = PaintingStyle.fill,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints a thin vertical line with periodic diamond dots
class _SideBorderPainter extends CustomPainter {
  final Color color;
  final Color dotColor;
  _SideBorderPainter({required this.color, required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    final cx = size.width / 2;

    // Vertical line
    canvas.drawLine(
      Offset(cx, 20),
      Offset(cx, size.height - 20),
      linePaint,
    );

    // Diamond dots every 50px
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    final diamondSize = 2.5;
    for (double y = 50; y < size.height - 40; y += 50) {
      final path = Path()
        ..moveTo(cx, y - diamondSize)
        ..lineTo(cx + diamondSize, y)
        ..lineTo(cx, y + diamondSize)
        ..lineTo(cx - diamondSize, y)
        ..close();
      canvas.drawPath(path, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Highlight types ordered by priority (lowest index = highest priority)
enum _HighlightType { searchActive, search, flash, bookmark }

class _HighlightRange {
  final int start;
  final int end;
  final _HighlightType type;
  const _HighlightRange(this.start, this.end, this.type);
}
