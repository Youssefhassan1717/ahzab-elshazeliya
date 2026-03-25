import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/bookmarks_provider.dart';

class BookmarksPanel extends StatefulWidget {
  final String hizbId;
  final void Function(String text) onBookmarkTap;

  const BookmarksPanel({
    super.key,
    required this.hizbId,
    required this.onBookmarkTap,
  });

  @override
  State<BookmarksPanel> createState() => _BookmarksPanelState();
}

class _BookmarksPanelState extends State<BookmarksPanel> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Bookmark> _bookmarks = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final provider = context.read<BookmarksProvider>();
    final bookmarks = await provider.getBookmarks(widget.hizbId);
    if (mounted) {
      setState(() {
        _bookmarks = List.from(bookmarks);
        _loaded = true;
      });
    }
  }

  void _deleteBookmark(int index) {
    final bookmark = _bookmarks[index];
    HapticFeedback.mediumImpact();

    // Remove from animated list with slide-out
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildAnimatedItem(bookmark, animation),
      duration: const Duration(milliseconds: 300),
    );

    // Remove from local list and provider
    setState(() => _bookmarks.removeAt(index));
    context.read<BookmarksProvider>().removeBookmark(widget.hizbId, bookmark.text);

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تم حذف العلامة',
          style: TextStyle(fontFamily: 'ScheherazadeNew'),
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.emeraldGreen;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.55,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.bookmark_rounded, color: accent, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'العلامات المميزة',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_bookmarks.length}',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 14,
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.0),
                      accent.withValues(alpha: 0.3),
                      accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            if (!_loaded)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator.adaptive(),
              )
            else if (_bookmarks.isEmpty)
              _buildEmptyState(isDark, accent)
            else
              Flexible(
                child: AnimatedList(
                  key: _listKey,
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  initialItemCount: _bookmarks.length,
                  itemBuilder: (context, index, animation) {
                    if (index >= _bookmarks.length) return const SizedBox.shrink();
                    return _buildAnimatedItem(_bookmarks[index], animation, index: index);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedItem(Bookmark bookmark, Animation<double> animation, {int? index}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.emeraldGreen;

    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-0.3, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: _BookmarkItem(
            bookmark: bookmark,
            isDark: isDark,
            accent: accent,
            onTap: index != null
                ? () {
                    Navigator.of(context).pop();
                    widget.onBookmarkTap(bookmark.text);
                  }
                : () {},
            onDelete: index != null ? () => _deleteBookmark(index) : () {},
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 44,
            color: accent.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد علامات',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 16,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'حدد نصاً واضغط "علامة مميزة"',
            style: TextStyle(
              fontFamily: 'ScheherazadeNew',
              fontSize: 13,
              color: (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary)
                  .withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkItem extends StatelessWidget {
  final Bookmark bookmark;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookmarkItem({
    required this.bookmark,
    required this.isDark,
    required this.accent,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          splashColor: accent.withValues(alpha: 0.08),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
              ),
              color: accent.withValues(alpha: isDark ? 0.05 : 0.02),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  size: 18,
                  color: accent.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bookmark.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'ScheherazadeNew',
                      fontSize: 14,
                      height: 1.6,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withValues(alpha: isDark ? 0.12 : 0.08),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Colors.red.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
