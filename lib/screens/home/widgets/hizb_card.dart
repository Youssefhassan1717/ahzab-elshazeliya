import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/hizb_part.dart';
import '../../../providers/favorites_provider.dart';
import '../../../widgets/islamic_icon.dart';
import '../../detail/detail_screen.dart';

class HizbCard extends StatelessWidget {
  final HizbPart part;

  const HizbCard({super.key, required this.part});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 76,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToDetail(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Islamic icon
                IslamicIcon(
                  size: 32,
                  color: AppColors.emeraldGreen,
                  withBackground: true,
                  isDark: isDark,
                ),
                const SizedBox(width: 10),

                // Book icon circle
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryGreen, AppColors.emeraldGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(21),
                  ),
                  child: const Icon(Icons.menu_book, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),

                // Title & subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        part.title,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.bold,
                          color: AppColors.emeraldGreen,
                          fontSize: 15,
                          height: 1.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (part.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          part.subtitle!,
                          style: TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            height: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Favorite button
                Consumer<FavoritesProvider>(
                  builder: (context, favProvider, _) {
                    final isFav = favProvider.isFavorite(part.id);
                    return _FavoriteButton(
                      isFavorite: isFav,
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        favProvider.toggleFavorite(part.id, context);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) => DetailScreen(part: part),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final tween = Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOutCubic));

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final bool isDark;
  final VoidCallback onTap;

  const _FavoriteButton({
    required this.isFavorite,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isFavorite
              ? Colors.red.withValues(alpha: 0.1)
              : (isDark
                  ? Colors.grey.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.08)),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(isFavorite),
              color: isFavorite
                  ? Colors.red.shade600
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
