import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static const List<String> fontFallback = [
    'PingFang SC',
    'Microsoft YaHei',
    'Noto Sans SC',
    'sans-serif',
  ];

  // ========== 浅色主题 ==========
  static ThemeData get lightTheme {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: const Color(0xFFF5F7FA),
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      fontFamily: GoogleFonts.notoSansSc().fontFamily,
      fontFamilyFallback: fontFallback,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: cs.surfaceContainerLow,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest,
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
      textTheme: _buildTextTheme(base.textTheme, cs.onSurface, cs.onSurfaceVariant),
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  // ========== 深色主题 ==========
  static ThemeData get darkTheme {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: const Color(0xFF121212),
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: GoogleFonts.notoSansSc().fontFamily,
      fontFamilyFallback: fontFallback,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: cs.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1E1E1E),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
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
      textTheme: _buildTextTheme(base.textTheme, cs.onSurface, cs.onSurfaceVariant),
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2A2A2A),
        selectedColor: cs.primaryContainer,
        labelStyle: TextStyle(color: cs.onSurface, fontSize: 13),
        secondaryLabelStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          return cs.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primaryContainer;
          return cs.surfaceContainerHighest;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          return null;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        selectedStyle: TextStyle(color: cs.onSurface),
        style: SegmentedButton.styleFrom(
          backgroundColor: const Color(0xFF2A2A2A),
          selectedBackgroundColor: cs.primaryContainer,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, Color primary, Color secondary) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(color: primary, fontWeight: FontWeight.w700),
      displayMedium: base.displayMedium?.copyWith(color: primary, fontWeight: FontWeight.w700),
      displaySmall: base.displaySmall?.copyWith(color: primary, fontWeight: FontWeight.w600),
      headlineLarge: base.headlineLarge?.copyWith(color: primary, fontWeight: FontWeight.w600),
      headlineMedium: base.headlineMedium?.copyWith(color: primary, fontWeight: FontWeight.w600),
      headlineSmall: base.headlineSmall?.copyWith(color: primary, fontWeight: FontWeight.w600),
      titleLarge: base.titleLarge?.copyWith(color: primary, fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(color: primary, fontWeight: FontWeight.w500),
      titleSmall: base.titleSmall?.copyWith(color: primary, fontWeight: FontWeight.w500),
      bodyLarge: base.bodyLarge?.copyWith(color: primary, fontWeight: FontWeight.w400, height: 1.5),
      bodyMedium: base.bodyMedium?.copyWith(color: primary, fontWeight: FontWeight.w400, height: 1.5),
      bodySmall: base.bodySmall?.copyWith(color: secondary, fontWeight: FontWeight.w400, height: 1.4),
      labelLarge: base.labelLarge?.copyWith(color: primary, fontWeight: FontWeight.w500),
      labelMedium: base.labelMedium?.copyWith(color: secondary, fontWeight: FontWeight.w500),
      labelSmall: base.labelSmall?.copyWith(color: secondary, fontWeight: FontWeight.w400),
    );
  }
}
