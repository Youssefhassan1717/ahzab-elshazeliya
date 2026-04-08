import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';

class FavoritesProvider extends ChangeNotifier {
  static const String _key = 'favorites_v3';
  static const int maxFavorites = 5;
  Set<String> _favorites = <String>{};

  Set<String> get favorites => _favorites;

  FavoritesProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    _favorites = list.toSet();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _favorites.toList());
  }

  bool isFavorite(String id) => _favorites.contains(id);

  void toggleFavorite(String id, BuildContext context) {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
      notifyListeners();
      _save();
    } else {
      if (_favorites.length >= maxFavorites) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'الحد الأقصى للأحزاب المميزة هو ٥. قم بإزالة واحد لإضافة آخر.',
              style: TextStyle(fontFamily: 'ScheherazadeNew'),
            ),
            backgroundColor: AppColors.emeraldGreen,
          ),
        );
        return;
      }
      _favorites.add(id);
      notifyListeners();
      _save();
    }
  }
}
