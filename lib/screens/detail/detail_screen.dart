import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/smooth_scroll_physics.dart';
import '../../models/hizb_part.dart';
import '../../providers/favorites_provider.dart';
import 'widgets/content_body.dart';
import 'widgets/detail_header.dart';
import 'widgets/zoom_instructions.dart';

class DetailScreen extends StatefulWidget {
  final HizbPart part;

  const DetailScreen({super.key, required this.part});

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

  final ScrollController _scrollController = ScrollController();

  late final AnimationController _animController;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
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
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              tooltip: 'نسخ المحتوى',
              onPressed: () => _copyContent(isDark),
            ),
            Consumer<FavoritesProvider>(
              builder: (context, favProvider, _) {
                final isFav = favProvider.isFavorite(widget.part.id);
                return IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      key: ValueKey(isFav),
                      color: isFav
                          ? Colors.red.shade600
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                  ),
                  tooltip: isFav ? 'إزالة من المميز' : 'إضافة للمميز',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    favProvider.toggleFavorite(widget.part.id, context);
                  },
                );
              },
            ),
          ],
        ),
        body: Theme(
          data: Theme.of(context).copyWith(
            textSelectionTheme: TextSelectionThemeData(
              selectionColor: AppColors.emeraldGreen.withValues(alpha: 0.25),
              selectionHandleColor: AppColors.emeraldGreen,
              cursorColor: AppColors.emeraldGreen,
            ),
          ),
          child: SelectionArea(
            child: GestureDetector(
              onDoubleTap: _resetZoom,
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: _onScaleEnd,
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
                      child: ContentBody(
                        content: widget.part.content,
                        fontSize: _fontSize,
                        isDark: isDark,
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
