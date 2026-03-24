import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/smooth_scroll_physics.dart';
import '../../data/ahzab_data.dart';
import '../../models/hizb_part.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/animated_list_item.dart';
import 'widgets/hizb_card.dart';
import 'widgets/search_bar.dart';
import 'widgets/section_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchText = '';

  // Animated list keys for smooth transitions
  final GlobalKey<AnimatedListState> _favoritesListKey = GlobalKey<AnimatedListState>();
  final GlobalKey<AnimatedListState> _allListKey = GlobalKey<AnimatedListState>();

  // Track items in each section for animation
  List<HizbPart> _favorites = [];
  List<HizbPart> _allItems = [];

  // Keep track of previous state to detect changes
  Set<String> _previousFavorites = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'أحزاب الإمام الشاذلي',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return RotationTransition(
                        turns: Tween(begin: 0.75, end: 1.0).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: Icon(
                      themeProvider.isDarkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      key: ValueKey(themeProvider.isDarkMode),
                    ),
                  ),
                  tooltip:
                      themeProvider.isDarkMode ? 'الوضع الفاتح' : 'الوضع الداكن',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    themeProvider.toggleTheme();
                  },
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            HizbSearchBar(
              onChanged: (value) {
                setState(() => _searchText = value);
              },
            ),
            Expanded(
              child: Consumer<FavoritesProvider>(
                builder: (context, favProvider, _) {
                  return _buildContent(favProvider, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(FavoritesProvider favProvider, bool isDark) {
    final filtered = allParts.where((p) {
      return p.title.contains(_searchText) ||
          (p.subtitle?.contains(_searchText) ?? false);
    }).toList();

    final favList =
        filtered.where((p) => favProvider.isFavorite(p.id)).toList();
    final otherList =
        filtered.where((p) => !favProvider.isFavorite(p.id)).toList();

    // Detect changes and trigger animations
    _handleFavoriteChanges(favProvider, favList, otherList);

    return CustomScrollView(
      physics: const SmoothScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      cacheExtent: 1200,
      slivers: [
        // Favorites section
        if (favList.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'مميز',
              icon: Icons.favorite,
              color: Colors.red.shade600,
            ),
          ),
          SliverFixedExtentList(
            itemExtent: 86,
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildAnimatedCard(
                  part: favList[index],
                  index: index,
                  isFavorite: true,
                );
              },
              childCount: favList.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],

        // All ahzab section
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'جميع الأحزاب',
            icon: Icons.menu_book,
            color: AppColors.emeraldGreen,
          ),
        ),
        SliverFixedExtentList(
          itemExtent: 86,
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return _buildAnimatedCard(
                part: otherList[index],
                index: index + favList.length,
                isFavorite: false,
              );
            },
            childCount: otherList.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildAnimatedCard({
    required HizbPart part,
    required int index,
    required bool isFavorite,
  }) {
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300 + (index * 30).clamp(0, 200)),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(30 * (1 - value), 0),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          child: HizbCard(
            part: part,
            isFavorite: isFavorite,
          ),
        ),
      ),
    );
  }

  void _handleFavoriteChanges(
    FavoritesProvider favProvider,
    List<HizbPart> newFavorites,
    List<HizbPart> newOthers,
  ) {
    final currentFavorites = favProvider.favorites;

    // Check for new favorites (added)
    for (final id in currentFavorites) {
      if (!_previousFavorites.contains(id)) {
        // New favorite added - could trigger animation here
        HapticFeedback.mediumImpact();
      }
    }

    _previousFavorites = currentFavorites;
  }
}
