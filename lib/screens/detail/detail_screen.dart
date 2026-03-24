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
  static const double _initialFontSize = 22;
  static const double _maxFontSize = 48;

  double _fontSize = _initialFontSize;

  double _baseScaleFactor = 1.0;
  bool _isScaling = false;

  late final AnimationController _zoomAnimController;
  Animation<double>? _zoomAnimation;

  @override
  void initState() {
    super.initState();
    _zoomAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _zoomAnimController.dispose();
    super.dispose();
  }

  /// Smoothly animate font size to a target value
  void _animateFontSizeTo(double target, {Duration? duration}) {
    final start = _fontSize;
    final clampedTarget = target.clamp(_initialFontSize, _maxFontSize);

    if ((clampedTarget - start).abs() < 0.1) return;

    _zoomAnimController.duration =
        duration ?? const Duration(milliseconds: 300);

    _zoomAnimation = Tween<double>(
      begin: start,
      end: clampedTarget,
    ).animate(CurvedAnimation(
      parent: _zoomAnimController,
      curve: Curves.easeOutCubic,
    ));

    _zoomAnimation!.addListener(_onZoomAnimationTick);
    _zoomAnimController.forward(from: 0).then((_) {
      _zoomAnimation?.removeListener(_onZoomAnimationTick);
    });
  }

  void _onZoomAnimationTick() {
    if (_zoomAnimation != null) {
      setState(() {
        _fontSize = _zoomAnimation!.value;
      });
    }
  }

  void _resetZoom() {
    if (_fontSize == _initialFontSize) return;
    HapticFeedback.lightImpact();
    _animateFontSizeTo(_initialFontSize, duration: const Duration(milliseconds: 400));
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (details.pointerCount >= 2) {
      _isScaling = true;
      _baseScaleFactor = _fontSize / _initialFontSize;
      // Stop any running animation
      _zoomAnimController.stop();
      _zoomAnimation?.removeListener(_onZoomAnimationTick);
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (!_isScaling || details.pointerCount < 2) return;

    // Exponential scaling for natural feel
    final rawScale = _baseScaleFactor * details.scale;
    // Apply easing: use log scale for smoother feel at extremes
    final easedScale = math.pow(rawScale, 0.85).toDouble();
    final newSize =
        (_initialFontSize * easedScale).clamp(_initialFontSize, _maxFontSize);

    // Only update if change is visible (avoid micro-jitter)
    if ((newSize - _fontSize).abs() > 0.15) {
      setState(() {
        _fontSize = newSize;
      });
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (!_isScaling) return;
    _isScaling = false;

    // Snap to nearest whole font size for crisp rendering
    final snapped = _fontSize.roundToDouble();
    final clamped = snapped.clamp(_initialFontSize, _maxFontSize);
    if ((clamped - _fontSize).abs() > 0.3) {
      _animateFontSizeTo(clamped, duration: const Duration(milliseconds: 150));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
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
        body: GestureDetector(
          onDoubleTap: _resetZoom,
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          child: SingleChildScrollView(
            physics: const SmoothScrollPhysics(
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
            fontFamily: 'NotoNaskhArabic',
            color: isDark ? AppColors.darkTextPrimary : Colors.white,
          ),
        ),
        backgroundColor: AppColors.emeraldGreen,
      ),
    );
  }
}
