import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/arabic_normalizer.dart';
import '../../../core/kashida.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/bookmarks_provider.dart';

class ContentBody extends StatelessWidget {
  final String content;
  final String title;

  static const String mushafFont = 'UthmanicHafs';

  /// Splits blank-line separated blocks into individually framed du'as.
  final bool separateParagraphs;

  /// Set to [mushafFont] to typeset the whole hizb in the Qur'anic face.
  final String bodyFontFamily;

  /// While a pinch is in flight the kashida pass is skipped — it is too heavy
  /// to redo on every frame.
  final bool isScaling;
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
    this.separateParagraphs = false,
    this.bodyFontFamily = 'ScheherazadeNew',
    this.isScaling = false,
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

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) return _buildEmptyState();
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize > 24 ? 8.0 : 14.0,
        vertical: 8,
      ),
      child: _buildContent(),
    );
  }

  static final _sectionPattern = RegExp(r'§SECTION§(.+?)§SECTION§');
  static final _multiNewlinePattern = RegExp(r'\n{3,}');
  static final _doubleNewlinePattern = RegExp(r'\n{2}');
  static final _multiSpacePattern = RegExp(r' {2,}');

  /// Drops a basmala the text already opens with, since one is drawn above it.
  static String _stripLeadingBasmala(String text) {
    final trimmed = text.trimLeft();
    final matches = findNormalizedMatches(trimmed, 'بسم الله الرحمن الرحيم');
    if (matches.isEmpty) return text;
    final (start, end) = matches.first;
    if (start > 2) return text;
    return trimmed
        .substring(end)
        .replaceFirst(RegExp(r'^[\s*.،ـ\u0640]+'), '');
  }

  /// Calligraphic bismillah ligature (U+FDFD) — Amiri renders it Quran-style.
  Widget _basmala() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '\uFDFD',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 46,
            height: 1.6,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
      ),
    );
  }

  static final _blankLinePattern = RegExp(r'\n\s*\n');

  /// One block per du'a, each with its attribution line and a divider between.
  /// A block whose whole body is the basmala renders the calligraphic form,
  /// so it is never repeated as plain text.
  Widget _buildSeparatedDuas(Widget Function(String) buildText) {
    final blocks = content
        .split(_blankLinePattern)
        .map((b) => b.trim())
        .where((b) => b.isNotEmpty)
        .toList();

    final parts = <Widget>[];

    for (var block in blocks) {
      String? heading;
      final nl = block.indexOf('\n');
      if (nl > 0) {
        final first = block.substring(0, nl).trim();
        if (first.endsWith(':') && first.length <= 90) {
          heading = first.substring(0, first.length - 1).trim();
          block = block.substring(nl + 1).trim();
        }
      }
      if (block.isEmpty) continue;

      if (parts.isNotEmpty) parts.add(_duaDivider());
      if (heading != null && heading.isNotEmpty) parts.add(_duaHeading(heading));

      if (_stripLeadingBasmala(block).trim().isEmpty) {
        parts.add(_basmala());
      } else {
        parts.add(buildText(block));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: parts,
    );
  }

  Widget _duaHeading(String text) {
    final accent = isDark ? AppColors.gold : AppColors.emeraldGreen;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: fontSize * 0.8,
          fontWeight: FontWeight.w700,
          height: 1.6,
          color: accent,
        ),
      ),
    );
  }

  Widget _duaDivider() {
    final accent = isDark ? AppColors.gold : AppColors.emeraldGreen;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Row(
        children: [
          Expanded(child: _gradientLine(accent, true)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _eightPointStar(accent, 4),
          ),
          Text(
            '۞',
            style: TextStyle(
              fontSize: 15,
              color: accent.withValues(alpha: 0.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _eightPointStar(accent, 4),
          ),
          Expanded(child: _gradientLine(accent, false)),
        ],
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
        globalSearchOffset +=
            findNormalizedMatches(text, normalizedQuery, wholeWord: true).length;
      }
      // Wrap with key for precise scroll positioning
      final key = chunkKeys[idx];
      return key != null ? KeyedSubtree(key: key, child: result) : result;
    }

    if (!content.contains('§SECTION§')) {
      if (separateParagraphs) {
        return _buildSeparatedDuas(buildText);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_basmala(), buildText(_stripLeadingBasmala(content))],
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

    final parts = <Widget>[];

    for (final entry in sectionEntries) {
      // Every sub-hizb gets a plain heading; the framed card read as clutter.
      if (entry.header != null) {
        parts.add(_buildSectionHeader(entry.header!));
      }
      if (entry.text.isNotEmpty) {
        final body = _stripLeadingBasmala(entry.text);
        if (body.length != entry.text.length) parts.add(_basmala());
        parts.add(buildText(body));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: parts,
    );
  }

  /// `§B§ … §b§` frames a passage the hizb asks you to repeat. Frames nest.
  static const String frameOpen = '§B§';
  static const String frameClose = '§b§';

  /// `{ ثلاثاً }` and the like: the count is drawn in the accent colour.
  static final _labelPattern = RegExp(r'\{[^}]*\}');

  /// `§Q§reference|uthmani text§Q§` — a verbatim Qur'anic passage.
  static final _quranPattern = RegExp(r'§Q§(.+?)\|(.+?)§Q§', dotAll: true);

  /// Strips the markers and reports what each one covered in the output text.
  static _Markup _parseMarkup(String src) {
    if (!src.contains('§')) {
      return _Markup.empty(src);
    }
    final buf = StringBuffer();
    final verses = <(int, int)>[];
    final frames = <(int, int)>[];
    final inner = <(int, int)>[];
    final quranFrames = <(int, int)>[];
    final open = <int>[];
    int i = 0;
    while (i < src.length) {
      if (src.startsWith(frameOpen, i)) {
        open.add(buf.length);
        i += frameOpen.length;
        continue;
      }
      if (src.startsWith(frameClose, i)) {
        if (open.isNotEmpty) {
          final start = open.removeLast();
          if (buf.length > start) {
            (open.isEmpty ? frames : inner).add((start, buf.length));
          }
        }
        i += frameClose.length;
        continue;
      }
      if (src.startsWith('§Q§', i)) {
        final m = _quranPattern.matchAsPrefix(src, i);
        if (m != null) {
          final openAt = buf.length;
          buf.write('\uFD3F ');
          quranFrames.add((openAt, buf.length));
          final verseStart = buf.length;
          buf.write(m.group(2)!.trim());
          verses.add((verseStart, buf.length));
          final close = buf.length;
          buf.write(' \uFD3E');
          quranFrames.add((close, buf.length));
          i = m.end;
          continue;
        }
      }
      buf.write(src[i]);
      i++;
    }
    return _Markup(buf.toString(), verses, frames, inner, quranFrames);
  }

  /// Resolves the markup exactly as the body does, for index-space parity.
  static String stripMarkup(String raw) => _parseMarkup(raw).text;

  bool get _isMushaf => bodyFontFamily == mushafFont;

  /// The mushaf face has a larger optical size, so it is set slightly smaller.
  double get _bodySize => _isMushaf ? fontSize * 0.95 : fontSize;
  double get _bodyHeight => _isMushaf ? 2.15 : 1.9;

  Widget _buildBodyText(String rawText, int searchMatchOffset, int chunkIdx) {
    // Collapse multiple blank lines into one newline, collapse multiple spaces,
    // but preserve single newlines so the text shows proper line breaks.
    final cleaned = rawText
        .replaceAll(_multiNewlinePattern, '\n')
        .replaceAll(_doubleNewlinePattern, '\n')
        .replaceAll(_multiSpacePattern, ' ')
        .trim();
    final markup = _parseMarkup(cleaned);
    final source = markup.text;

    final baseStyle = TextStyle(
      fontFamily: bodyFontFamily,
      fontSize: _bodySize,
      height: _bodyHeight,
      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      fontWeight: FontWeight.w400,
      letterSpacing: _isMushaf || fontSize > 24 ? 0.0 : 0.1,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final kashida = (isScaling || !width.isFinite)
            ? KashidaJustifier.identity(source)
            : KashidaJustifier.resolve(
                source,
                baseStyle,
                width,
                // Only the ornaments measure differently; a colour change does
                // not, so a repeated passage still justifies with the rest.
                skipRanges: [
                  ...markup.verses,
                  ...markup.quranFrames,
                ],
              );
        return _buildStyledText(
          kashida,
          markup,
          baseStyle,
          searchMatchOffset,
          chunkIdx,
        );
      },
    );
  }

  /// Merges the mushaf, repeat and ornament ranges into one ordered list of
  /// non-overlapping spans, so an inner style survives inside an outer one.
  List<_Overlay> _buildOverlays({
    required String text,
    required List<(int, int)> verses,
    required List<(int, int)> frames,
    required List<(int, int)> smallFrames,
    required List<(int, int)> quranFrames,
  }) {
    final accent = isDark ? AppColors.gold : AppColors.emeraldGreen;
    final verseStyle = TextStyle(
      fontFamily: mushafFont,
      fontSize: fontSize * 0.95,
      height: 2.15,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    );
    // Colour alone marks a repeat: brackets mirror in Arabic, so the opening
    // one ends up looking like the closing one.
    final frameStyle = TextStyle(color: accent);
    final smallFrameStyle = frameStyle;
    final quranFrameStyle = TextStyle(
      fontFamily: 'Amiri',
      fontSize: fontSize * 0.85,
      height: 2.15,
      color: accent,
      letterSpacing: 0,
    );
    final bodyColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    // Ordered outermost first: later layers are merged over earlier ones.
    final layers = <_Overlay>[
      for (final (s, e) in frames) _Overlay(s, e, frameStyle),
      for (final (s, e) in smallFrames) _Overlay(s, e, smallFrameStyle),
      for (final (s, e) in verses) _Overlay(s, e, verseStyle),
      for (final (s, e) in quranFrames) _Overlay(s, e, quranFrameStyle),
      // The count reads as an instruction, not as part of the litany.
      for (final m in _labelPattern.allMatches(text))
        _Overlay(m.start, m.end, TextStyle(color: bodyColor)),
    ];
    if (layers.isEmpty) return const [];

    final edges = <int>{};
    for (final o in layers) {
      edges.add(o.start);
      edges.add(o.end);
    }
    final sorted = edges.toList()..sort();
    final out = <_Overlay>[];
    for (var i = 0; i + 1 < sorted.length; i++) {
      final s = sorted[i], e = sorted[i + 1];
      TextStyle? merged;
      for (final o in layers) {
        if (o.start <= s && o.end >= e) {
          merged = merged == null ? o.style : merged.merge(o.style);
        }
      }
      if (merged != null) out.add(_Overlay(s, e, merged));
    }
    return out;
  }

  Widget _buildStyledText(
    KashidaText kashida,
    _Markup markup,
    TextStyle baseStyle,
    int searchMatchOffset,
    int chunkIdx,
  ) {
    final text = kashida.text;
    List<(int, int)> remap(List<(int, int)> src) => src
        .map((r) => (kashida.mapIndex(r.$1), kashida.mapIndex(r.$2)))
        .toList();
    final overlays = _buildOverlays(
      text: text,
      verses: remap(markup.verses),
      frames: remap(markup.frames),
      smallFrames: remap(markup.smallFrames),
      quranFrames: remap(markup.quranFrames),
    );

    final accentColor = isDark ? AppColors.gold : AppColors.emeraldGreen;

    // Collect all highlight ranges
    final allRanges = <_HighlightRange>[];

    // Search highlighting
    int searchMatchCount = 0;
    if (searchQuery.isNotEmpty) {
      final normalizedQuery = normalizeArabic(searchQuery);
      for (final (start, end)
          in findNormalizedMatches(text, normalizedQuery, wholeWord: true)) {
        final globalIdx = searchMatchOffset + searchMatchCount;
        final isActive = globalIdx == activeSearchMatchIndex;
        allRanges.add(_HighlightRange(start, end,
            isActive ? _HighlightType.searchActive : _HighlightType.search));
        searchMatchCount++;
      }
    }

    // Flash highlight — direct index, NO text searching
    if (flashChunkIndex == chunkIdx && flashLocalStart != null && flashLocalEnd != null && highlightOpacity > 0) {
      final s = kashida.mapIndex(flashLocalStart!).clamp(0, text.length);
      final e = kashida.mapIndex(flashLocalEnd!).clamp(s, text.length);
      if (e > s) {
        allRanges.add(_HighlightRange(s, e, _HighlightType.flash));
      }
    }

    // Active bookmark highlight — the bookmark we just navigated to
    if (activeBookmarkChunkIndex == chunkIdx && activeBookmarkLocalStart != null && activeBookmarkLocalEnd != null) {
      final s = kashida.mapIndex(activeBookmarkLocalStart!).clamp(0, text.length);
      final e = kashida.mapIndex(activeBookmarkLocalEnd!).clamp(s, text.length);
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
        final s = kashida.mapIndex(bookmark.localStart).clamp(0, text.length);
        final e = kashida.mapIndex(bookmark.localEnd).clamp(s, text.length);
        if (e > s) {
          allRanges.add(_HighlightRange(s, e, _HighlightType.bookmark));
        }
      }
    }

    // Kashida already fills each line; justify only absorbs the leftover pixels.
    const textAlign = TextAlign.justify;

    if (allRanges.isEmpty && overlays.isEmpty) {
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

    // Emits a slice, splitting it wherever a font/weight overlay applies.
    void addSpan(int start, int end, TextStyle? style) {
      if (end <= start) return;
      int cur = start;
      for (final overlay in overlays) {
        if (overlay.end <= cur || overlay.start >= end) continue;
        if (overlay.start > cur) {
          spans.add(TextSpan(text: text.substring(cur, overlay.start), style: style));
        }
        final s = math.max(overlay.start, cur);
        final e = math.min(overlay.end, end);
        var applied = overlay.style;
        if (style?.color != null) applied = applied.copyWith(color: style!.color);
        spans.add(TextSpan(
          text: text.substring(s, e),
          style: (style ?? const TextStyle()).merge(applied),
        ));
        cur = e;
      }
      if (cur < end) {
        spans.add(TextSpan(text: text.substring(cur, end), style: style));
      }
    }

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
      addSpan(cursor, range.start, null);

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

      addSpan(range.start, range.end, hlStyle);
      cursor = range.end;
    }

    addSpan(cursor, text.length, null);

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

// Highlight types ordered by priority (lowest index = highest priority)
enum _HighlightType { searchActive, search, flash, activeBookmark, bookmark }

class _Overlay {
  final int start;
  final int end;
  final TextStyle style;
  const _Overlay(this.start, this.end, this.style);
}

class _Markup {
  final String text;
  final List<(int, int)> verses;

  /// A passage the hizb asks you to repeat, shown in the accent colour.
  final List<(int, int)> frames;

  /// A repeat nested inside another repeat.
  final List<(int, int)> smallFrames;

  /// Ornate brackets that mark a Qur'anic passage.
  final List<(int, int)> quranFrames;

  const _Markup(this.text, this.verses, this.frames, this.smallFrames,
      this.quranFrames);

  const _Markup.empty(this.text)
      : verses = const [],
        frames = const [],
        smallFrames = const [],
        quranFrames = const [];
}

class _HighlightRange {
  final int start;
  final int end;
  final _HighlightType type;
  const _HighlightRange(this.start, this.end, this.type);
}
