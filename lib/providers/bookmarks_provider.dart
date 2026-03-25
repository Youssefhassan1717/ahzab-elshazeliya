import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Bookmark {
  final String text;
  final DateTime createdAt;

  Bookmark({required this.text, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        text: json['text'] as String,
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

  Future<void> addBookmark(String hizbId, String text) async {
    final bookmarks = await getBookmarks(hizbId);
    // Don't add duplicate
    if (bookmarks.any((b) => b.text == text)) return;
    bookmarks.insert(0, Bookmark(text: text));
    notifyListeners();
    _save(hizbId);
  }

  Future<void> removeBookmark(String hizbId, String text) async {
    final bookmarks = await getBookmarks(hizbId);
    bookmarks.removeWhere((b) => b.text == text);
    notifyListeners();
    _save(hizbId);
  }

  bool isBookmarked(String hizbId, String text) {
    final bookmarks = _cache[hizbId];
    if (bookmarks == null) return false;
    return bookmarks.any((b) => b.text == text);
  }

  int getCount(String hizbId) {
    return _cache[hizbId]?.length ?? 0;
  }

  List<String> getBookmarkTexts(String hizbId) {
    return _cache[hizbId]?.map((b) => b.text).toList() ?? [];
  }
}
