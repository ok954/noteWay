import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  /// 全局字体回退栈：Noto Sans SC → 苹方 → 微软雅黑 → 系统无衬线
  static const List<String> fontFallback = [
    'PingFang SC',
    'Microsoft YaHei',
    'Noto Sans SC',
    'sans-serif',
  ];

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      fontFamily: GoogleFonts.notoSansSc().fontFamily,
      fontFamilyFallback: fontFallback,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFFF5F7FA),
        foregroundColor: Color(0xFF333333),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: _buildTextTheme(base.textTheme, const Color(0xFF333333)),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEEEEEE),
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: GoogleFonts.notoSansSc().fontFamily,
      fontFamilyFallback: fontFallback,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1E1E1E),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      textTheme: _buildTextTheme(base.textTheme, Colors.white),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF333333),
        thickness: 1,
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, Color color) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(color: color, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      displayMedium: base.displayMedium?.copyWith(color: color, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      displaySmall: base.displaySmall?.copyWith(color: color, fontWeight: FontWeight.w600),
      headlineLarge: base.headlineLarge?.copyWith(color: color, fontWeight: FontWeight.w600),
      headlineMedium: base.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
      headlineSmall: base.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
      titleLarge: base.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      titleMedium: base.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w500, letterSpacing: 0.15),
      titleSmall: base.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      bodyLarge: base.bodyLarge?.copyWith(color: color, fontWeight: FontWeight.w400, letterSpacing: 0.15, height: 1.5),
      bodyMedium: base.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w400, letterSpacing: 0.15, height: 1.5),
      bodySmall: base.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w400, letterSpacing: 0.1, height: 1.4),
      labelLarge: base.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      labelMedium: base.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      labelSmall: base.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w500, letterSpacing: 0.1),
    );
  }
}
