import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Material 3 theming for ForgeFit. Dark-mode-first, with a matching light
/// theme. Typography uses Inter via google_fonts with tabular figures for
/// clean number alignment in logs and charts.
class AppTheme {
  AppTheme._();

  static const double radius = 18;

  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      error: AppColors.danger,
    );

    final base = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
    final background = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: isDark ? Colors.white : const Color(0xFF11131A),
        displayColor: isDark ? Colors.white : const Color(0xFF11131A),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF11131A),
        ),
      ),
      cardTheme: CardTheme(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: isDark ? Colors.white : const Color(0xFF11131A),
          side: BorderSide(
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        indicatorColor: AppColors.primary.withOpacity(0.18),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        height: 68,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white10 : Colors.black12,
        space: 1,
      ),
    );
  }
}
