import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/smooth_scroll_physics.dart';
import '../../data/muqaddima.dart';
import '../detail/widgets/content_body.dart';

/// The book's foreword, set in the same face as the ahzab themselves.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  /// Matches the reading size the hizb screen derives from the device width.
  static const _referenceWidth = 411.0;
  static const _referenceFontSize = 24.0;
  static const _minFontSize = 10.0;
  static const _maxFontSize = 44.0;
  static const _smoothK = 12.0;

  final ValueNotifier<double> _fontSizeNotifier = ValueNotifier(
    _referenceFontSize,
  );
  double _fontSize = _referenceFontSize;
  double _baseFontSize = _referenceFontSize;
  bool _baseFontResolved = false;

  final Map<int, Offset> _pointers = {};
  double _initialDistance = 0;
  double _fontSizeAtPinchStart = _referenceFontSize;
  int _lastSmoothTime = 0;
  bool _isScaling = false;

  late final AnimationController _animController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  Animation<double>? _animation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_baseFontResolved) return;
    _baseFontResolved = true;
    final width = MediaQuery.sizeOf(context).width;
    _baseFontSize = (_referenceFontSize * width / _referenceWidth).clamp(
      22.0,
      34.0,
    );
    _fontSize = _baseFontSize;
    _fontSizeAtPinchStart = _baseFontSize;
    _fontSizeNotifier.value = _baseFontSize;
  }

  @override
  void dispose() {
    _animation?.removeListener(_onAnimationTick);
    _animController.dispose();
    _fontSizeNotifier.dispose();
    super.dispose();
  }

  double _fingerDistance() {
    if (_pointers.length < 2) return 0;
    final pts = _pointers.values.toList();
    final dx = pts[0].dx - pts[1].dx;
    final dy = pts[0].dy - pts[1].dy;
    return math.sqrt(dx * dx + dy * dy);
  }

  void _onPointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.position;
    if (_pointers.length == 2) {
      _initialDistance = _fingerDistance();
      _fontSizeAtPinchStart = _fontSize;
      _lastSmoothTime = DateTime.now().microsecondsSinceEpoch;
      if (!_isScaling) {
        _isScaling = true;
        _animController.stop();
        _animation?.removeListener(_onAnimationTick);
        setState(() {});
      }
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.position;
    if (_pointers.length == 2 && _isScaling && _initialDistance > 0) {
      final target =
          (_fontSizeAtPinchStart * _fingerDistance() / _initialDistance).clamp(
            _minFontSize,
            _maxFontSize,
          );

      // Time-based smoothing, so the text does not jitter with the fingers.
      final now = DateTime.now().microsecondsSinceEpoch;
      final dt = (now - _lastSmoothTime) / 1e6;
      _lastSmoothTime = now;
      final alpha = 1.0 - math.exp(-_smoothK * dt.clamp(0.001, 0.1));

      final smoothed = (_fontSize + (target - _fontSize) * alpha).clamp(
        _minFontSize,
        _maxFontSize,
      );
      if ((smoothed - _fontSize).abs() > 0.01) {
        _fontSize = smoothed;
        _fontSizeNotifier.value = _fontSize;
      }
    }
  }

  void _endPinch(int pointer) {
    _pointers.remove(pointer);
    if (_pointers.length < 2 && _isScaling) {
      _isScaling = false;
      _pointers.clear();
      setState(() {});
    }
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
    _animation = Tween<double>(begin: _fontSize, end: _baseFontSize).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animation!.addListener(_onAnimationTick);
    _animController.forward(from: 0).then((_) {
      _animation?.removeListener(_onAnimationTick);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'المقدمة',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: (e) => _endPinch(e.pointer),
          onPointerCancel: (e) => _endPinch(e.pointer),
          child: GestureDetector(
            onDoubleTap: _resetZoom,
            child: ListView(
              physics: _isScaling
                  ? const NeverScrollableScrollPhysics()
                  : const SmoothScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
              padding: const EdgeInsets.fromLTRB(4, 18, 4, 32),
              children: [
                ValueListenableBuilder<double>(
                  valueListenable: _fontSizeNotifier,
                  builder: (context, size, _) => ContentBody(
                    content: muqaddima.content,
                    title: muqaddima.title,
                    bodyFontFamily: ContentBody.mushafFont,
                    isScaling: _isScaling,
                    fontSize: size,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
