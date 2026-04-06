import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../services/rewarded_ad_service.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {
  bool _thanked = false;
  bool _loading = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _watchAd() {
    setState(() => _loading = true);
    HapticFeedback.lightImpact();

    RewardedAdService.instance.showAd(
      onRewarded: () {
        if (mounted) setState(() => _thanked = true);
      },
      onDismissed: () {
        if (mounted) setState(() => _loading = false);
      },
      onFailed: () {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'الإعلان غير جاهز حالياً، حاول مرة أخرى بعد قليل',
                style: TextStyle(fontFamily: 'ScheherazadeNew'),
              ),
              backgroundColor: AppColors.emeraldGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            ),
          );
        }
      },
    );
  }

  void _watchAgain() {
    setState(() {
      _thanked = false;
      _loading = false;
    });
    _watchAd();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.emeraldGreen;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          title: Text(
            'ساهم بالأجر',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_forward_ios_rounded,
                size: 20,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: FadeTransition(
          opacity: _fadeIn,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _thanked
                          ? Icons.favorite_rounded
                          : Icons.volunteer_activism_rounded,
                      size: 36,
                      color: _thanked ? Colors.red.shade400 : accent,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Message
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      _thanked
                          ? 'جزاك الله خيراً ❤️\nأسأل الله أن يجعل ذلك في ميزان حسناتك.'
                          : 'عائد الإعلانات يُصرف في سبيل الله.\nساهم بمشاهدة إعلان قصير واحتسب الأجر.',
                      key: ValueKey(_thanked),
                      style: TextStyle(
                        fontFamily: 'ScheherazadeNew',
                        fontSize: 19,
                        height: 1.8,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading
                          ? null
                          : (_thanked ? _watchAgain : _watchAd),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            accent.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            )
                          : Text(
                              _thanked
                                  ? 'مشاهدة إعلان آخر'
                                  : 'مشاهدة إعلان',
                              style: const TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),

                  if (_thanked) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'رجوع',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 15,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
