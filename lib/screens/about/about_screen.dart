import 'package:flutter/material.dart';
import '../../core/smooth_scroll_physics.dart';
import '../../data/muqaddima.dart';
import '../detail/widgets/content_body.dart';

/// The book's foreword, set in the same face as the ahzab themselves.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  /// Matches the reading size the hizb screen derives from the device width.
  static const _referenceWidth = 411.0;
  static const _referenceFontSize = 24.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final fontSize =
        (_referenceFontSize * width / _referenceWidth).clamp(22.0, 34.0);

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
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 32),
          children: [
            ContentBody(
              content: muqaddima.content,
              title: muqaddima.title,
              bodyFontFamily: ContentBody.mushafFont,
              fontSize: fontSize,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}
