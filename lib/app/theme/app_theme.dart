import 'package:ad_shop_pos/data/services/category_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Centralized design tokens for consistent spacing & radii across the app.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
}

/// Brand palette used to seed the Material 3 color scheme.
class AppColors {
  static const Color seed = Color(0xFF4F46E5); // Indigo 600
  static const Color accent = Color(0xFF06B6D4); // Cyan 500
  static const Color success = Color(0xFF16A34A); // Green 600
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color danger = Color(0xFFDC2626); // Red 600

  /// Default colors keyed by category for visual grouping.
  /// Used as fallback when CategoryController is not available.
  static const Map<String, Color> category = {
    'Watches': Color(0xFF6366F1),
    'Caps': Color(0xFF0EA5E9),
    'Perfumes': Color(0xFFEC4899),
    'Glasses': Color(0xFF14B8A6),
  };

  static Color forCategory(String category) {
    // Try dynamic categories first (from CategoryController)
    try {
      final catController = Get.find<CategoryController>();
      return catController.colorFor(category);
    } catch (_) {}
    // Fallback to static map
    return AppColors.category[category] ?? AppColors.seed;
  }
}

class AppTheme {
  static ThemeData lightTheme = _build(Brightness.light);
  static ThemeData darkTheme = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );

    final isDark = brightness == Brightness.dark;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0F1115)
          : const Color(0xFFF6F7FB),
    );

    return base.copyWith(
      // ---------- App bar ----------
      appBarTheme: AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 2,
        elevation: 0,
        backgroundColor: base.scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),

      // ---------- Text ----------
      textTheme: base.textTheme.copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),

      // ---------- Cards ----------
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? const Color(0xFF181B22) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.6),
          ),
        ),
      ),

      // ---------- Inputs ----------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF181B22) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
      ),

      // ---------- Buttons ----------
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // ---------- FAB ----------
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),

      // ---------- Chips ----------
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
        showCheckmark: false,
      ),

      // ---------- Dialogs ----------
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),

      // ---------- ListTile ----------
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}
