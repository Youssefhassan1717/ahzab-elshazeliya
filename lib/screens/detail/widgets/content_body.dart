import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/arabic_normalizer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/bookmarks_provider.dart';

class ContentBody extends StatelessWidget {
  final String content;
  final String title;
  final double fontSize;
  final bool isDark;
  final String searchQuery;
  final int activeSearchMatchIndex;
  final List<Bookmark> bookmarks; // full bookmark objects with chunkIndex + localStart/End
  final int? flashChunkIndex;     // chunk to flash-highlight (null = none)
  final int? flashLocalStart;     // start index in that chunk's cleaned text
  final int? flashLocalEnd;       // end index in that chunk's cleaned text
  final double highlightOpacity;
  final int? activeBookmarkChunkIndex;  // actively navigated bookmark chunk
  final int? activeBookmarkLocalStart;  // actively navigated bookmark start
  final int? activeBookmarkLocalEnd;    // actively navigated bookmark end
  final Map<int, GlobalKey> chunkKeys;  // keys for precise scroll positioning

  const ContentBody({
    super.key,
    required this.content,
    this.title = '',
    required this.fontSize,
    required this.isDark,
    this.searchQuery = '',
    this.activeSearchMatchIndex = 0,
    this.bookmarks = const [],
    this.flashChunkIndex,
    this.flashLocalStart,
    this.flashLocalEnd,
    this.highlightOpacity = 0.0,
    this.activeBookmarkChunkIndex,
    this.activeBookmarkLocalStart,
    this.activeBookmarkLocalEnd,
    this.chunkKeys = const {},
  });

  /// Check if this content has multiple sections (sub-ahzab)
  bool get _hasMultipleSections {
    final matches = _sectionPattern.allMatches(content);
    return matches.length > 1;
  }

  @override
  Widget build(BuildContext context) {
    // Multi-section content: skip outer frame, each section has its own inner frame
    if (_hasMultipleSections) {
      final accent = isDark ? AppColors.gold : AppColors.emeraldGreen;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ornamentalBand(
            accent,
            accent.withValues(alpha: isDark ? 0.18 : 0.12),
            accent.withValues(alpha: isDark ? 0.08 : 0.05),
            label: title,
          ),
          const SizedBox(height: 4),
          content.isNotEmpty ? _buildContent() : _buildEmptyState(),
        ],
      );
    }

    final accent = isDark ? AppColors.gold : AppColors.emeraldGreen;
    final accentSoft = accent.withValues(alpha: isDark ? 0.18 : 0.12);
    final accentFaint = accent.withValues(alpha: isDark ? 0.08 : 0.05);

    return Container(
      // Outer frame
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
          width: 1,
        ),
        boxShadow: [
          // Soft depth shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          // Subtle inner glow
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.04 : 0.02),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
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
                child: RepaintBoundary(child: _sideOrnament(accent, isDark)),
              ),
              // Right side ornamental border
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: RepaintBoundary(child: _sideOrnament(accent, isDark)),
              ),

              // Corner ornaments
              for (final corner in _Corner.values)
                Positioned(
                  top: corner.isTop ? 0 : null,
                  bottom: corner.isTop ? null : 0,
                  left: corner.isLeft ? 0 : null,
                  right: corner.isLeft ? null : 0,
                  child: RepaintBoundary(
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: CustomPaint(
                        painter: _CornerPainter(
                          color: accent.withValues(alpha: isDark ? 0.25 : 0.15),
                          corner: corner,
                        ),
                      ),
                    ),
                  ),
                ),

              // Main content column
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top ornamental band — carries the hizb name
                  _ornamentalBand(accent, accentSoft, accentFaint, label: title),

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
                      padding: EdgeInsets.symmetric(
                        horizontal: fontSize > 24 ? 4.0 : 10.0,
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

  /// Decorative band at top/bottom of the frame.
  /// When [label] is set it replaces the centre ornament with that text.
  Widget _ornamentalBand(Color accent, Color accentSoft, Color accentFaint,
      {String? label}) {
    final hasLabel = label != null && label.isNotEmpty;
    return Container(
      padding: EdgeInsets.symmetric(vertical: hasLabel ? 6 : 8),
      decoration: BoxDecoration(
        color: accentFaint,
        border: Border(
          bottom: BorderSide(color: accentSoft, width: 0.5),
          top: BorderSide(color: accentSoft, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(child: _gradientLine(accent, true)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: _eightPointStar(accent, 5),
          ),
          if (hasLabel)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    color: accent,
                  ),
                ),
              ),
            )
          else
            Text(
              ' ۞ ',
              style: TextStyle(
                fontSize: 12,
                color: accent.withValues(alpha: 0.35),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: _eightPointStar(accent, 5),
          ),
          Expanded(child: _gradientLine(accent, false)),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  /// Side border with repeating diamond dots
  Widget _sideOrnament(Color accent, bool isDark) {
    return SizedBox(
      width: 6,
      child: CustomPaint(
        painter: _SideBorderPainter(
          color: accent.withValues(alpha: isDark ? 0.08 : 0.05),
          dotColor: accent.withValues(alpha: isDark ? 0.14 : 0.08),
        ),
      ),
    );
  }

  static final _sectionPattern = RegExp(r'§SECTION§(.+?)§SECTION§');
  static final _multiNewlinePattern = RegExp(r'\n{3,}');
  static final _doubleNewlinePattern = RegExp(r'\n{2}');
  static final _multiSpacePattern = RegExp(r' {2,}');

  /// Small centred tinted basmala, as it appeared in the old header card.
  Widget _basmala() {
    final accent = isDark ? AppColors.gold : AppColors.emeraldGreen;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        'بسم الله الرحمن الرحيم',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'ScheherazadeNew',
          color: accent.withValues(alpha: 0.55),
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.5,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildContent() {
    int globalSearchOffset = 0;
    int chunkIndex = 0;

    Widget buildText(String text) {
      final idx = chunkIndex;
      chunkIndex++;
      final result = _buildBodyText(text, globalSearchOffset, idx);
      if (searchQuery.isNotEmpty) {
        final normalizedQuery = normalizeArabic(searchQuery);
        globalSearchOffset += findNormalizedMatches(text, normalizedQuery).length;
      }
      // Wrap with key for precise scroll positioning
      final key = chunkKeys[idx];
      return key != null ? KeyedSubtree(key: key, child: result) : result;
    }

    if (!content.contains('§SECTION§')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_basmala(), buildText(content)],
      );
    }

    // Parse sections: collect (header, textAfter) pairs
    final sectionEntries = <({String? header, String text})>[];
    int lastEnd = 0;
    final matches = _sectionPattern.allMatches(content).toList();

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final before = content.substring(lastEnd, match.start).trim();
      if (before.isNotEmpty) {
        sectionEntries.add((header: null, text: before));
      }
      // Text after this section header until next section or end
      final textStart = match.end;
      final textEnd = (i + 1 < matches.length) ? matches[i + 1].start : content.length;
      final sectionText = content.substring(textStart, textEnd).trim();
      sectionEntries.add((header: match.group(1)!, text: sectionText));
      lastEnd = textEnd;
    }

    // Check if there are multiple sections (sub-ahzab needing inner frames)
    final sectionCount = sectionEntries.where((e) => e.header != null).length;
    final needsInnerFrames = sectionCount > 1;

    final parts = <Widget>[];

    for (final entry in sectionEntries) {
      if (entry.header != null && needsInnerFrames) {
        // Build inner framed card for this sub-hizb
        parts.add(_buildInnerSectionCard(
          title: entry.header!,
          body: entry.text.isNotEmpty ? buildText(entry.text) : null,
        ));
      } else if (entry.header != null) {
        // Single section — render flat as before
        parts.add(_buildSectionHeader(entry.header!));
        if (entry.text.isNotEmpty) {
          parts.add(buildText(entry.text));
        }
      } else {
        // Text before any section header
        if (entry.text.isNotEmpty) {
          parts.add(buildText(entry.text));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: parts,
    );
  }

  /// Inner framed card for sub-ahzab (e.g. الرزق, الحراسة, العفو)
  /// Matches the same ornamental style as the outer frame used for single ahzab
  Widget _buildInnerSectionCard({required String title, Widget? body}) {
    final accent = isDark ? AppColors.gold : AppColors.emeraldGreen;
    final accentSoft = accent.withValues(alpha: isDark ? 0.18 : 0.12);
    final accentFaint = accent.withValues(alpha: isDark ? 0.08 : 0.05);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.04 : 0.02),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            ),
            child: Stack(
              children: [
                // Subtle radial glow at top
                Positioned(
                  top: -60, left: 0, right: 0, height: 200,
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
                Positioned(top: 0, bottom: 0, left: 0,
                  child: RepaintBoundary(child: _sideOrnament(accent, isDark)),
                ),
                // Right side ornamental border
                Positioned(top: 0, bottom: 0, right: 0,
                  child: RepaintBoundary(child: _sideOrnament(accent, isDark)),
                ),
                // Corner ornaments
                for (final corner in _Corner.values)
                  Positioned(
                    top: corner.isTop ? 0 : null,
                    bottom: corner.isTop ? null : 0,
                    left: corner.isLeft ? 0 : null,
                    right: corner.isLeft ? null : 0,
                    child: RepaintBoundary(
                      child: SizedBox(
                        width: 36, height: 36,
                        child: CustomPaint(
                          painter: _CornerPainter(
                            color: accent.withValues(alpha: isDark ? 0.25 : 0.15),
                            corner: corner,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Main content column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top ornamental band with section title
                    _ornamentalBand(accent, accentSoft, accentFaint),

                    // Section title
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '﴾  $title  ﴿',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: fontSize * 0.95,
                              fontWeight: FontWeight.w700,
                              color: accent,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),

                    // Inner frame with content
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                          vertical: BorderSide(color: accentFaint, width: 1),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: fontSize > 24 ? 4.0 : 10.0,
                          vertical: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [_basmala(), if (body != null) body],
                        ),
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
      ),
    );
  }

  Widget _buildBodyText(String rawText, int searchMatchOffset, int chunkIdx) {
    // Collapse multiple blank lines into one newline, collapse multiple spaces,
    // but preserve single newlines so the text shows proper line breaks.
    final text = rawText
        .replaceAll(_multiNewlinePattern, '\n')
        .replaceAll(_doubleNewlinePattern, '\n')
        .replaceAll(_multiSpacePattern, ' ')
        .trim();

    final baseStyle = TextStyle(
      fontFamily: 'ScheherazadeNew',
      fontSize: fontSize,
      height: 1.9,
      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      fontWeight: FontWeight.w400,
      letterSpacing: fontSize > 24 ? 0.0 : 0.1,
    );

    final accentColor = isDark ? AppColors.gold : AppColors.emeraldGreen;

    // Collect all highlight ranges
    final allRanges = <_HighlightRange>[];

    // Search highlighting
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

    // Flash highlight — direct index, NO text searching
    if (flashChunkIndex == chunkIdx && flashLocalStart != null && flashLocalEnd != null && highlightOpacity > 0) {
      final s = flashLocalStart!.clamp(0, text.length);
      final e = flashLocalEnd!.clamp(s, text.length);
      if (e > s) {
        allRanges.add(_HighlightRange(s, e, _HighlightType.flash));
      }
    }

    // Active bookmark highlight — the bookmark we just navigated to
    if (activeBookmarkChunkIndex == chunkIdx && activeBookmarkLocalStart != null && activeBookmarkLocalEnd != null) {
      final s = activeBookmarkLocalStart!.clamp(0, text.length);
      final e = activeBookmarkLocalEnd!.clamp(s, text.length);
      if (e > s) {
        allRanges.add(_HighlightRange(s, e, _HighlightType.activeBookmark));
      }
    }

    // Bookmark subtle highlights — direct index per bookmark, NO text searching
    for (final bookmark in bookmarks) {
      if (bookmark.chunkIndex == chunkIdx) {
        // Skip if this is the active bookmark (already highlighted stronger above)
        if (activeBookmarkChunkIndex == chunkIdx &&
            activeBookmarkLocalStart == bookmark.localStart &&
            activeBookmarkLocalEnd == bookmark.localEnd) {
          continue;
        }
        final s = bookmark.localStart.clamp(0, text.length);
        final e = bookmark.localEnd.clamp(s, text.length);
        if (e > s) {
          allRanges.add(_HighlightRange(s, e, _HighlightType.bookmark));
        }
      }
    }

    // At large font sizes, justify creates ugly gaps between words
    final textAlign = fontSize > 26 ? TextAlign.right : TextAlign.justify;

    if (allRanges.isEmpty) {
      return Text(text, style: baseStyle, textAlign: textAlign, softWrap: true);
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
        case _HighlightType.activeBookmark:
          // Stronger, premium highlight for the actively navigated bookmark
          hlStyle = TextStyle(
            fontWeight: FontWeight.w600,
            backgroundColor: isDark
                ? AppColors.gold.withValues(alpha: 0.28)
                : AppColors.emeraldGreen.withValues(alpha: 0.18),
            decoration: TextDecoration.underline,
            decorationColor: accentColor.withValues(alpha: 0.35),
            decorationStyle: TextDecorationStyle.solid,
            decorationThickness: 2.0,
          );
        case _HighlightType.bookmark:
          // Clean, light, premium subtle highlight
          hlStyle = TextStyle(
            backgroundColor: isDark
                ? AppColors.gold.withValues(alpha: 0.10)
                : AppColors.emeraldGreen.withValues(alpha: 0.07),
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
      textAlign: textAlign,
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
enum _HighlightType { searchActive, search, flash, activeBookmark, bookmark }

class _HighlightRange {
  final int start;
  final int end;
  final _HighlightType type;
  const _HighlightRange(this.start, this.end, this.type);
}
