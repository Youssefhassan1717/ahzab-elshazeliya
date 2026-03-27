import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Bookmark {
  final String text;
  final double scrollFraction; // scroll position as fraction of maxScrollExtent (0.0–1.0)
  final int matchIndex; // which occurrence of this text in the content (0-based)
  final DateTime createdAt;

  Bookmark({required this.text, this.scrollFraction = 0.0, this.matchIndex = 0, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'text': text,
        'scrollFraction': scrollFraction,
        'matchIndex': matchIndex,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        text: json['text'] as String,
        scrollFraction: (json['scrollFraction'] as num?)?.toDouble() ?? 0.0,
        matchIndex: (json['matchIndex'] as int?) ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class BookmarksProvider extends ChangeNotifier {
  static const String _keyPrefix = 'bookmarks_v1_';

  // Cache: hizbId -> list of bookmarks
  final Map<String, List<Bookmark>> _cache = {};

  Future<List<Bookmark>> getBookmarks(String hizbId) async {
    if (_cache.containsKey(hizbId)) return _cache[hizbId]!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('$_keyPrefix$hizbId') ?? [];
    final list = raw
        .map((s) => Bookmark.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    _cache[hizbId] = list;
    return list;
  }

  Future<void> _save(String hizbId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _cache[hizbId] ?? [];
    await prefs.setStringList(
      '$_keyPrefix$hizbId',
      list.map((b) => jsonEncode(b.toJson())).toList(),
    );
  }

  Future<void> addBookmark(String hizbId, String text, {double scrollFraction = 0.0, int matchIndex = 0}) async {
    final bookmarks = await getBookmarks(hizbId);
    if (bookmarks.any((b) => b.text == text && b.matchIndex == matchIndex)) return;
    bookmarks.insert(0, Bookmark(text: text, scrollFraction: scrollFraction, matchIndex: matchIndex));
    notifyListeners();
    _save(hizbId);
  }

  Future<void> removeBookmark(String hizbId, Bookmark bookmark) async {
    final bookmarks = await getBookmarks(hizbId);
    bookmarks.removeWhere((b) => b.text == bookmark.text && b.scrollFraction == bookmark.scrollFraction && b.createdAt == bookmark.createdAt);
    notifyListeners();
    _save(hizbId);
  }

  bool isBookmarked(String hizbId, String text) {
    final bookmarks = _cache[hizbId];
    if (bookmarks == null) return false;
    return bookmarks.any((b) => b.text == text);
  }

  /// Synchronous count — returns 0 if not yet loaded.
  /// Call [ensureLoaded] first for accurate results.
  int getCount(String hizbId) {
    return _cache[hizbId]?.length ?? 0;
  }

  List<String> getBookmarkTexts(String hizbId) {
    return _cache[hizbId]?.map((b) => b.text).toList() ?? [];
  }

  List<Bookmark> getBookmarksList(String hizbId) {
    return _cache[hizbId] ?? [];
  }

  /// Ensures bookmarks for [hizbId] are loaded from disk into cache.
  Future<void> ensureLoaded(String hizbId) async {
    if (!_cache.containsKey(hizbId)) {
      await getBookmarks(hizbId);
      notifyListeners();
    }
  }
}
