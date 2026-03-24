import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: AppColors.primaryGreen,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        brightness: brightness,
      ),
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        iconTheme: IconThemeData(
          color:
              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      textTheme: _buildTextTheme(isDark),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.emeraldGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _buildTextTheme(bool isDark) {
    final color =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return TextTheme(
      displayLarge: TextStyle(fontFamily: 'Amiri', color: color),
      displayMedium: TextStyle(fontFamily: 'Amiri', color: color),
      displaySmall: TextStyle(fontFamily: 'Amiri', color: color),
      headlineLarge: TextStyle(fontFamily: 'Amiri', color: color),
      headlineMedium: TextStyle(fontFamily: 'Amiri', color: color),
      headlineSmall: TextStyle(fontFamily: 'Amiri', color: color),
      titleLarge: TextStyle(fontFamily: 'Amiri', color: color),
      titleMedium: TextStyle(fontFamily: 'Amiri', color: color),
      titleSmall: TextStyle(fontFamily: 'Amiri', color: color),
      bodyLarge: TextStyle(fontFamily: 'NotoNaskhArabic', color: color),
      bodyMedium: TextStyle(fontFamily: 'NotoNaskhArabic', color: color),
      bodySmall: TextStyle(fontFamily: 'NotoNaskhArabic', color: color),
      labelLarge: TextStyle(fontFamily: 'NotoNaskhArabic', color: color),
      labelMedium: TextStyle(fontFamily: 'NotoNaskhArabic', color: color),
      labelSmall: TextStyle(fontFamily: 'NotoNaskhArabic', color: color),
    );
  }
}
