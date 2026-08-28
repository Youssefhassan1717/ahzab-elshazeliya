import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/bookmarks_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/intro/intro_screen.dart';

class AhzabApp extends StatelessWidget {
  const AhzabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => BookmarksProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'أحزاب الإمام الشاذلي',
            themeMode: themeProvider.themeMode,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeAnimationDuration: const Duration(milliseconds: 250),
            themeAnimationCurve: Curves.easeOutCubic,
            home: const IntroScreen(),
          );
        },
      ),
    );
  }
}
