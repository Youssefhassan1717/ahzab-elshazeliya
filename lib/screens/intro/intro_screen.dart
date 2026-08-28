import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  // Only 4 controllers instead of 7
  late final AnimationController _bgController;       // background fade-in (finite)
  late final AnimationController _contentController;   // staggered text entrance (finite)
  late final AnimationController _loopController;      // slow loop: rotation + particles + breathe
  late final AnimationController _exitController;      // exit fade (finite)

  // Background
  late final Animation<double> _bgFade;
  late final Animation<double> _geometryBloom;

  // Content entrance
  late final Animation<double> _bismillahFade;
  late final Animation<double> _bismillahSlide;
  late final Animation<double> _topLineFade;
  late final Animation<double> _topLineWidth;
  late final Animation<double> _titleFade;
  late final Animation<double> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _subtitleSlide;
  late final Animation<double> _bottomLineFade;
  late final Animation<double> _bottomLineWidth;
  late final Animation<double> _duaFade;
  late final Animation<double> _duaSlide;

  // Exit
  late final Animation<double> _exitFade;
  late final Animation<Offset> _exitSlide;

  // Precomputed particles (12 instead of 35)
  late final List<_FloatingParticle> _particles;

  bool _navigating = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _bgController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    );

    // Single slow loop drives rotation, particles, and breathing
    _loopController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _exitController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // ── Background ──
    _bgFade = CurvedAnimation(parent: _bgController, curve: Curves.easeOut);
    _geometryBloom = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeOutCubic),
    );

    // ── Content entrance ──
    _bismillahFade = _fadeInterval(0.0, 0.18);
    _bismillahSlide = _slideInterval(0.0, 0.22);
    _topLineFade = _fadeInterval(0.10, 0.28);
    _topLineWidth = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.10, 0.35, curve: Curves.easeOut)),
    );
    _titleFade = _fadeInterval(0.22, 0.42);
    _titleSlide = _slideInterval(0.20, 0.45);
    _subtitleFade = _fadeInterval(0.40, 0.58);
    _subtitleSlide = _slideInterval(0.38, 0.60);
    _bottomLineFade = _fadeInterval(0.52, 0.68);
    _bottomLineWidth = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.52, 0.72, curve: Curves.easeOut)),
    );
    _duaFade = _fadeInterval(0.65, 0.82);
    _duaSlide = _slideInterval(0.63, 0.85);

    // ── Exit ──
    _exitFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
    _exitSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.03)).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    // ── Particles — 12, precomputed ──
    final rng = math.Random(42);
    _particles = List.generate(12, (_) => _FloatingParticle(rng));

    _startSequence();
  }

  Animation<double> _fadeInterval(double begin, double end) {
    return Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Interval(begin, end, curve: Curves.easeOut)),
    );
  }

  Animation<double> _slideInterval(double begin, double end) {
    return Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(parent: _contentController, curve: Interval(begin, end, curve: Curves.easeOutCubic)),
    );
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    _bgController.forward();
    _loopController.repeat();

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    _contentController.forward();

    // Let the last line settle before leaving.
    await Future.delayed(const Duration(milliseconds: 3700));
    if (!mounted) return;
    _navigateToHome();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _contentController.dispose();
    _loopController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    if (_navigating) return;
    _navigating = true;
    HapticFeedback.lightImpact();
    _exitController.forward().then((_) {
      if (!mounted) return;
      _loopController.stop();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 550),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.04, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    final accent = isDark ? AppColors.gold : AppColors.emeraldGreen;
    final subtitleColor = isDark
        ? AppColors.gold.withValues(alpha: 0.6)
        : AppColors.lightTextSecondary;
    final faintText = isDark
        ? AppColors.darkTextSecondary.withValues(alpha: 0.5)
        : AppColors.lightTextSecondary.withValues(alpha: 0.7);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF040C07) : Colors.white,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _navigateToHome,
          child: FadeTransition(
            opacity: _exitFade,
            child: SlideTransition(
              position: _exitSlide,
              child: SizedBox.expand(
                child: Stack(
                  children: [
                    // ── Static backdrop: gradient + tiled arabesque + corners.
                    // Painted once, faded in by the transition, never rebuilt.
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: FadeTransition(
                          opacity: _bgFade,
                          child: _buildStaticBackdrop(isDark),
                        ),
                      ),
                    ),

                    // ── Rotating geometry rings
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: FadeTransition(
                          opacity: _bgFade,
                          child: ScaleTransition(
                            scale: _geometryBloom,
                            child: Opacity(
                              opacity: 0.85,
                              child: AnimatedBuilder(
                                animation: _loopController,
                                builder: (context, _) => CustomPaint(
                                  painter: _IslamicGeometryPainter(
                                    rotation: _loopController.value * 2 * math.pi,
                                    color: isDark
                                        ? AppColors.emeraldGreen.withValues(alpha: 0.14)
                                        : AppColors.emeraldGreen.withValues(alpha: 0.11),
                                    goldColor: isDark
                                        ? AppColors.gold.withValues(alpha: 0.09)
                                        : AppColors.emeraldGreen.withValues(alpha: 0.08),
                                    center: Offset(size.width / 2, size.height * 0.42),
                                    screenWidth: size.width,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Drifting particles
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: FadeTransition(
                          opacity: _bgFade,
                          child: Opacity(
                            opacity: isDark ? 0.6 : 0.45,
                            child: AnimatedBuilder(
                              animation: _loopController,
                              builder: (context, _) => CustomPaint(
                                painter: _ParticlePainter(
                                  particles: _particles,
                                  progress: _loopController.value,
                                  color: isDark ? AppColors.gold : AppColors.emeraldGreen,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Breathing glow behind the title
                    Positioned.fill(
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _loopController,
                            builder: (context, _) {
                              final breathe =
                                  math.sin(_loopController.value * 2 * math.pi) * 0.5 + 0.5;
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: const Alignment(0, -0.08),
                                    radius: 0.48 + (breathe * 0.08),
                                    colors: isDark
                                        ? [
                                            AppColors.gold
                                                .withValues(alpha: 0.05 + breathe * 0.03),
                                            Colors.transparent,
                                          ]
                                        : [
                                            AppColors.emeraldGreen
                                                .withValues(alpha: 0.04 + breathe * 0.02),
                                            Colors.transparent,
                                          ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // ── Content
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _entrance(
                              _bismillahFade,
                              _bismillahSlide,
                              Text(
                                'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                                style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400,
                                    color: accent.withValues(alpha: 0.85),
                                    height: 1.8),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 22),
                            _buildOrnamentLine(_topLineFade, _topLineWidth, accent),
                            const SizedBox(height: 28),
                            _entrance(
                              _titleFade,
                              _titleSlide,
                              Column(children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: isDark
                                        ? [
                                            AppColors.darkTextPrimary,
                                            AppColors.gold.withValues(alpha: 0.85)
                                          ]
                                        : [AppColors.emeraldGreen, AppColors.deepGreen],
                                  ).createShader(bounds),
                                  child: const Text('أحزاب',
                                      style: TextStyle(
                                          fontFamily: 'ReemKufi',
                                          fontSize: 62,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          height: 1.5,
                                          letterSpacing: 5),
                                      textAlign: TextAlign.center),
                                ),
                                const SizedBox(height: 6),
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: isDark
                                        ? [
                                            AppColors.gold.withValues(alpha: 0.9),
                                            AppColors.darkTextPrimary
                                          ]
                                        : [AppColors.deepGreen, AppColors.primaryGreen],
                                  ).createShader(bounds),
                                  child: const Text('الإمام الشاذلي',
                                      style: TextStyle(
                                          fontFamily: 'ReemKufi',
                                          fontSize: 42,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          height: 1.5,
                                          letterSpacing: 3),
                                      textAlign: TextAlign.center),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 18),
                            _entrance(
                              _subtitleFade,
                              _subtitleSlide,
                              Column(children: [
                                Text(
                                    'إِمَامُ الْعَارِفِينَ وَقُطْبُ الْأَقْطَابِ وَكَهْفُ أَمْنِ الطُّلَّابِ',
                                    style: TextStyle(
                                        fontFamily: 'ScheherazadeNew',
                                        fontSize: 16,
                                        color: subtitleColor,
                                        height: 1.7),
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 6),
                                Text('رضي الله عنه',
                                    style: TextStyle(
                                        fontFamily: 'ScheherazadeNew',
                                        fontSize: 17,
                                        color: faintText,
                                        height: 1.6),
                                    textAlign: TextAlign.center),
                              ]),
                            ),
                            const SizedBox(height: 26),
                            _buildOrnamentLine(_bottomLineFade, _bottomLineWidth, accent),
                            const SizedBox(height: 22),
                            _entrance(
                              _duaFade,
                              _duaSlide,
                              Text('اللَّهُمَّ انْفَعْنَا بِهِ',
                                  style: TextStyle(
                                      fontFamily: 'ScheherazadeNew',
                                      fontSize: 17,
                                      color: faintText,
                                      height: 1.6),
                                  textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Fades + lifts [child] without ever rebuilding it.
  Widget _entrance(Animation<double> fade, Animation<double> slide, Widget child) {
    return FadeTransition(
      opacity: fade,
      child: AnimatedBuilder(
        animation: slide,
        builder: (context, c) =>
            Transform.translate(offset: Offset(0, slide.value), child: c),
        child: child,
      ),
    );
  }

  Widget _buildStaticBackdrop(bool isDark) {
    return Stack(
      children: [
        const Positioned.fill(child: _StaticGradientBg()),
        Positioned.fill(
          child: Opacity(
            opacity: isDark ? 0.45 : 0.4,
            child: ShaderMask(
              shaderCallback: (bounds) => RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.45),
                  Colors.white.withValues(alpha: 0.75),
                ],
                stops: const [0.0, 0.2, 0.5, 1.0],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: CustomPaint(
                painter: _TiledArabesquePainter(
                  color: AppColors.emeraldGreen
                      .withValues(alpha: isDark ? 0.22 : 0.16),
                ),
              ),
            ),
          ),
        ),
        ..._buildCornerArabesques(isDark),
      ],
    );
  }

  List<Widget> _buildCornerArabesques(bool isDark) {
    final c1 = isDark ? AppColors.gold.withValues(alpha: 0.35) : AppColors.emeraldGreen.withValues(alpha: 0.22);
    final c2 = isDark ? AppColors.emeraldGreen.withValues(alpha: 0.28) : AppColors.emeraldGreen.withValues(alpha: 0.16);
    final op1 = isDark ? 0.4 : 0.3;
    final op2 = isDark ? 0.25 : 0.2;
    return [
      Positioned(top: -15, right: -15, child: Opacity(opacity: op1,
        child: CustomPaint(size: const Size(220, 220), painter: _CornerArabesquePainter(color: c1)))),
      Positioned(bottom: -15, left: -15, child: Opacity(opacity: op1,
        child: Transform.rotate(angle: math.pi, child: CustomPaint(size: const Size(220, 220), painter: _CornerArabesquePainter(color: c1))))),
      Positioned(top: -15, left: -15, child: Opacity(opacity: op2,
        child: Transform.rotate(angle: math.pi / 2, child: CustomPaint(size: const Size(160, 160), painter: _CornerArabesquePainter(color: c2))))),
      Positioned(bottom: -15, right: -15, child: Opacity(opacity: op2,
        child: Transform.rotate(angle: -math.pi / 2, child: CustomPaint(size: const Size(160, 160), painter: _CornerArabesquePainter(color: c2))))),
    ];
  }

  Widget _buildOrnamentLine(
      Animation<double> fade, Animation<double> widthFraction, Color accent) {
    return FadeTransition(
      opacity: fade,
      child: AnimatedBuilder(
        animation: widthFraction,
        builder: (context, child) =>
            SizedBox(width: 240 * widthFraction.value, child: child),
        child: Row(children: [
          Expanded(
              child: Container(
                  height: 0.5,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                    Colors.transparent,
                    accent.withValues(alpha: 0.5)
                  ])))),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('۞',
                  style: TextStyle(
                      fontSize: 14, color: accent.withValues(alpha: 0.55)))),
          Expanded(
              child: Container(
                  height: 0.5,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                    accent.withValues(alpha: 0.5),
                    Colors.transparent
                  ])))),
        ]),
      ),
    );
  }
}

// ── Static gradient background (never repaints) ──
class _StaticGradientBg extends StatelessWidget {
  const _StaticGradientBg();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.2), radius: 1.2,
          colors: isDark
              ? const [Color(0xFF163D24), Color(0xFF0D2415), Color(0xFF081A0E), Color(0xFF040C07)]
              : const [Color(0xFFE8F5EC), Color(0xFFF0F7F2), Color(0xFFF8FCF9), Colors.white],
          stops: const [0.0, 0.35, 0.65, 1.0],
        ),
      ),
    );
  }
}

// ── Particles (12, NO blur — blur is extremely expensive) ──
class _FloatingParticle {
  final double x, startY, speed, size, opacity, phase;
  _FloatingParticle(math.Random rng)
      : x = rng.nextDouble(),
        startY = rng.nextDouble(),
        speed = 0.2 + rng.nextDouble() * 0.3,
        size = 2.0 + rng.nextDouble() * 2.5,
        opacity = 0.2 + rng.nextDouble() * 0.35,
        phase = rng.nextDouble() * 2 * math.pi;
}

class _ParticlePainter extends CustomPainter {
  final List<_FloatingParticle> particles;
  final double progress;
  final Color color;
  _ParticlePainter({required this.particles, required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final y = (p.startY - progress * p.speed) % 1.0;
      final x = p.x + math.sin(progress * 2 * math.pi + p.phase) * 0.015;
      final edgeFade = y < 0.1 ? y / 0.1 : (y > 0.9 ? (1.0 - y) / 0.1 : 1.0);
      paint.color = color.withValues(alpha: p.opacity * edgeFade);
      canvas.drawCircle(Offset(x * size.width, y * size.height), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => progress != old.progress;
}

// ── Geometry — 2 rings instead of 5 ──
class _IslamicGeometryPainter extends CustomPainter {
  final double rotation;
  final Color color, goldColor;
  final Offset center;
  final double screenWidth;
  _IslamicGeometryPainter({required this.rotation, required this.color, required this.goldColor, required this.center, required this.screenWidth});

  @override
  void paint(Canvas canvas, Size size) {
    _drawRing(canvas, center, screenWidth * 0.72, 8, rotation, color, 0.7);
    _drawRing(canvas, center, screenWidth * 0.42, 12, -rotation * 0.6, goldColor, 0.5);
  }

  void _drawRing(Canvas canvas, Offset c, double r, int pts, double angle, Color col, double sw) {
    final paint = Paint()..color = col..style = PaintingStyle.stroke..strokeWidth = sw;
    final path = Path();
    for (int i = 0; i <= pts; i++) {
      final t = angle + (2 * math.pi * i / pts);
      final p = Offset(c.dx + r * math.cos(t), c.dy + r * math.sin(t));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, paint);

    if (pts >= 6) {
      final step = pts ~/ 3;
      paint..color = col.withValues(alpha: col.a * 0.45)..strokeWidth = sw * 0.5;
      for (int i = 0; i < pts; i++) {
        final t1 = angle + (2 * math.pi * i / pts);
        final t2 = angle + (2 * math.pi * ((i + step) % pts) / pts);
        canvas.drawLine(
          Offset(c.dx + r * math.cos(t1), c.dy + r * math.sin(t1)),
          Offset(c.dx + r * math.cos(t2), c.dy + r * math.sin(t2)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_IslamicGeometryPainter old) => rotation != old.rotation;
}

// ── Tiled arabesque (static — painted once) ──
class _TiledArabesquePainter extends CustomPainter {
  final Color color;
  _TiledArabesquePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 0.8;
    const ts = 44.0;
    final cols = (size.width / ts).ceil() + 1;
    final rows = (size.height / ts).ceil() + 1;
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final cx = col * ts + (row.isOdd ? ts / 2 : 0);
        final cy = row * ts;
        _star8(canvas, cx, cy, ts * 0.36, paint);
      }
    }
  }

  void _star8(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final oa = (i * math.pi / 4) - math.pi / 8;
      final ia = oa + math.pi / 8;
      if (i == 0) path.moveTo(cx + r * math.cos(oa), cy + r * math.sin(oa));
      else path.lineTo(cx + r * math.cos(oa), cy + r * math.sin(oa));
      path.lineTo(cx + (r * 0.42) * math.cos(ia), cy + (r * 0.42) * math.sin(ia));
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(cx, cy), r * 0.18, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Corner arabesque (static) ──
class _CornerArabesquePainter extends CustomPainter {
  final Color color;
  _CornerArabesquePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width;
    const cy = 0.0;
    final maxR = size.width * 0.95;
    final paint = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;

    for (int i = 0; i < 6; i++) {
      final r = maxR * (0.28 + i * 0.12);
      paint..color = color.withValues(alpha: color.a * (1.0 - i * 0.12).clamp(0.3, 1.0))
           ..strokeWidth = (2.2 - i * 0.3).clamp(0.5, 2.2);
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), math.pi * 0.5, math.pi * 0.5, false, paint);
    }

    for (int i = 0; i < 8; i++) {
      final a = math.pi * 0.5 + (math.pi * 0.5 * i / 7);
      paint..color = color.withValues(alpha: color.a * 0.3)..strokeWidth = 0.5;
      canvas.drawLine(
        Offset(cx + maxR * 0.22 * math.cos(a), cy + maxR * 0.22 * math.sin(a)),
        Offset(cx + maxR * 0.82 * math.cos(a), cy + maxR * 0.82 * math.sin(a)), paint);
    }

    // Small star
    final sr = maxR * 0.1;
    final sc = Offset(cx - maxR * 0.14, cy + maxR * 0.14);
    final sp = Path();
    for (int i = 0; i < 8; i++) {
      final oa = (i * math.pi / 4) - math.pi / 8;
      final ia = oa + math.pi / 8;
      if (i == 0) sp.moveTo(sc.dx + sr * math.cos(oa), sc.dy + sr * math.sin(oa));
      else sp.lineTo(sc.dx + sr * math.cos(oa), sc.dy + sr * math.sin(oa));
      sp.lineTo(sc.dx + (sr * 0.45) * math.cos(ia), sc.dy + (sr * 0.45) * math.sin(ia));
    }
    sp.close();
    paint..color = color.withValues(alpha: color.a * 0.6)..strokeWidth = 0.8..style = PaintingStyle.stroke;
    canvas.drawPath(sp, paint);

    // Dots
    paint.style = PaintingStyle.fill;
    for (int i = 0; i < 10; i++) {
      final a = math.pi * 0.5 + (math.pi * 0.5 * i / 9);
      paint.color = color.withValues(alpha: color.a * 0.4);
      canvas.drawCircle(Offset(cx + maxR * 0.5 * math.cos(a), cy + maxR * 0.5 * math.sin(a)), 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
