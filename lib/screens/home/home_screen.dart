import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/smooth_scroll_physics.dart';
import '../../core/arabic_normalizer.dart';
import '../../data/ahzab_data.dart';
import '../../models/hizb_part.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/theme_provider.dart';
import '../support/support_screen.dart';
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
  Timer? _debounce;
  bool _initialAnimationDone = false;

  @override
  void initState() {
    super.initState();
    // Mark initial animation done after first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _initialAnimationDone = true);
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _searchText = value);
    });
  }

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
            IconButton(
              icon: const Icon(Icons.volunteer_activism_rounded, size: 22),
              tooltip: 'ساهم بالأجر',
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SupportScreen()),
                );
              },
            ),
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
            HizbSearchBar(onChanged: _onSearchChanged),
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
    final normalizedQuery = normalizeArabic(_searchText);
    final filtered = allParts.where((p) {
      if (_searchText.isEmpty) return true;
      return normalizeArabic(p.title).contains(normalizedQuery) ||
          (p.subtitle != null && normalizeArabic(p.subtitle!).contains(normalizedQuery)) ||
          normalizeArabic(p.content).contains(normalizedQuery);
    }).toList();

    final favList =
        filtered.where((p) => favProvider.isFavorite(p.id)).toList();
    final otherList =
        filtered.where((p) => !favProvider.isFavorite(p.id)).toList();

    // Build a flat list of items: [fav header?, fav cards..., spacer?, all header, all cards..., bottom spacer]
    final items = <_ListItem>[];

    if (favList.isNotEmpty) {
      items.add(_ListItem.header(key: 'header_fav', widget: SectionHeader(
        title: 'مميز',
        icon: Icons.favorite,
        color: Colors.red.shade600,
      )));
      for (final part in favList) {
        items.add(_ListItem.card(part: part, isFavorite: true, searchQuery: _searchText));
      }
      items.add(const _ListItem.spacer(key: 'spacer_fav', height: 16));
    }

    items.add(_ListItem.header(key: 'header_all', widget: SectionHeader(
      title: 'جميع الأحزاب',
      icon: Icons.menu_book,
      color: AppColors.emeraldGreen,
    )));
    for (final part in otherList) {
      items.add(_ListItem.card(part: part, isFavorite: false, searchQuery: _searchText));
    }
    items.add(const _ListItem.spacer(key: 'spacer_bottom', height: 24));

    return CustomScrollView(
      physics: const SmoothScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      cacheExtent: 600,
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = items[index];
              switch (item.type) {
                case _ItemType.header:
                  return item.widget!;
                case _ItemType.spacer:
                  return SizedBox(height: item.height);
                case _ItemType.card:
                  return _CardWrapper(
                    key: ValueKey(item.part!.id),
                    staggerIndex: _initialAnimationDone ? -1 : index,
                    child: HizbCard(
                      part: item.part!,
                      isFavorite: item.isFavorite,
                      searchQuery: item.searchQuery,
                    ),
                  );
              }
            },
            childCount: items.length,
            findChildIndexCallback: (key) {
              // Help Flutter find cards by key so it can reuse them across rebuilds
              if (key is ValueKey<String>) {
                for (int i = 0; i < items.length; i++) {
                  if (items[i].type == _ItemType.card && items[i].part!.id == key.value) {
                    return i;
                  }
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}

enum _ItemType { header, spacer, card }

class _ListItem {
  final _ItemType type;
  final String? key;
  final Widget? widget;
  final double? height;
  final HizbPart? part;
  final bool isFavorite;
  final String searchQuery;

  const _ListItem._({
    required this.type,
    this.key,
    this.widget,
    this.height,
    this.part,
    this.isFavorite = false,
    this.searchQuery = '',
  });

  _ListItem.header({required String key, required Widget widget})
      : this._(type: _ItemType.header, key: key, widget: widget);

  const _ListItem.spacer({required String key, required double height})
      : this._(type: _ItemType.spacer, key: key, height: height);

  _ListItem.card({required HizbPart part, required bool isFavorite, String searchQuery = ''})
      : this._(type: _ItemType.card, part: part, isFavorite: isFavorite, searchQuery: searchQuery);
}

/// Card wrapper that handles:
/// 1. One-shot stagger animation on initial app load (staggerIndex >= 0)
/// 2. Smooth animated transition when moving between sections (staggerIndex == -1)
///
/// Uses the same key (part.id) regardless of section, so Flutter reuses the
/// Element when a card moves from favorites↔all — no dispose/recreate.
class _CardWrapper extends StatefulWidget {
  final int staggerIndex;
  final Widget child;

  const _CardWrapper({
    super.key,
    required this.staggerIndex,
    required this.child,
  });

  @override
  State<_CardWrapper> createState() => _CardWrapperState();
}

class _CardWrapperState extends State<_CardWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.12, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.staggerIndex >= 0) {
      // Initial app load: staggered entrance
      final delay = (widget.staggerIndex * 35).clamp(0, 280);
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) {
          _controller.forward();
          _hasAnimated = true;
        }
      });
    } else {
      // After initial load: appear instantly
      _controller.value = 1.0;
      _hasAnimated = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}
