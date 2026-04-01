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
  // Phase 1: Background fade-in + geometric pattern bloom
  late final AnimationController _bgController;
  // Phase 2: Content entrance — staggered
  late final AnimationController _contentController;
  // Phase 3: Hold shimmer / breathing glow
  late final AnimationController _breatheController;
  // Phase 4: Exit — everything dissolves upward
  late final AnimationController _exitController;
  // Perpetual: slow geometric rotation
  late final AnimationController _rotationController;

  // Background
  late final Animation<double> _bgFade;
  late final Animation<double> _geometryBloom;
  late final Animation<double> _geometryRotation;

  // Content entrance
  late final Animation<double> _bismillahFade;
  late final Animation<double> _bismillahScale;
  late final Animation<double> _topLineFade;
  late final Animation<double> _topLineWidth;
  late final Animation<double> _titleFade;
  late final Animation<double> _titleScale;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _bottomLineFade;
  late final Animation<double> _bottomLineWidth;
  late final Animation<double> _duaFade;

  // Breathing
  late final Animation<double> _breathe;

  // Exit
  late final Animation<double> _exitFade;
  late final Animation<Offset> _exitSlide;

  bool _navigating = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // ── Controllers ──
    _bgController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _breatheController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _exitController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 90),
      vsync: this,
    )..repeat();

    // ── Background animations ──
    _bgFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeOut),
    );
    _geometryBloom = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeOutCubic),
    );
    _geometryRotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // ── Content entrance (staggered over 3s) ──
    _bismillahFade = _interval(0.0, 0.22, Curves.easeOut);
    _bismillahScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOutCubic),
      ),
    );

    _topLineFade = _interval(0.12, 0.30, Curves.easeOut);
    _topLineWidth = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.12, 0.38, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = _interval(0.28, 0.48, Curves.easeOut);
    _titleScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.28, 0.52, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFade = _interval(0.48, 0.65, Curves.easeOut);

    _bottomLineFade = _interval(0.55, 0.72, Curves.easeOut);
    _bottomLineWidth = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.55, 0.78, curve: Curves.easeOutCubic),
      ),
    );

    _duaFade = _interval(0.70, 0.88, Curves.easeOut);

    // ── Breathing glow ──
    _breathe = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    // ── Exit ──
    _exitFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
    _exitSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.02),
    ).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    // ── Orchestration ──
    _startSequence();
  }

  Animation<double> _interval(double begin, double end, Curve curve) {
    return Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Interval(begin, end, curve: curve),
      ),
    );
  }

  Future<void> _startSequence() async {
    // Phase 1: Background fades in
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _bgController.forward();

    // Phase 2: Content enters (overlaps with bg)
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _contentController.forward();

    // Phase 3: Breathing glow after content settles
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    _breatheController.repeat(reverse: true);

    // Phase 4: Auto-transition
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    _navigateToHome();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _contentController.dispose();
    _breatheController.dispose();
    _exitController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    if (_navigating) return;
    _navigating = true;

    _breatheController.stop();
    _exitController.forward().then((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF050E08),
        body: AnimatedBuilder(
          animation: Listenable.merge([
            _bgController,
            _contentController,
            _breatheController,
            _exitController,
            _rotationController,
          ]),
          builder: (context, _) {
            return SlideTransition(
              position: _exitSlide,
              child: FadeTransition(
                opacity: _exitFade,
                child: _buildBody(context),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final breatheValue = _breatheController.isAnimating ? _breathe.value : 0.0;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          // Deep gradient background
          Positioned.fill(
            child: Opacity(
              opacity: _bgFade.value,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0F2E1A),
                      Color(0xFF0A1A0F),
                      Color(0xFF060F09),
                      Color(0xFF050E08),
                    ],
                    stops: [0.0, 0.35, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Geometric pattern
          Positioned.fill(
            child: Opacity(
              opacity: _bgFade.value * 0.6,
              child: Transform.scale(
                scale: _geometryBloom.value,
                child: CustomPaint(
                  painter: _IslamicGeometryPainter(
                    rotation: _geometryRotation.value,
                    color: AppColors.emeraldGreen.withValues(alpha: 0.035),
                    goldColor: AppColors.gold.withValues(alpha: 0.018),
                    center: Offset(size.width / 2, size.height * 0.42),
                    screenWidth: size.width,
                  ),
                ),
              ),
            ),
          ),

          // Center radial glow — breathes
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.05),
                  radius: 0.5 + (breatheValue * 0.08),
                  colors: [
                    AppColors.emeraldGreen
                        .withValues(alpha: 0.07 + breatheValue * 0.03),
                    AppColors.gold.withValues(alpha: 0.02 + breatheValue * 0.01),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // Content — perfectly centered
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // بسم الله الرحمن الرحيم
                  Opacity(
                    opacity: _bismillahFade.value,
                    child: Transform.scale(
                      scale: _bismillahScale.value,
                      child: Text(
                        'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: AppColors.gold.withValues(alpha: 0.8),
                          height: 1.8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Top ornamental line
                  _buildOrnamentLine(_topLineFade.value, _topLineWidth.value),

                  const SizedBox(height: 36),

                  // Main title — elegant with gold accent
                  Opacity(
                    opacity: _titleFade.value,
                    child: Transform.scale(
                      scale: _titleScale.value,
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.darkTextPrimary,
                                AppColors.gold.withValues(alpha: 0.85),
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'أحزاب',
                              style: TextStyle(
                                fontFamily: 'ReemKufi',
                                fontSize: 64,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                                letterSpacing: 6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.gold.withValues(alpha: 0.9),
                                AppColors.darkTextPrimary,
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'الإمام الشاذلي',
                              style: TextStyle(
                                fontFamily: 'ReemKufi',
                                fontSize: 44,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.3,
                                letterSpacing: 3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Description + رضي الله عنه
                  Opacity(
                    opacity: _subtitleFade.value,
                    child: Column(
                      children: [
                        Text(
                          'إِمَامُ الْعَارِفِينَ وَقُطْبُ الْأَقْطَابِ وَكَهْفُ أَمْنِ الطُّلَّابِ',
                          style: TextStyle(
                            fontFamily: 'ScheherazadeNew',
                            fontSize: 16,
                            color: AppColors.gold.withValues(alpha: 0.6),
                            height: 1.7,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'رضي الله عنه',
                          style: TextStyle(
                            fontFamily: 'ScheherazadeNew',
                            fontSize: 17,
                            color: AppColors.darkTextSecondary.withValues(alpha: 0.45),
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Bottom ornamental line
                  _buildOrnamentLine(
                    _bottomLineFade.value,
                    _bottomLineWidth.value,
                  ),

                  const SizedBox(height: 32),

                  // Dua
                  Opacity(
                    opacity: _duaFade.value,
                    child: Text(
                      'اللَّهُمَّ انْفَعْنَا بِهِ',
                      style: TextStyle(
                        fontFamily: 'ScheherazadeNew',
                        fontSize: 17,
                        color: AppColors.darkTextSecondary.withValues(alpha: 0.5),
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrnamentLine(double fade, double widthFraction) {
    return Opacity(
      opacity: fade,
      child: SizedBox(
        width: 220 * widthFraction,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 0.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.gold.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '۞',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.gold.withValues(alpha: 0.5),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 0.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtle Islamic geometric star patterns
class _IslamicGeometryPainter extends CustomPainter {
  final double rotation;
  final Color color;
  final Color goldColor;
  final Offset center;
  final double screenWidth;

  _IslamicGeometryPainter({
    required this.rotation,
    required this.color,
    required this.goldColor,
    required this.center,
    required this.screenWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Outer 8-pointed star ring
    _drawStarRing(canvas, center, screenWidth * 0.75, 8, rotation, color, 0.6);
    // Mid 12-pointed ring — counter-rotates
    _drawStarRing(
        canvas, center, screenWidth * 0.45, 12, -rotation * 0.6, goldColor, 0.5);
    // Inner 6-pointed — faster
    _drawStarRing(
        canvas, center, screenWidth * 0.22, 6, rotation * 1.4, color, 0.7);
  }

  void _drawStarRing(Canvas canvas, Offset c, double r, int points,
      double angle, Color col, double strokeWidth) {
    final paint = Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Polygon
    final path = Path();
    for (int i = 0; i <= points; i++) {
      final theta = angle + (2 * math.pi * i / points);
      final x = c.dx + r * math.cos(theta);
      final y = c.dy + r * math.sin(theta);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);

    // Star: connect every-other vertex
    if (points >= 6) {
      final step = points ~/ 3;
      final starPaint = Paint()
        ..color = col.withValues(alpha: col.a * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.6;
      for (int i = 0; i < points; i++) {
        final t1 = angle + (2 * math.pi * i / points);
        final t2 = angle + (2 * math.pi * ((i + step) % points) / points);
        canvas.drawLine(
          Offset(c.dx + r * math.cos(t1), c.dy + r * math.sin(t1)),
          Offset(c.dx + r * math.cos(t2), c.dy + r * math.sin(t2)),
          starPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_IslamicGeometryPainter old) => rotation != old.rotation;
}
