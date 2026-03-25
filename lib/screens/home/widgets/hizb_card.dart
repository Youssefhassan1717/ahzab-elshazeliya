import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/arabic_normalizer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/hizb_part.dart';
import '../../../providers/favorites_provider.dart';
import '../../detail/detail_screen.dart';

class HizbCard extends StatefulWidget {
  final HizbPart part;
  final bool isFavorite;
  final String searchQuery;

  const HizbCard({
    super.key,
    required this.part,
    this.isFavorite = false,
    this.searchQuery = '',
  });

  @override
  State<HizbCard> createState() => _HizbCardState();
}

class _HizbCardState extends State<HizbCard> with TickerProviderStateMixin {
  late final AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Press feedback
  late final AnimationController _pressController;
  late final Animation<double> _pressScale;
  
  bool _wasFavorite = false;
  
  // Getter for convenient access
  HizbPart get part => widget.part;

  @override
  void initState() {
    super.initState();
    _wasFavorite = widget.isFavorite;
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(HizbCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite != _wasFavorite) {
      // Trigger animation when favorite status changes
      _animateFavoriteChange(widget.isFavorite);
      _wasFavorite = widget.isFavorite;
    }
  }

  void _animateFavoriteChange(bool isNowFavorite) {
    // Slide animation - move up if added to favorites, down if removed
    final beginOffset = isNowFavorite ? const Offset(0, 0.5) : const Offset(0, -0.5);
    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _slideController.forward(from: 0);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.gold : AppColors.emeraldGreen;

    return ScaleTransition(
      scale: _pressScale,
      child: SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : accentColor.withValues(alpha: 0.07),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                splashColor: accentColor.withValues(alpha: 0.08),
                highlightColor: accentColor.withValues(alpha: 0.04),
                onTapDown: (_) => _pressController.forward(),
                onTapUp: (_) {
                  _pressController.reverse();
                  _navigateToDetail(context);
                },
                onTapCancel: () => _pressController.reverse(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Subtle top accent bar
                      Positioned(
                        top: 0,
                        right: 0,
                        left: 0,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor.withValues(alpha: 0.0),
                                accentColor.withValues(alpha: 0.35),
                                accentColor.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Card content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            // Islamic ornament icon
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    accentColor.withValues(alpha: 0.12),
                                    accentColor.withValues(alpha: 0.03),
                                  ],
                                ),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.18),
                                  width: 1.2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '۞',
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: accentColor,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Title & subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Hero(
                                    tag: 'hizb_title_${part.id}',
                                    flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
                                      return DefaultTextStyle(
                                        style: DefaultTextStyle.of(toHeroContext).style,
                                        child: toHeroContext.widget,
                                      );
                                    },
                                    child: Text(
                                      part.title,
                                      style: TextStyle(
                                        fontFamily: 'Amiri',
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                        fontSize: 17,
                                        height: 1.4,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  if (part.subtitle != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      part.subtitle!,
                                      style: TextStyle(
                                        fontFamily: 'ScheherazadeNew',
                                        fontSize: 12.5,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                        height: 1.3,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                  // Content match snippet
                                  if (widget.searchQuery.isNotEmpty) ...[                                    
                                    _buildSnippet(isDark, accentColor),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Favorite button
                            Consumer<FavoritesProvider>(
                              builder: (context, favProvider, _) {
                                final isFav = favProvider.isFavorite(part.id);
                                return _FavoriteButton(
                                  isFavorite: isFav,
                                  isDark: isDark,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    favProvider.toggleFavorite(part.id, context);
                                  },
                                );
                              },
                            ),

                            // Arrow indicator (RTL → left chevron)
                            const SizedBox(width: 2),
                            Icon(
                              Icons.chevron_left,
                              size: 20,
                              color: isDark
                                  ? AppColors.darkTextSecondary.withValues(alpha: 0.4)
                                  : AppColors.lightTextSecondary.withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSnippet(bool isDark, Color accentColor) {
    final query = widget.searchQuery;
    final normalizedQuery = normalizeArabic(query);
    // Clean content: remove §SECTION§ markers and collapse whitespace
    final cleanContent = part.content
        .replaceAll(RegExp(r'§SECTION§.+?§SECTION§'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final bestMatch = findBestSnippetMatch(cleanContent, normalizedQuery);
    if (bestMatch == null) return const SizedBox.shrink();

    final (matchStart, matchEnd) = bestMatch;

    // RTL display: text flows right→left, so "before" appears on the RIGHT
    // (visible) while the match gets pushed LEFT (may be truncated).
    // Keep "before" very short so the highlighted match stays visible.
    int snippetStart = matchStart;
    int count = 0;
    // Only go back ~12 chars (1-2 words) to keep match visible in RTL
    while (snippetStart > 0 && count < 12) {
      snippetStart--;
      count++;
    }
    // Snap to next space to avoid cutting a word
    while (snippetStart > 0 && cleanContent[snippetStart] != ' ') {
      snippetStart--;
    }
    if (snippetStart > 0) snippetStart++; // skip the space

    int snippetEnd = matchEnd;
    count = 0;
    // Go forward ~30 chars for context after match
    while (snippetEnd < cleanContent.length && count < 30) {
      snippetEnd++;
      count++;
    }
    // Snap to next space
    while (snippetEnd < cleanContent.length && cleanContent[snippetEnd] != ' ') {
      snippetEnd++;
    }

    final before = cleanContent.substring(snippetStart, matchStart);
    final matchText = cleanContent.substring(matchStart, matchEnd);
    final after = cleanContent.substring(matchEnd, snippetEnd);

    final prefix = snippetStart > 0 ? '... ' : '';
    final suffix = snippetEnd < cleanContent.length ? ' ...' : '';

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.12 : 0.06),
          width: 0.5,
        ),
      ),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textDirection: TextDirection.rtl,
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'ScheherazadeNew',
            fontSize: 12,
            color: isDark
                ? AppColors.darkTextSecondary.withValues(alpha: 0.7)
                : AppColors.lightTextSecondary.withValues(alpha: 0.7),
            height: 1.4,
          ),
          children: [
            TextSpan(text: '$prefix$before'),
            TextSpan(
              text: matchText,
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w700,
                backgroundColor: accentColor.withValues(alpha: isDark ? 0.15 : 0.10),
              ),
            ),
            TextSpan(text: '$after$suffix'),
          ],
        ),
      ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      _SwipeBackPageRoute(
        builder: (_) => DetailScreen(
          part: part,
          searchQuery: widget.searchQuery,
        ),
      ),
    );
  }
}

/// A page route that supports iOS-style swipe-back from the left edge,
/// with slide + fade transition matching the app's RTL design.
class _SwipeBackPageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  _SwipeBackPageRoute({required this.builder});

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 250);

  // Enable the swipe-back gesture
  @override
  bool get popGestureEnabled => true;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // Wrap in a swipe-back gesture detector
    final Widget page = SlideTransition(
      position: Tween(
        begin: const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(curvedAnimation),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.3, end: 1.0).animate(curvedAnimation),
        child: child,
      ),
    );

    // Only enable gesture when the route is on top
    if (animation.status == AnimationStatus.completed) {
      return _SwipeBackGesture(route: this, child: page);
    }
    return page;
  }
}

class _SwipeBackGesture extends StatefulWidget {
  final PageRoute route;
  final Widget child;

  const _SwipeBackGesture({required this.route, required this.child});

  @override
  State<_SwipeBackGesture> createState() => _SwipeBackGestureState();
}

class _SwipeBackGestureState extends State<_SwipeBackGesture> {
  double _dragOffset = 0;
  bool _isDragging = false;
  static const double _edgeWidth = 30.0;
  static const double _threshold = 0.35;

  void _onHorizontalDragStart(DragStartDetails details) {
    // Only start if swipe begins from the left edge
    if (details.globalPosition.dx <= _edgeWidth) {
      _isDragging = true;
      _dragOffset = 0;
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, MediaQuery.of(context).size.width);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final screenWidth = MediaQuery.of(context).size.width;
    final fraction = _dragOffset / screenWidth;
    final velocity = details.primaryVelocity ?? 0;

    if (fraction > _threshold || velocity > 800) {
      // Complete the back navigation
      Navigator.of(context).pop();
    } else {
      // Snap back
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fraction = _dragOffset / screenWidth;

    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: AnimatedContainer(
        duration: _isDragging ? Duration.zero : const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(_dragOffset, 0, 0),
        child: AnimatedOpacity(
          duration: _isDragging ? Duration.zero : const Duration(milliseconds: 250),
          opacity: 1.0 - (fraction * 0.3),
          child: widget.child,
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final bool isDark;
  final VoidCallback onTap;

  const _FavoriteButton({
    required this.isFavorite,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: widget.isFavorite
                ? Colors.red.withValues(alpha: 0.15)
                : (widget.isDark
                    ? Colors.grey.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.08)),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.elasticOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(widget.isFavorite),
                color: widget.isFavorite
                    ? Colors.red.shade600
                    : (widget.isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
