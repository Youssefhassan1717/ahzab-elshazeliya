import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/bookmarks_provider.dart';

class BookmarksPanel extends StatelessWidget {
  final String hizbId;
  final void Function(String text) onBookmarkTap;

  const BookmarksPanel({
    super.key,
    required this.hizbId,
    required this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.emeraldGreen;

    return Consumer<BookmarksProvider>(
      builder: (context, provider, _) {
        return FutureBuilder<List<Bookmark>>(
          future: provider.getBookmarks(hizbId),
          builder: (context, snapshot) {
            final bookmarks = snapshot.data ?? [];

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
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
                          Icon(
                            Icons.bookmark_rounded,
                            color: accent,
                            size: 22,
                          ),
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
                            '${bookmarks.length}',
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
                    if (bookmarks.isEmpty)
                      _buildEmptyState(isDark, accent)
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                          itemCount: bookmarks.length,
                          itemBuilder: (context, index) {
                            return _BookmarkItem(
                              bookmark: bookmarks[index],
                              isDark: isDark,
                              accent: accent,
                              onTap: () {
                                Navigator.of(context).pop();
                                onBookmarkTap(bookmarks[index].text);
                              },
                              onDelete: () {
                                HapticFeedback.lightImpact();
                                provider.removeBookmark(
                                    hizbId, bookmarks[index].text);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
