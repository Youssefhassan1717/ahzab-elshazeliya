import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport, RenderParagraph;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/arabic_normalizer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/smooth_scroll_physics.dart';
import '../../models/hizb_part.dart';
import '../../providers/bookmarks_provider.dart';
import '../../providers/favorites_provider.dart';
import 'widgets/bookmarks_panel.dart';
import 'widgets/content_body.dart';
import 'widgets/detail_header.dart';
import 'widgets/zoom_instructions.dart';

class DetailScreen extends StatefulWidget {
  final HizbPart part;
  final String searchQuery;

  const DetailScreen({super.key, required this.part, this.searchQuery = ''});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with TickerProviderStateMixin {
  static const double _baseFontSize = 16.0;
  static const double _minFontSize = 10.0;
  static const double _maxFontSize = 44.0;

  // Zoom state — raw pointer driven
  final ValueNotifier<double> _fontSizeNotifier = ValueNotifier(_baseFontSize);
  double _fontSize = _baseFontSize;
  final Map<int, Offset> _pointers = {}; // active pointer positions
  double _initialDistance = 0.0; // finger distance at pinch start
  double _fontSizeAtPinchStart = _baseFontSize; // fontSize when pinch began
  int _lastSmoothTime = 0; // microsecond timestamp for time-based smoothing
  static const double _smoothK = 12.0; // smoothing stiffness
  bool _isScaling = false;

  // Flash highlight for bookmark navigation (exact position, no text search)
  int? _flashChunkIndex;
  int? _flashLocalStart;
  int? _flashLocalEnd;

  // Active bookmark — persists after flash fades to keep it highlighted
  int? _activeBookmarkChunkIndex;
  int? _activeBookmarkLocalStart;
  int? _activeBookmarkLocalEnd;

  // Bookmark navigation state
  int _currentBookmarkIndex = -1;
  bool _showBookmarkNav = false;

  // GlobalKeys for each text chunk — for precise scroll positioning
  final Map<int, GlobalKey> _chunkKeys = {};
  // GlobalKey for the scroll view — used to get exact viewport screen position
  final GlobalKey _scrollViewKey = GlobalKey();

  // AppBar hide/show on scroll
  // Drives the floating header only, so scrolling never rebuilds the hizb text.
  final ValueNotifier<double> _appBarVisibility = ValueNotifier<double>(1.0);
  double _lastScrollOffset = 0.0;

  // Search match navigation
  List<(int, int)> _searchMatches = [];
  int _currentMatchIndex = 0;

  final ScrollController _scrollController = ScrollController();

  late final AnimationController _animController;
  late final AnimationController _highlightController;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scrollController.addListener(_onScroll);

    // Pre-create GlobalKeys for each text chunk
    final chunks = _splitChunks(widget.part.content);
    for (int i = 0; i < chunks.length; i++) {
      _chunkKeys[i] = GlobalKey();
    }

    // Preload bookmarks for this hizb from disk
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookmarksProvider>().ensureLoaded(widget.part.id);
    });

    // Compute all search matches and scroll to first
    if (widget.searchQuery.isNotEmpty) {
      _computeSearchMatches();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && _searchMatches.isNotEmpty) {
            _scrollToMatchIndex(0);
          }
        });
      });
    }
  }

  /// Cleans content the same way _buildBodyText does for consistent position mapping.
  static final _sectionCleanPattern = RegExp(r'§SECTION§.+?§SECTION§');
  static final _multiNewlinePattern = RegExp(r'\n{3,}');
  static final _doubleNewlinePattern = RegExp(r'\n{2}');
  static final _multiSpacePattern = RegExp(r' {2,}');

  String _cleanContent(String raw) {
    return raw
        .replaceAll(_sectionCleanPattern, ' ')
        .replaceAll(_multiNewlinePattern, '\n')
        .replaceAll(_doubleNewlinePattern, '\n')
        .replaceAll(_multiSpacePattern, ' ')
        .trim();
  }

  static final _sectionPattern = RegExp(r'§SECTION§(.+?)§SECTION§');

  /// Splits content into text chunks the same way ContentBody does.
  static List<String> _splitChunks(String content) {
    if (!content.contains('§SECTION§')) return [content];
    final chunks = <String>[];
    int lastEnd = 0;
    for (final match in _sectionPattern.allMatches(content)) {
      final before = content.substring(lastEnd, match.start).trim();
      if (before.isNotEmpty) chunks.add(before);
      lastEnd = match.end;
    }
    final after = content.substring(lastEnd).trim();
    if (after.isNotEmpty) chunks.add(after);
    return chunks;
  }

  /// Cleans a chunk the same way _buildBodyText does.
  static String _cleanChunk(String raw) {
    return raw
        .replaceAll(_multiNewlinePattern, '\n')
        .replaceAll(_doubleNewlinePattern, '\n')
        .replaceAll(_multiSpacePattern, ' ')
        .trim();
  }

  void _computeSearchMatches() {
    final cleanContent = _cleanContent(widget.part.content);
    final normalizedQuery = normalizeArabic(widget.searchQuery);
    _searchMatches = findNormalizedMatches(cleanContent, normalizedQuery);
    _currentMatchIndex = 0;
  }

  void _scrollToMatchIndex(int index) {
    if (_searchMatches.isEmpty || !_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    setState(() => _currentMatchIndex = index);

    final cleanContent = _cleanContent(widget.part.content);
    final (matchStart, _) = _searchMatches[index];
    final fraction = matchStart / cleanContent.length;
    final viewportHeight = _scrollController.position.viewportDimension;
    final totalScrollableHeight = maxScroll + viewportHeight;

    const contentStartOffset = 270.0;
    const contentEndPadding = 112.0;
    final contentBodyHeight = totalScrollableHeight - contentStartOffset - contentEndPadding;
    final matchPixelPos = contentStartOffset + (fraction * contentBodyHeight);
    final targetOffset = (matchPixelPos - viewportHeight * 0.35).clamp(0.0, maxScroll);

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  void _nextMatch() {
    if (_searchMatches.isEmpty) return;
    HapticFeedback.selectionClick();
    final next = (_currentMatchIndex + 1) % _searchMatches.length;
    _scrollToMatchIndex(next);
  }

  void _prevMatch() {
    if (_searchMatches.isEmpty) return;
    HapticFeedback.selectionClick();
    final prev = (_currentMatchIndex - 1 + _searchMatches.length) % _searchMatches.length;
    _scrollToMatchIndex(prev);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _animController.dispose();
    _highlightController.dispose();
    _scrollController.dispose();
    _fontSizeNotifier.dispose();
    _appBarVisibility.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final delta = offset - _lastScrollOffset;
    _lastScrollOffset = offset;

    // At the very top, always show
    if (offset <= 0) {
      _appBarVisibility.value = 1.0;
      return;
    }

    // Scrolling down → hide, scrolling up → show
    // Use delta sensitivity for smooth transition
    double newVisibility = _appBarVisibility.value - (delta / 80.0);
    newVisibility = newVisibility.clamp(0.0, 1.0);

    // Snap to fully hidden/shown to avoid lingering partial states
    if (newVisibility < 0.05) newVisibility = 0.0;
    if (newVisibility > 0.95) newVisibility = 1.0;

    if ((newVisibility - _appBarVisibility.value).abs() > 0.01) {
      _appBarVisibility.value = newVisibility;
    }
  }

  // ── Raw pointer zoom ──────────────────────────────────────────────
  double _fingerDistance() {
    if (_pointers.length < 2) return 0.0;
    final pts = _pointers.values.toList();
    final dx = pts[0].dx - pts[1].dx;
    final dy = pts[0].dy - pts[1].dy;
    return math.sqrt(dx * dx + dy * dy);
  }

  void _onPointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.position;
    if (_pointers.length == 2) {
      // Pinch started — capture baseline
      _initialDistance = _fingerDistance();
      _fontSizeAtPinchStart = _fontSize;
      _lastSmoothTime = DateTime.now().microsecondsSinceEpoch;
      if (!_isScaling) {
        _isScaling = true;
        // Stop any running reset animation
        _animController.stop();
        _animation?.removeListener(_onAnimationTick);
        setState(() {}); // disable scroll
      }
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.position;
    if (_pointers.length == 2 && _isScaling && _initialDistance > 0) {
      final currentDist = _fingerDistance();
      final scaleFactor = currentDist / _initialDistance;

      // Logarithmic mapping → target font size
      final targetSize = (_fontSizeAtPinchStart * scaleFactor)
          .clamp(_minFontSize, _maxFontSize);

      // Time-based exponential smoothing
      final now = DateTime.now().microsecondsSinceEpoch;
      final dt = (now - _lastSmoothTime) / 1e6; // seconds
      _lastSmoothTime = now;
      final alpha = 1.0 - math.exp(-_smoothK * dt.clamp(0.001, 0.1));

      final smoothed = _fontSize + (targetSize - _fontSize) * alpha;
      final clamped = smoothed.clamp(_minFontSize, _maxFontSize);

      if ((clamped - _fontSize).abs() > 0.01) {
        _fontSize = clamped;
        _fontSizeNotifier.value = _fontSize;
      }
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.length < 2 && _isScaling) {
      _isScaling = false;
      _pointers.clear();
      setState(() {}); // re-enable scroll
    }
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.length < 2 && _isScaling) {
      _isScaling = false;
      _pointers.clear();
      setState(() {});
    }
  }

  void _animateToFontSize(double target, Duration duration) {
    _animController.duration = duration;
    
    _animation = Tween<double>(
      begin: _fontSize,
      end: target,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animation!.addListener(_onAnimationTick);
    _animController.forward(from: 0).then((_) {
      _animation?.removeListener(_onAnimationTick);
    });
  }

  void _onAnimationTick() {
    if (_animation != null) {
      _fontSize = _animation!.value;
      _fontSizeNotifier.value = _fontSize;
    }
  }

  void _resetZoom() {
    if (_fontSize == _baseFontSize) return;
    HapticFeedback.lightImpact();
    _animateToFontSize(_baseFontSize, const Duration(milliseconds: 300));
  }

  Widget _buildZoomableContent(bool isDark, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          child: DetailHeader(
            title: widget.part.title,
            subtitle: widget.part.subtitle,
            fontSize: fontSize,
          ),
        ),
        const SizedBox(height: 20),
        RepaintBoundary(
          child: Consumer<BookmarksProvider>(
            builder: (context, bookProvider, _) {
              final bookmarks =
                  bookProvider.getBookmarksList(widget.part.id);
              return AnimatedBuilder(
                animation: _highlightController,
                builder: (context, _) {
                  return ContentBody(
                    content: widget.part.content,
                    fontSize: fontSize,
                    isDark: isDark,
                    searchQuery: widget.searchQuery,
                    activeSearchMatchIndex: _currentMatchIndex,
                    bookmarks: bookmarks,
                    flashChunkIndex: _flashChunkIndex,
                    flashLocalStart: _flashLocalStart,
                    flashLocalEnd: _flashLocalEnd,
                    highlightOpacity: _flashChunkIndex != null
                        ? (1.0 - _highlightController.value).clamp(0.0, 1.0)
                        : 0.0,
                    activeBookmarkChunkIndex: _activeBookmarkChunkIndex,
                    activeBookmarkLocalStart: _activeBookmarkLocalStart,
                    activeBookmarkLocalEnd: _activeBookmarkLocalEnd,
                    chunkKeys: _chunkKeys,
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        const ZoomInstructions(),
      ],
    );
  }

  /// Walks the render tree from a GlobalKey to find the actual RenderParagraph.
  RenderParagraph? _findRenderParagraph(GlobalKey key) {
    final renderObj = key.currentContext?.findRenderObject();
    if (renderObj == null) return null;
    if (renderObj is RenderParagraph) return renderObj;
    RenderParagraph? result;
    void visitor(RenderObject child) {
      if (result != null) return;
      if (child is RenderParagraph) {
        result = child;
        return;
      }
      child.visitChildren(visitor);
    }
    renderObj.visitChildren(visitor);
    return result;
  }

  /// Scrolls to make a specific character range visible using
  /// getOffsetToReveal with the character's rect, which correctly handles
  /// nested RepaintBoundary, SelectionArea, and large paragraphs.
  void _scrollToCharInChunk(int chunkIndex, int localStart, {int? localEnd}) {
    if (!_scrollController.hasClients) return;

    final chunkKey = _chunkKeys[chunkIndex];
    if (chunkKey == null) return;

    final rp = _findRenderParagraph(chunkKey);
    if (rp == null) return;

    final viewport = RenderAbstractViewport.of(rp);

    // Get the exact bounding box of the bookmarked range within the paragraph,
    // then pass it as `rect` to getOffsetToReveal so Flutter computes
    // the correct scroll offset — even for huge single-chunk paragraphs.
    final chunks = _splitChunks(widget.part.content);
    if (chunkIndex < chunks.length) {
      final cleanText = _cleanChunk(chunks[chunkIndex]);
      if (cleanText.isNotEmpty) {
        final clampedStart = localStart.clamp(0, cleanText.length);
        // Use the full bookmark range if provided, otherwise single char
        final clampedEnd = (localEnd ?? (clampedStart + 1)).clamp(clampedStart, cleanText.length);
        final boxes = rp.getBoxesForSelection(
          TextSelection(baseOffset: clampedStart, extentOffset: clampedEnd),
        );
        if (boxes.isNotEmpty) {
          // Use just the first box's position — we want to scroll to where
          // the bookmark starts, not the center of a multi-line range
          final charRect = boxes.first.toRect();
          final offsetToReveal =
              viewport.getOffsetToReveal(rp, 0.3, rect: charRect);
          final maxScroll = _scrollController.position.maxScrollExtent;

          _scrollController.animateTo(
            offsetToReveal.offset.clamp(0.0, maxScroll),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
          return;
        }
      }
    }

    // Fallback: scroll to paragraph top
    final offsetToReveal = viewport.getOffsetToReveal(rp, 0.3);
    final maxScroll = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      offsetToReveal.offset.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToBookmark(Bookmark bookmark) {
    // Delay slightly so layout settles after bottom sheet dismisses
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToCharInChunk(bookmark.chunkIndex, bookmark.localStart, localEnd: bookmark.localEnd);
    });

    // Set persistent active bookmark highlight
    setState(() {
      _activeBookmarkChunkIndex = bookmark.chunkIndex;
      _activeBookmarkLocalStart = bookmark.localStart;
      _activeBookmarkLocalEnd = bookmark.localEnd;
      _flashChunkIndex = bookmark.chunkIndex;
      _flashLocalStart = bookmark.localStart;
      _flashLocalEnd = bookmark.localEnd;
    });

    // Flash highlight fades, but active bookmark stays
    _highlightController.forward(from: 0).then((_) {
      if (mounted) setState(() {
        _flashChunkIndex = null;
        _flashLocalStart = null;
        _flashLocalEnd = null;
      });
    });
  }

  void _navigateToBookmarkIndex(int index) {
    final bookmarks = context.read<BookmarksProvider>().getBookmarksList(widget.part.id);
    if (bookmarks.isEmpty) return;
    final clampedIndex = index.clamp(0, bookmarks.length - 1);
    setState(() {
      _currentBookmarkIndex = clampedIndex;
      _showBookmarkNav = true;
    });
    _scrollToBookmark(bookmarks[clampedIndex]);
  }

  void _nextBookmark() {
    final bookmarks = context.read<BookmarksProvider>().getBookmarksList(widget.part.id);
    if (bookmarks.isEmpty) return;
    HapticFeedback.selectionClick();
    final next = (_currentBookmarkIndex + 1) % bookmarks.length;
    _navigateToBookmarkIndex(next);
  }

  void _prevBookmark() {
    final bookmarks = context.read<BookmarksProvider>().getBookmarksList(widget.part.id);
    if (bookmarks.isEmpty) return;
    HapticFeedback.selectionClick();
    final prev = (_currentBookmarkIndex - 1 + bookmarks.length) % bookmarks.length;
    _navigateToBookmarkIndex(prev);
  }

  void _dismissBookmarkNav() {
    setState(() {
      _showBookmarkNav = false;
      _activeBookmarkChunkIndex = null;
      _activeBookmarkLocalStart = null;
      _activeBookmarkLocalEnd = null;
    });
  }

  void _scrollToText(String text) {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    final cleanContent = _cleanContent(widget.part.content);
    final normalizedQuery = normalizeArabic(text);
    final matches = findNormalizedMatches(cleanContent, normalizedQuery);
    if (matches.isEmpty) return;

    final (matchStart, _) = matches.first;
    final fraction = matchStart / cleanContent.length;
    final viewportHeight = _scrollController.position.viewportDimension;
    final totalScrollableHeight = maxScroll + viewportHeight;

    const contentStartOffset = 270.0;
    const contentEndPadding = 112.0;
    final contentBodyHeight = totalScrollableHeight - contentStartOffset - contentEndPadding;
    final matchPixelPos = contentStartOffset + (fraction * contentBodyHeight);
    final targetOffset = (matchPixelPos - viewportHeight * 0.35).clamp(0.0, maxScroll);

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
    );
  }

  void _showBookmarksPanel() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BookmarksPanel(
        hizbId: widget.part.id,
        onBookmarkTap: (bookmark) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted) return;
            // Find the index of this bookmark in the list
            final bookmarks = context.read<BookmarksProvider>().getBookmarksList(widget.part.id);
            final idx = bookmarks.indexWhere((b) =>
                b.chunkIndex == bookmark.chunkIndex &&
                b.localStart == bookmark.localStart);
            setState(() {
              _currentBookmarkIndex = idx >= 0 ? idx : 0;
              _showBookmarkNav = bookmarks.length > 1;
            });
            _scrollToBookmark(bookmark);
          });
        },
        onBookmarkRemoved: (bookmark) {
          // Clear highlight if the removed bookmark was the active one
          if (_activeBookmarkChunkIndex == bookmark.chunkIndex &&
              _activeBookmarkLocalStart == bookmark.localStart &&
              _activeBookmarkLocalEnd == bookmark.localEnd) {
            setState(() {
              _activeBookmarkChunkIndex = null;
              _activeBookmarkLocalStart = null;
              _activeBookmarkLocalEnd = null;
              _flashChunkIndex = null;
              _flashLocalStart = null;
              _flashLocalEnd = null;
            });
          }
          // Hide bookmark nav if no bookmarks left
          final remaining = context.read<BookmarksProvider>().getCount(widget.part.id);
          if (remaining == 0) {
            setState(() {
              _showBookmarkNav = false;
              _currentBookmarkIndex = -1;
            });
          }
        },
      ),
    );
  }

  void _addBookmark(String selectedText, {Offset? selectionScreenPos}) {
    if (selectedText.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    final trimmed = selectedText.trim();

    final chunks = _splitChunks(widget.part.content);
    final normalizedQuery = normalizeArabic(trimmed);

    int? targetChunkIdx;
    int? localStart;
    int? localEnd;

    // ── Strategy: Use getPositionForOffset for character-level precision ──
    // Convert the screen position to a character index via the render
    // paragraph, then pick the match whose range contains or is nearest
    // to that character. This is far more reliable than comparing 2D
    // distances between bounding-box centers and toolbar-anchor midpoints.
    if (selectionScreenPos != null) {
      for (final entry in _chunkKeys.entries) {
        final rp = _findRenderParagraph(entry.value);
        if (rp == null) continue;

        // Convert screen position to paragraph-local coordinates
        final localPos = rp.globalToLocal(selectionScreenPos);

        // Check if the position falls within this paragraph (with tolerance)
        final tolerance = _fontSize * 3;
        if (localPos.dy >= -tolerance && localPos.dy <= rp.size.height + tolerance) {
          // Find all matches in THIS chunk only
          final cleaned = _cleanChunk(chunks[entry.key]);
          final matches = findNormalizedMatches(cleaned, normalizedQuery);
          if (matches.isEmpty) continue;

          // Get the character index at the screen position
          final textPos = rp.getPositionForOffset(localPos);
          final charIdx = textPos.offset;

          // Pick the match whose range contains this character,
          // or failing that, the nearest match by character distance.
          int? bestStart, bestEnd;
          double bestDist = double.infinity;

          for (final (s, e) in matches) {
            if (charIdx >= s && charIdx < e) {
              // Character falls inside this match — exact hit
              bestStart = s;
              bestEnd = e;
              break;
            }
            // Distance from character to match midpoint
            final midpoint = (s + e) / 2;
            final dist = (charIdx - midpoint).abs();
            if (dist < bestDist) {
              bestDist = dist;
              bestStart = s;
              bestEnd = e;
            }
          }

          if (bestStart != null && bestEnd != null) {
            targetChunkIdx = entry.key;
            localStart = bestStart;
            localEnd = bestEnd;
            break; // Found match in this chunk, no need to check others
          }
        }
      }
    }

    // ── Fallback: first occurrence (should rarely happen) ──
    if (localStart == null) {
      for (int i = 0; i < chunks.length; i++) {
        final cleaned = _cleanChunk(chunks[i]);
        final matches = findNormalizedMatches(cleaned, normalizedQuery);
        if (matches.isNotEmpty) {
          targetChunkIdx = i;
          localStart = matches.first.$1;
          localEnd = matches.first.$2;
          break;
        }
      }
    }

    if (targetChunkIdx == null || localStart == null || localEnd == null) return;

    final provider = context.read<BookmarksProvider>();
    provider.addBookmark(
      widget.part.id, trimmed,
      chunkIndex: targetChunkIdx,
      localStart: localStart,
      localEnd: localEnd,
    );

    // Show brief feedback
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '\u062a\u0645 \u062d\u0641\u0638 \u0627\u0644\u0639\u0644\u0627\u0645\u0629',
          style: TextStyle(fontFamily: 'ScheherazadeNew'),
        ),
        backgroundColor: isDark ? AppColors.gold : AppColors.emeraldGreen,
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + kToolbarHeight;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Column(
          children: [
            Expanded(
              child: Stack(
          children: [
            // Main scrollable content
            Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: GestureDetector(
                onDoubleTap: _resetZoom,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                      selectionColor: AppColors.emeraldGreen.withValues(alpha: 0.25),
                      selectionHandleColor: AppColors.emeraldGreen,
                      cursorColor: AppColors.emeraldGreen,
                    ),
                  ),
                  child: SelectionArea(
                    contextMenuBuilder: _buildContextMenu,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: RawScrollbar(
                        controller: _scrollController,
                        thumbVisibility: false,
                        trackVisibility: false,
                        thickness: 4.5,
                        radius: const Radius.circular(8),
                        fadeDuration: const Duration(milliseconds: 400),
                        timeToFade: const Duration(milliseconds: 800),
                        thumbColor: isDark
                            ? AppColors.gold.withValues(alpha: 0.45)
                            : AppColors.emeraldGreen.withValues(alpha: 0.35),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                        minThumbLength: 80,
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: SingleChildScrollView(
                            key: _scrollViewKey,
                            controller: _scrollController,
                            physics: _isScaling
                                ? const NeverScrollableScrollPhysics()
                                : const SmoothScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            padding: EdgeInsets.fromLTRB(4, headerHeight + 12, 4, 32),
                            child: ValueListenableBuilder<double>(
                              valueListenable: _fontSizeNotifier,
                              builder: (context, currentFontSize, _) {
                                return _buildZoomableContent(isDark, currentFontSize);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Floating header — slides up & fades as one unified unit
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<double>(
                valueListenable: _appBarVisibility,
                builder: (context, visibility, child) {
                  final v = visibility.clamp(0.0, 1.0);
                  return ClipRect(
                    child: Transform.translate(
                      offset: Offset(0, -headerHeight * (1.0 - v)),
                      child: Opacity(
                        opacity: v,
                        child: IgnorePointer(ignoring: v < 0.1, child: child),
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    border: Border(
                      bottom: BorderSide(
                        color: (isDark ? AppColors.gold : AppColors.emeraldGreen).withValues(alpha: 0.12),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: kToolbarHeight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).maybePop();
                              },
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: Center(
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 20,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                  widget.part.title,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildBookmarkAction(isDark),
                            const SizedBox(width: 4),
                            _buildFavoriteAction(isDark),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Floating search navigation bar
            if (widget.searchQuery.isNotEmpty && _searchMatches.length > 1)
              Positioned(
                top: 8,
                left: 40,
                right: 40,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: _SearchNavBar(
                    currentIndex: _currentMatchIndex,
                    totalMatches: _searchMatches.length,
                    onNext: _nextMatch,
                    onPrev: _prevMatch,
                    isDark: isDark,
                  ),
                ),
              ),

            // Floating bookmark navigation bar
            if (_showBookmarkNav)
              Positioned(
                bottom: 24,
                left: 40,
                right: 40,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: _BookmarkNavBar(
                    currentIndex: _currentBookmarkIndex,
                    totalBookmarks: context.watch<BookmarksProvider>().getCount(widget.part.id),
                    onNext: _nextBookmark,
                    onPrev: _prevBookmark,
                    onDismiss: _dismissBookmarkNav,
                    isDark: isDark,
                  ),
                ),
              ),
          ],
        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextMenu(BuildContext context, SelectableRegionState selectableRegionState) {
    final isDk = Theme.of(context).brightness == Brightness.dark;
    final accent = isDk ? AppColors.gold : AppColors.emeraldGreen;
    final bg = isDk ? const Color(0xFF1A2E20) : const Color(0xFFF5F9F5);
    final textCol = isDk ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    return AdaptiveTextSelectionToolbar(
      anchors: selectableRegionState.contextMenuAnchors,
      children: [
        Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.25), width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: isDk ? 0.3 : 0.12), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMenuBtn(icon: Icons.copy_rounded, label: '\u0646\u0633\u062e', accent: accent, textColor: textCol, onTap: () {
                  selectableRegionState.copySelection(SelectionChangedCause.toolbar);
                  selectableRegionState.hideToolbar();
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
                    content: const Text('\u062a\u0645 \u0646\u0633\u062e \u0627\u0644\u0646\u0635', style: TextStyle(fontFamily: 'ScheherazadeNew')),
                    backgroundColor: isDk ? AppColors.gold : AppColors.emeraldGreen,
                    duration: const Duration(milliseconds: 1200),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  ));
                }),
                Container(width: 1, height: 28, color: accent.withValues(alpha: 0.15)),
                _buildMenuBtn(icon: Icons.bookmark_add_rounded, label: '\u0639\u0644\u0627\u0645\u0629 \u0645\u0645\u064a\u0632\u0629', accent: accent, textColor: textCol, onTap: () async {
                  // Capture selection position BEFORE clearing
                  final anchors = selectableRegionState.contextMenuAnchors;
                  final secondary = anchors.secondaryAnchor ?? anchors.primaryAnchor;
                  final selectionScreenPos = Offset(
                    (anchors.primaryAnchor.dx + secondary.dx) / 2,
                    (anchors.primaryAnchor.dy + secondary.dy) / 2,
                  );

                  selectableRegionState.copySelection(SelectionChangedCause.toolbar);
                  selectableRegionState.hideToolbar();
                  await Future.delayed(const Duration(milliseconds: 200));
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null && data!.text!.trim().isNotEmpty) {
                    _addBookmark(data.text!, selectionScreenPos: selectionScreenPos);
                  }
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookmarkAction(bool isDark) {
    final accent = isDark ? AppColors.gold : AppColors.emeraldGreen;
    return Consumer<BookmarksProvider>(
      builder: (context, bookProvider, _) {
        final count = bookProvider.getCount(widget.part.id);
        final hasBookmarks = count > 0;
        return GestureDetector(
          onTap: _showBookmarksPanel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: hasBookmarks ? accent.withValues(alpha: isDark ? 0.15 : 0.10) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: hasBookmarks ? Border.all(color: accent.withValues(alpha: 0.25), width: 1) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(hasBookmarks ? Icons.auto_stories_rounded : Icons.auto_stories_outlined, size: 20, color: accent),
                if (count > 1) ...[
                  const SizedBox(width: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: Text(
                      '$count',
                      key: ValueKey<int>(count),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Amiri', color: accent),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoriteAction(bool isDark) {
    return Consumer<FavoritesProvider>(
      builder: (context, favProvider, _) {
        final isFav = favProvider.isFavorite(widget.part.id);
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            favProvider.toggleFavorite(widget.part.id, context);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isFav ? Colors.red.shade600.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: isFav ? Border.all(color: Colors.red.shade600.withValues(alpha: 0.25), width: 1) : null,
            ),
            child: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 20,
              color: isFav ? Colors.red.shade600 : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuBtn({
    required IconData icon,
    required String label,
    required Color accent,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyContent(bool isDark) {
    final text = '${widget.part.title}'
        '${widget.part.subtitle != null ? '\n${widget.part.subtitle}\n' : '\n'}'
        '\n${widget.part.content}';
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '\u062a\u0645 \u0646\u0633\u062e \u0627\u0644\u0645\u062d\u062a\u0648\u0649 \u0628\u0646\u062c\u0627\u062d',
          style: TextStyle(
            fontFamily: 'ScheherazadeNew',
            color: isDark ? AppColors.darkTextPrimary : Colors.white,
          ),
        ),
        backgroundColor: AppColors.emeraldGreen,
      ),
    );
  }
}

class _SearchNavBar extends StatefulWidget {
  final int currentIndex;
  final int totalMatches;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final bool isDark;

  const _SearchNavBar({
    required this.currentIndex,
    required this.totalMatches,
    required this.onNext,
    required this.onPrev,
    required this.isDark,
  });

  @override
  State<_SearchNavBar> createState() => _SearchNavBarState();
}

class _SearchNavBarState extends State<_SearchNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isDark ? AppColors.gold : AppColors.emeraldGreen;
    final bg = widget.isDark
        ? const Color(0xFF132E1C).withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.95);
    final textColor = widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return FadeTransition(
      opacity: CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic)),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: accent.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Previous button
                _navButton(
                  icon: Icons.keyboard_arrow_up_rounded,
                  onTap: widget.onPrev,
                  accent: accent,
                ),
                const SizedBox(width: 2),

                // Counter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: widget.isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.currentIndex + 1} / ${widget.totalMatches}',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),

                const SizedBox(width: 2),

                // Next button
                _navButton(
                  icon: Icons.keyboard_arrow_down_rounded,
                  onTap: widget.onNext,
                  accent: accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color accent,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 22, color: accent),
        ),
      ),
    );
  }
}

class _BookmarkNavBar extends StatefulWidget {
  final int currentIndex;
  final int totalBookmarks;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onDismiss;
  final bool isDark;

  const _BookmarkNavBar({
    required this.currentIndex,
    required this.totalBookmarks,
    required this.onNext,
    required this.onPrev,
    required this.onDismiss,
    required this.isDark,
  });

  @override
  State<_BookmarkNavBar> createState() => _BookmarkNavBarState();
}

class _BookmarkNavBarState extends State<_BookmarkNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isDark ? AppColors.gold : AppColors.emeraldGreen;
    final bg = widget.isDark
        ? const Color(0xFF132E1C).withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.95);

    return FadeTransition(
      opacity: CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic)),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: accent.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
                BoxShadow(
                  color: accent.withValues(alpha: 0.08),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dismiss button
                _navButton(
                  icon: Icons.close_rounded,
                  onTap: widget.onDismiss,
                  accent: accent.withValues(alpha: 0.5),
                  size: 18,
                ),
                const SizedBox(width: 2),

                // Previous button
                _navButton(
                  icon: Icons.keyboard_arrow_up_rounded,
                  onTap: widget.onPrev,
                  accent: accent,
                ),
                const SizedBox(width: 2),

                // Counter with bookmark icon
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: widget.isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_rounded, size: 14, color: accent),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.currentIndex + 1} / ${widget.totalBookmarks}',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 2),

                // Next button
                _navButton(
                  icon: Icons.keyboard_arrow_down_rounded,
                  onTap: widget.onNext,
                  accent: accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color accent,
    double size = 22,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: size, color: accent),
        ),
      ),
    );
  }
}
