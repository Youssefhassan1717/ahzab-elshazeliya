import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/hizb_part.dart';
import '../../../providers/favorites_provider.dart';
import '../../../widgets/islamic_icon.dart';
import '../../detail/detail_screen.dart';

class HizbCard extends StatefulWidget {
  final HizbPart part;
  final bool isFavorite;

  const HizbCard({
    super.key,
    required this.part,
    this.isFavorite = false,
  });

  @override
  State<HizbCard> createState() => _HizbCardState();
}

class _HizbCardState extends State<HizbCard> with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _wasFavorite = false;
  
  // Getter for convenient access
  HizbPart get part => widget.part;

  @override
  void initState() {
    super.initState();
    _wasFavorite = widget.isFavorite;
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(HizbCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite != _wasFavorite) {
      // Trigger animation when favorite status changes
      _animateFavoriteChange(widget.isFavorite);
      _wasFavorite = widget.isFavorite;
    }
  }

  void _animateFavoriteChange(bool isNowFavorite) {
    // Slide animation - move up if added to favorites, down if removed
    final beginOffset = isNowFavorite ? const Offset(0, 0.5) : const Offset(0, -0.5);
    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _slideController.forward(from: 0);
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
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
          // Curved animation for smooth feel
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          // Slide from right with overshoot
          final slideTween = Tween(
            begin: const Offset(0.3, 0.0),
            end: Offset.zero,
          );

          // Fade in with delay
          final fadeTween = Tween<double>(begin: 0.0, end: 1.0);

          // Scale up from 0.9
          final scaleTween = Tween<double>(begin: 0.9, end: 1.0);

          // Combine all transitions
          return FadeTransition(
            opacity: fadeTween.animate(curvedAnimation),
            child: ScaleTransition(
              scale: scaleTween.animate(curvedAnimation),
              child: SlideTransition(
                position: slideTween.animate(curvedAnimation),
                child: child,
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final bool isDark;
  final VoidCallback onTap;

  const _FavoriteButton({
    required this.isFavorite,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: widget.isFavorite
                ? Colors.red.withValues(alpha: 0.15)
                : (widget.isDark
                    ? Colors.grey.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.08)),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.elasticOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(widget.isFavorite),
                color: widget.isFavorite
                    ? Colors.red.shade600
                    : (widget.isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
