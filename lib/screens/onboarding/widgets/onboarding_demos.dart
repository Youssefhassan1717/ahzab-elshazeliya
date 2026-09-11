import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Runs a looping animation, but only while its page is the one on screen.
class _DemoLoop extends StatefulWidget {
  const _DemoLoop({
    required this.active,
    required this.duration,
    required this.builder,
  });

  final bool active;
  final Duration duration;
  final Widget Function(BuildContext context, double t) builder;

  @override
  State<_DemoLoop> createState() => _DemoLoopState();
}

class _DemoLoopState extends State<_DemoLoop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant _DemoLoop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => widget.builder(context, _c.value),
      ),
    );
  }
}

/// Maps the loop position [t] onto the slice between [a] and [b] as 0 → 1.
double _seg(double t, double a, double b, {Curve curve = Curves.easeInOut}) {
  if (t <= a) return 0;
  if (t >= b) return 1;
  return curve.transform((t - a) / (b - a));
}

class _Palette {
  _Palette(BuildContext context)
    : isDark = Theme.of(context).brightness == Brightness.dark;

  final bool isDark;

  Color get accent => isDark ? AppColors.gold : AppColors.emeraldGreen;
  Color get surface => isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get hairline => textSecondary.withValues(alpha: isDark ? 0.18 : 0.14);
}

BoxDecoration _panel(_Palette p, {Color? border}) => BoxDecoration(
  color: p.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: border ?? p.hairline),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: p.isDark ? 0.28 : 0.05),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ],
);

// ── 1. Welcome ───────────────────────────────────────────────────────────────

class WelcomeDemo extends StatelessWidget {
  const WelcomeDemo({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final p = _Palette(context);

    return _DemoLoop(
      active: active,
      duration: const Duration(seconds: 8),
      builder: (context, t) {
        final breathe = 0.5 + 0.5 * math.sin(t * 2 * math.pi);

        return SizedBox(
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      p.accent.withValues(alpha: 0.05 + 0.07 * breathe),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              for (final turn in const [0.0, 0.125])
                Transform.rotate(
                  angle: t * 2 * math.pi * 0.12 + turn * 2 * math.pi,
                  child: Container(
                    width: 172,
                    height: 172,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: p.accent.withValues(alpha: 0.22),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              // The basmala ligature is very wide; let it shrink to fit.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '\uFDFD',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 62,
                      height: 1.6,
                      color: p.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── 2. The app bar: the muqaddima and the theme switch ────────────────────────

class AppBarDemo extends StatelessWidget {
  const AppBarDemo({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final p = _Palette(context);

    return _DemoLoop(
      active: active,
      duration: const Duration(seconds: 5),
      builder: (context, t) {
        final ripple = _seg(t, 0.22, 0.5);
        final press = _seg(t, 0.22, 0.3) - _seg(t, 0.3, 0.44);
        final moon = _seg(t, 0.66, 0.78) - _seg(t, 0.78, 0.92);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: _panel(p),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'أحزاب الإمام الشاذلي',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.accent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        if (ripple > 0 && ripple < 1)
                          Container(
                            width: 26 + 22 * ripple,
                            height: 26 + 22 * ripple,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: p.accent.withValues(
                                alpha: 0.28 * (1 - ripple),
                              ),
                            ),
                          ),
                        Transform.scale(
                          scale: 1 - 0.16 * press,
                          child: Icon(
                            Icons.auto_stories_rounded,
                            size: 22,
                            color: p.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Transform.rotate(
                        angle: -0.5 * moon,
                        child: Icon(
                          Icons.dark_mode_rounded,
                          size: 21,
                          color: p.accent.withValues(alpha: 0.45 + 0.55 * moon),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _MockCard(p: p, title: 'حزب البحر'),
            const SizedBox(height: 10),
            _MockCard(p: p, title: 'حزب البر', dim: true),
          ],
        );
      },
    );
  }
}

class _MockCard extends StatelessWidget {
  const _MockCard({
    required this.p,
    required this.title,
    this.dim = false,
    this.trailing,
    this.border,
  });

  final _Palette p;
  final String title;
  final bool dim;
  final Widget? trailing;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dim ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: _panel(p, border: border),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.accent.withValues(alpha: 0.10),
              ),
              child: Center(
                child: Text(
                  '۞',
                  style: TextStyle(fontSize: 15, color: p.accent),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

// ── 3. Search ────────────────────────────────────────────────────────────────

class SearchDemo extends StatelessWidget {
  const SearchDemo({super.key, required this.active});

  final bool active;

  static const _word = 'الفتح';

  @override
  Widget build(BuildContext context) {
    final p = _Palette(context);

    return _DemoLoop(
      active: active,
      duration: const Duration(seconds: 6),
      builder: (context, t) {
        final typing = _seg(t, 0.08, 0.4, curve: Curves.linear);
        final typed = _word.substring(0, (_word.length * typing).round());
        final caretOn = typing < 1 && (t * 9) % 1 < 0.55;
        final result = _seg(t, 0.46, 0.62);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: _panel(
                p,
                border: typed.isEmpty
                    ? null
                    : p.accent.withValues(alpha: 0.35),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 20, color: p.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      typed.isEmpty ? 'ابحث في الأحزاب...' : typed + (caretOn ? '|' : ''),
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 15,
                        color: typed.isEmpty
                            ? p.textSecondary.withValues(alpha: 0.7)
                            : p.textPrimary,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Opacity(
              opacity: result,
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - result)),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: _panel(p),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: p.accent.withValues(alpha: 0.10),
                            ),
                            child: Center(
                              child: Text(
                                '۞',
                                style: TextStyle(fontSize: 14, color: p.accent),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'حزب الفتح',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 13,
                            height: 1.7,
                            color: p.textSecondary,
                          ),
                          children: [
                            const TextSpan(text: 'اللَّهُمَّ افْتَحْ لَنَا بِ'),
                            TextSpan(
                              text: 'الْفَتْحِ',
                              style: TextStyle(
                                color: p.accent,
                                fontWeight: FontWeight.w700,
                                backgroundColor: p.accent.withValues(
                                  alpha: 0.16,
                                ),
                              ),
                            ),
                            const TextSpan(text: ' الْمُبِينِ'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── 4. Pinch to zoom ─────────────────────────────────────────────────────────

class ZoomDemo extends StatelessWidget {
  const ZoomDemo({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final p = _Palette(context);

    return _DemoLoop(
      active: active,
      duration: const Duration(seconds: 5),
      builder: (context, t) {
        final k = 0.5 - 0.5 * math.cos(t * 2 * math.pi);
        final spread = 26.0 + 34.0 * k;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          decoration: _panel(p),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 96,
                child: Center(
                  // Widening the box scales the line up; it never wraps.
                  child: SizedBox(
                    width: 264 * (0.55 + 0.45 * k),
                    child: FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Text(
                        'اللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا مُحَمَّدٍ',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontFamily: 'UthmanicHafs',
                          fontSize: 20,
                          height: 1.9,
                          color: p.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 26,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Transform.translate(
                      offset: Offset(-spread, 0),
                      child: _FingerDot(color: p.accent),
                    ),
                    Transform.translate(
                      offset: Offset(spread, 0),
                      child: _FingerDot(color: p.accent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FingerDot extends StatelessWidget {
  const _FingerDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
    );
  }
}

// ── 5. Select text, then bookmark it ─────────────────────────────────────────

class BookmarkDemo extends StatelessWidget {
  const BookmarkDemo({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final p = _Palette(context);

    return _DemoLoop(
      active: active,
      duration: const Duration(seconds: 7),
      builder: (context, t) {
        final select = _seg(t, 0.10, 0.30);
        final menu = _seg(t, 0.34, 0.46) - _seg(t, 0.74, 0.86);
        final choose = _seg(t, 0.56, 0.66) - _seg(t, 0.74, 0.86);
        final saved = _seg(t, 0.64, 0.76);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: _panel(p),
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontSize: 15,
                    height: 2.0,
                    color: p.textPrimary,
                  ),
                  children: [
                    const TextSpan(text: 'وَنَسْأَلُكَ اللَّهُمَّ '),
                    TextSpan(
                      text: 'حُسْنَ الْخِتَامِ',
                      style: TextStyle(
                        backgroundColor: p.accent.withValues(
                          alpha: 0.30 * select,
                        ),
                      ),
                    ),
                    const TextSpan(text: ' وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Opacity(
              opacity: menu.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.9 + 0.1 * menu,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  decoration: _panel(p),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MenuItem(
                        p: p,
                        icon: Icons.copy_rounded,
                        label: 'نسخ',
                        highlight: 0,
                      ),
                      Container(width: 1, height: 20, color: p.hairline),
                      _MenuItem(
                        p: p,
                        icon: Icons.bookmark_add_rounded,
                        label: 'علامة مميزة',
                        highlight: choose.clamp(0.0, 1.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Opacity(
              opacity: saved,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - saved)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_rounded, size: 15, color: p.accent),
                      const SizedBox(width: 6),
                      Text(
                        'تم حفظ الموضع',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: p.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.p,
    required this.icon,
    required this.label,
    required this.highlight,
  });

  final _Palette p;
  final IconData icon;
  final String label;
  final double highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: p.accent.withValues(alpha: 0.16 * highlight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: p.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 6. Favourites ────────────────────────────────────────────────────────────

class FavoriteDemo extends StatelessWidget {
  const FavoriteDemo({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final p = _Palette(context);

    return _DemoLoop(
      active: active,
      duration: const Duration(milliseconds: 5500),
      builder: (context, t) {
        final fill = _seg(t, 0.22, 0.40, curve: Curves.easeOutBack);
        final burst = _seg(t, 0.26, 0.55);
        final promote = _seg(t, 0.52, 0.72);
        final pop = 1 + 0.35 * math.sin(math.pi * _seg(t, 0.22, 0.46));

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: promote,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12, right: 4),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, size: 15, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'مميز',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _MockCard(
              p: p,
              title: 'حِزْبُ الْبَحْرِ',
              border: Color.lerp(
                p.hairline,
                p.accent.withValues(alpha: 0.5),
                promote,
              ),
              trailing: SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    if (burst > 0 && burst < 1)
                      for (var i = 0; i < 6; i++)
                        Transform.translate(
                          offset: Offset.fromDirection(
                            i * math.pi / 3,
                            10 + 12 * burst,
                          ),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.withValues(
                                alpha: 0.7 * (1 - burst),
                              ),
                            ),
                          ),
                        ),
                    Transform.scale(
                      scale: pop,
                      child: Icon(
                        fill > 0.5
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 22,
                        color: Color.lerp(
                          p.textSecondary.withValues(alpha: 0.6),
                          Colors.red,
                          fill.clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Opacity(
              opacity: 1 - promote * 0.55,
              child: _MockCard(p: p, title: 'حِزْبُ الْبَرِّ', dim: true),
            ),
          ],
        );
      },
    );
  }
}
