import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';
import 'widgets/onboarding_demos.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const _seenKey = 'onboarding_seen_v1';

  static Future<bool> hasBeenSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;
  bool _leaving = false;

  late final List<_Page> _pages = [
    _Page(
      icon: Icons.spa_rounded,
      title: 'أَهْلًا بِكَ',
      body:
          'أحزاب سيدي أبي الحسن الشاذلي رضي الله عنه بين يديك، مضبوطةً بالشكل. '
          'دقيقةٌ واحدة تُعرِّفك على التطبيق.',
      demo: (active) => WelcomeDemo(active: active),
    ),
    _Page(
      icon: Icons.auto_stories_rounded,
      title: 'ابْدَأْ بِالْمُقَدِّمَة',
      body:
          'من أيقونة الكتاب في أعلى الشاشة تفتح مقدمة الأحزاب وما يُذكر فيها '
          'من آدابها وشروط قراءتها.',
      hintIcon: Icons.dark_mode_rounded,
      hint: 'وبجوارها أيقونة تنقلك بين الوضع الفاتح والداكن.',
      demo: (active) => AppBarDemo(active: active),
    ),
    _Page(
      icon: Icons.search_rounded,
      title: 'ابْحَثْ فِي كُلِّ الْأَحْزَاب',
      body:
          'اكتب كلمةً في شريط البحث فتظهر الأحزاب التي وردت فيها مع موضعها. '
          'وبعد فتح الحزب تتنقل بين المواضع بالسهمين.',
      hintIcon: Icons.lightbulb_outline_rounded,
      hint: 'مثال: اكتب «الفتح» فيظهر لك حزب الفتح.',
      demo: (active) => SearchDemo(active: active),
    ),
    _Page(
      icon: Icons.pinch_rounded,
      title: 'حَجْمُ الْخَطِّ بَيْنَ يَدَيْك',
      body:
          'باعِد بين إصبعيك على النص ليكبُر الخط، وقرِّبهما ليصغُر. '
          'وانقر نقرتين للعودة إلى الحجم الافتراضي.',
      demo: (active) => ZoomDemo(active: active),
    ),
    _Page(
      icon: Icons.bookmark_add_rounded,
      title: 'ضَعْ عَلَامَةً عَلَى مَوْضِعِك',
      body:
          'اضغط مطولًا على أي كلمة لتحديدها، ثم اختر «علامة مميزة» ليحفظ لك '
          'التطبيق الموضع، أو «نسخ» لنسخ النص.',
      hintIcon: Icons.auto_stories_outlined,
      hint: 'وتعود إلى علاماتك من أيقونة الكتاب داخل الحزب.',
      demo: (active) => BookmarkDemo(active: active),
    ),
    _Page(
      icon: Icons.favorite_rounded,
      title: 'أَحْزَابُكَ الْمُمَيَّزَة',
      body:
          'اضغط على القلب ليُثبَّت الحزب في أعلى القائمة تحت «مميز»، '
          'فتصل إليه سريعًا. ويمكنك تمييز خمسة أحزاب.',
      demo: (active) => FavoriteDemo(active: active),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _pages.length - 1;

  void _next() {
    HapticFeedback.lightImpact();
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_leaving) return;
    _leaving = true;
    await OnboardingScreen.markSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.03, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.emeraldGreen;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        body: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.55),
                      radius: 0.95,
                      colors: [
                        accent.withValues(alpha: isDark ? 0.07 : 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        const Spacer(),
                        AnimatedOpacity(
                          opacity: _isLast ? 0 : 1,
                          duration: const Duration(milliseconds: 250),
                          child: TextButton(
                            onPressed: _isLast ? null : _finish,
                            child: Text(
                              'تخطي',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pages.length,
                      onPageChanged: (i) {
                        HapticFeedback.selectionClick();
                        setState(() => _index = i);
                      },
                      itemBuilder: (context, i) => _PageView(
                        page: _pages[i],
                        index: i,
                        controller: _controller,
                        active: i == _index,
                        accent: accent,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 8, 28, 26),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < _pages.length; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: i == _index ? 22 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: i == _index
                                      ? accent
                                      : accent.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            onPressed: _next,
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: isDark
                                  ? AppColors.darkBackground
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(
                                _isLast ? 'ابدأ الآن' : 'التالي',
                                key: ValueKey(_isLast),
                                style: const TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
}

class _Page {
  const _Page({
    required this.icon,
    required this.title,
    required this.body,
    required this.demo,
    this.hint,
    this.hintIcon,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget Function(bool active) demo;
  final String? hint;
  final IconData? hintIcon;
}

class _PageView extends StatelessWidget {
  const _PageView({
    required this.page,
    required this.index,
    required this.controller,
    required this.active,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
  });

  final _Page page;
  final int index;
  final PageController controller;
  final bool active;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // How far this page sits from the centre of the viewport, in pages.
        final position =
            controller.hasClients && controller.position.haveDimensions
            ? (controller.page ?? controller.initialPage.toDouble())
            : controller.initialPage.toDouble();
        final delta = (index - position).clamp(-1.0, 1.0);
        final fade = (1 - delta.abs() * 1.4).clamp(0.0, 1.0);

        return Opacity(
          opacity: fade,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Transform.translate(
                    offset: Offset(delta * 70, 0),
                    child: Transform.scale(
                      scale: 1 - 0.06 * delta.abs(),
                      child: page.demo(active),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Transform.translate(
                    offset: Offset(delta * 26, 0),
                    child: _Copy(
                      page: page,
                      accent: accent,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Copy extends StatelessWidget {
  const _Copy({
    required this.page,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
  });

  final _Page page;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
            ),
            child: Icon(page.icon, color: accent, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            page.title,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.5,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            page.body,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 17,
              height: 1.9,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (page.hint != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: accent.withValues(alpha: 0.16)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(page.hintIcon, size: 16, color: accent),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      page.hint!,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 15,
                        height: 1.6,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
