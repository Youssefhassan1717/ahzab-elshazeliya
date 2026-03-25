import 'dart:math' as math;
import 'package:flutter/material.dart';
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
  static const double _baseFontSize = 22.0;
  static const double _minFontSize = 14.0;
  static const double _maxFontSize = 56.0;

  double _fontSize = _baseFontSize;
  double _previousScale = 1.0;
  bool _isScaling = false;
  String? _highlightText; // Temporarily highlighted bookmark text

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
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

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

  void _computeSearchMatches() {
    final content = widget.part.content;
    final cleanContent = content.replaceAll(RegExp(r'§SECTION§.+?§SECTION§'), '');
    final normalizedQuery = normalizeArabic(widget.searchQuery);
    _searchMatches = findNormalizedMatches(cleanContent, normalizedQuery);
    _currentMatchIndex = 0;
  }

  void _scrollToMatchIndex(int index) {
    if (_searchMatches.isEmpty || !_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    setState(() => _currentMatchIndex = index);

    final content = widget.part.content;
    final cleanContent = content.replaceAll(RegExp(r'§SECTION§.+?§SECTION§'), '');
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
    _animController.dispose();
    _highlightController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (details.pointerCount < 2) return;
    
    _isScaling = true;
    _previousScale = _fontSize / _baseFontSize;
    
    // Stop any running animation
    _animController.stop();
    _animation?.removeListener(_onAnimationTick);
    
    // Force rebuild to disable scroll physics during pinch
    setState(() {});
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (!_isScaling || details.pointerCount < 2) return;

    // currentScale = previousScale * gestureScale
    final currentScale = _previousScale * details.scale;
    
    // Exponential scaling for natural feel
    final exponentialScale = math.pow(currentScale, 1.15).toDouble();
    
    // Clamp and calculate font size directly — no lerp lag
    final newFontSize = (_baseFontSize * exponentialScale).clamp(_minFontSize, _maxFontSize);

    // Only rebuild if change is visible
    if ((newFontSize - _fontSize).abs() > 0.05) {
      setState(() {
        _fontSize = newFontSize;
      });
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (!_isScaling) return;
    _isScaling = false;

    // Save current scale for next gesture
    _previousScale = _fontSize / _baseFontSize;

    // Force rebuild to re-enable scroll physics
    setState(() {});

    // Snap to nearest 0.5 for crisp rendering
    final snapped = (_fontSize * 2).roundToDouble() / 2;
    final clamped = snapped.clamp(_minFontSize, _maxFontSize);
    
    if ((clamped - _fontSize).abs() > 0.3) {
      _animateToFontSize(clamped, const Duration(milliseconds: 120));
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
      setState(() {
        _fontSize = _animation!.value;
      });
    }
  }

  void _resetZoom() {
    if (_fontSize == _baseFontSize) return;
    HapticFeedback.lightImpact();
    _previousScale = 1.0;
    _animateToFontSize(_baseFontSize, const Duration(milliseconds: 300));
  }

  void _scrollToText(String text) {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    final content = widget.part.content;
    final cleanContent = content.replaceAll(RegExp(r'§SECTION§.+?§SECTION§'), '');
    final normalizedQuery = normalizeArabic(text);
    final bestMatch = findBestSnippetMatch(cleanContent, normalizedQuery);
    if (bestMatch == null) return;

    final (matchStart, _) = bestMatch;
    final fraction = matchStart / cleanContent.length;
    final viewportHeight = _scrollController.position.viewportDimension;
    final totalScrollableHeight = maxScroll + viewportHeight;

    // The scroll content is: padding(12) + header(~220) + gap(20) + contentBody + gap(20) + zoomInstr(~60) + padding(32)
    // Content body starts at roughly ~270px and ends at totalScrollableHeight - ~112
    const contentStartOffset = 270.0;
    const contentEndPadding = 112.0;
    final contentBodyHeight = totalScrollableHeight - contentStartOffset - contentEndPadding;

    // Map the text fraction to a scroll position within the content body
    final matchPixelPos = contentStartOffset + (fraction * contentBodyHeight);

    // Center the match in the viewport (place it at ~35% from top for comfortable reading)
    final targetOffset = (matchPixelPos - viewportHeight * 0.35).clamp(0.0, maxScroll);

    // Smooth two-phase scroll: fast approach then gentle settle
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
    );

    // Briefly highlight the text with a longer, softer glow
    setState(() => _highlightText = text);
    _highlightController.forward(from: 0).then((_) {
      if (mounted) setState(() => _highlightText = null);
    });
  }

  void _showBookmarksPanel() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BookmarksPanel(
        hizbId: widget.part.id,
        onBookmarkTap: (text) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _scrollToText(text);
          });
        },
      ),
    );
  }

  void _addBookmark(String selectedText) {
    if (selectedText.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    final provider = context.read<BookmarksProvider>();
    provider.addBookmark(widget.part.id, selectedText.trim());

    // Show brief feedback
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تم حفظ العلامة',
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Hero(
            tag: 'hizb_title_${widget.part.id}',
            flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
              return DefaultTextStyle(
                style: DefaultTextStyle.of(toHeroContext).style,
                child: toHeroContext.widget,
              );
            },
            child: Text(
              widget.part.title,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
          actions: [
            // Bookmarks icon — modern style
            Consumer<BookmarksProvider>(
              builder: (context, bookProvider, _) {
                final count = bookProvider.getCount(widget.part.id);
                final hasBookmarks = count > 0;
                final accent = isDark ? AppColors.gold : AppColors.emeraldGreen;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: _showBookmarksPanel,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: hasBookmarks
                            ? accent.withValues(alpha: isDark ? 0.15 : 0.10)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: hasBookmarks
                            ? Border.all(color: accent.withValues(alpha: 0.25), width: 1)
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Icon(
                              hasBookmarks
                                  ? Icons.auto_stories_rounded
                                  : Icons.auto_stories_outlined,
                              key: ValueKey(hasBookmarks),
                              size: 20,
                              color: accent,
                            ),
                          ),
                          if (hasBookmarks) ...[                            
                            const SizedBox(width: 4),
                            Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Amiri',
                                color: accent,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Consumer<FavoritesProvider>(
              builder: (context, favProvider, _) {
                final isFav = favProvider.isFavorite(widget.part.id);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      favProvider.toggleFavorite(widget.part.id, context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isFav
                            ? Colors.red.shade600.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: isFav
                            ? Border.all(color: Colors.red.shade600.withValues(alpha: 0.25), width: 1)
                            : null,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          key: ValueKey(isFav),
                          size: 20,
                          color: isFav
                              ? Colors.red.shade600
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            // Main content
            Theme(
          data: Theme.of(context).copyWith(
            textSelectionTheme: TextSelectionThemeData(
              selectionColor: AppColors.emeraldGreen.withValues(alpha: 0.25),
              selectionHandleColor: AppColors.emeraldGreen,
              cursorColor: AppColors.emeraldGreen,
            ),
          ),
          child: SelectionArea(
            contextMenuBuilder: (context, selectableRegionState) {
              final isDk = Theme.of(context).brightness == Brightness.dark;
              final accent = isDk ? AppColors.gold : AppColors.emeraldGreen;
              final bg = isDk
                  ? const Color(0xFF1A2E20)
                  : const Color(0xFFF5F9F5);
              final textCol = isDk
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary;

              return AdaptiveTextSelectionToolbar(
                anchors: selectableRegionState.contextMenuAnchors,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.25),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDk ? 0.3 : 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMenuBtn(
                            icon: Icons.copy_rounded,
                            label: 'نسخ',
                            accent: accent,
                            textColor: textCol,
                            onTap: () {
                              selectableRegionState.copySelection(SelectionChangedCause.toolbar);
                              selectableRegionState.hideToolbar();
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'تم نسخ النص',
                                    style: TextStyle(fontFamily: 'ScheherazadeNew'),
                                  ),
                                  backgroundColor: isDk ? AppColors.gold : AppColors.emeraldGreen,
                                  duration: const Duration(milliseconds: 1200),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                ),
                              );
                            },
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: accent.withValues(alpha: 0.15),
                          ),
                          _buildMenuBtn(
                            icon: Icons.bookmark_add_rounded,
                            label: 'علامة مميزة',
                            accent: accent,
                            textColor: textCol,
                            onTap: () {
                              selectableRegionState.copySelection(SelectionChangedCause.toolbar);
                              Clipboard.getData(Clipboard.kTextPlain).then((data) {
                                if (data?.text != null && data!.text!.isNotEmpty) {
                                  _addBookmark(data.text!);
                                }
                              });
                              selectableRegionState.hideToolbar();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            child: GestureDetector(
              onDoubleTap: _resetZoom,
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: _onScaleEnd,
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
                controller: _scrollController,
                physics: _isScaling
                    ? const NeverScrollableScrollPhysics()
                    : const SmoothScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RepaintBoundary(
                      child: DetailHeader(
                        title: widget.part.title,
                        subtitle: widget.part.subtitle,
                        fontSize: _fontSize,
                      ),
                    ),
                    const SizedBox(height: 20),
                    RepaintBoundary(
                      child: Consumer<BookmarksProvider>(
                        builder: (context, bookProvider, _) {
                          final bookmarkedTexts =
                              bookProvider.getBookmarkTexts(widget.part.id);
                          return AnimatedBuilder(
                            animation: _highlightController,
                            builder: (context, _) {
                              return ContentBody(
                                content: widget.part.content,
                                fontSize: _fontSize,
                                isDark: isDark,
                                searchQuery: widget.searchQuery,
                                activeSearchMatchIndex: _currentMatchIndex,
                                bookmarkedTexts: bookmarkedTexts,
                                highlightText: _highlightText,
                                highlightOpacity: _highlightText != null
                                    ? (1.0 - _highlightController.value).clamp(0.0, 1.0)
                                    : 0.0,
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const ZoomInstructions(),
                  ],
                ),
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
          ],
        ),
      ),
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
          'تم نسخ المحتوى بنجاح',
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
