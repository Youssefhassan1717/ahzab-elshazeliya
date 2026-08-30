import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/smooth_scroll_physics.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _imam = [
    (
      'نسبه ومولده',
      'هو الإمام أبو الحسن عليّ بن عبد الله بن عبد الجبّار الشاذليّ، '
          'الحسنيّ النسب. وُلد سنة ثلاثٍ وتسعين وخمسمائة للهجرة بقريةٍ من قرى '
          'غُمارة بشمال المغرب، ونشأ على حفظ القرآن الكريم وطلب العلم.'
    ),
    (
      'شيخه وطريقه',
      'رحل في طلب الطريق حتى لَقِيَ شيخه القطب عبد السلام بن مَشِيش '
          'رضي الله عنه بجبل العَلَم، فأخذ عنه وتربّى على يديه، ثم أذِن له '
          'بالتصدّر لتربية المريدين، فنُسبت إليه الطريقة الشاذليّة.'
    ),
    (
      'رحلته ومقامه',
      'انتقل إلى إفريقيّة فنزل مدينة شاذلة، ثم قدِم مصر فاستقرّ بالإسكندريّة، '
          'واجتمع عليه العلماء والصالحون، وكان يجمع بين علوم الشريعة وأذواق '
          'الحقيقة، ويأمر أصحابه بلزوم الكتاب والسنّة.'
    ),
    (
      'وفاته',
      'توفّي رضي الله عنه سنة ستٍّ وخمسين وستّمائة للهجرة بصحراء عَيْذاب '
          'وهو في طريقه إلى الحجّ، ودُفن هناك، ورحمة الله عليه.'
    ),
    (
      'أحزابه',
      'ترك رضي الله عنه أحزاباً وأوراداً مباركة، من أشهرها حزب البحر '
          'وحزب البرّ وحزب النصر وحزب اللطف، وهي أدعية جامعة مبنيّة على '
          'آيات القرآن الكريم والأدعية المأثورة.'
    ),
  ];

  static const _app = [
    (
      'عن التطبيق',
      'جُمعت في هذا التطبيق أحزاب الإمام أبي الحسن الشاذليّ رضي الله عنه '
          'مكتوبةً بخطٍّ واضح، ليسهُل على القارئ ورده اليوميّ في أيّ وقت '
          'وبغير حاجةٍ إلى اتّصال بالإنترنت.'
    ),
    (
      'المميزات',
      'يمكنك البحث داخل جميع الأحزاب، وتمييز ما تحبّ بعلامة مرجعيّة للعودة '
          'إليه، وإضافة الأحزاب المفضّلة، وتكبير الخطّ أو تصغيره بإصبعين، '
          'والتبديل بين الوضع الفاتح والداكن.'
    ),
    (
      'دعوة',
      'نسأل الله أن ينفع به قارئه وكاتبه وناشره، وأن يجعله خالصاً لوجهه '
          'الكريم. ولا تنسونا من صالح دعائكم.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.emeraldGreen;

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
        body: ListView(
          physics: const SmoothScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
          children: [
            _Bismillah(accent: accent, isDark: isDark),
            const SizedBox(height: 22),
            _Heading(text: 'الإمام أبو الحسن الشاذلي', accent: accent),
            for (final (title, body) in _imam)
              _Entry(title: title, body: body, accent: accent, isDark: isDark),
            const SizedBox(height: 10),
            _Heading(text: 'هذا التطبيق', accent: accent),
            for (final (title, body) in _app)
              _Entry(title: title, body: body, accent: accent, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _Bismillah extends StatelessWidget {
  final Color accent;
  final bool isDark;
  const _Bismillah({required this.accent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '\uFDFD',
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 46,
          height: 1.6,
          color:
              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  final Color accent;
  const _Heading({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(child: _rule(accent, true)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
          Expanded(child: _rule(accent, false)),
        ],
      ),
    );
  }

  Widget _rule(Color accent, bool toCentre) {
    final colors = [Colors.transparent, accent.withValues(alpha: 0.45)];
    return Container(
      height: 0.8,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: toCentre ? colors : colors.reversed.toList(),
        ),
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  final String title;
  final String body;
  final Color accent;
  final bool isDark;

  const _Entry({
    required this.title,
    required this.body,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: accent,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontFamily: 'ScheherazadeNew',
              fontSize: 19,
              height: 1.9,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
