import 'package:ad_shop_pos/data/services/category_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ═══════════════════════════════════════════════════════════════
//  DESIGN SYSTEM — Codynest POS
//  Professional, clean POS aesthetic inspired by Shopify/Square.
//  8px grid system · Semantic color tokens · Tight typography
// ═══════════════════════════════════════════════════════════════

/// ── Spacing ──
/// 8px grid system. Every value is a multiple of 4.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 48;

  // Keep old names as aliases for backward compat
  // (xxl was 32, now xxxl is 32 — old code still works)
  static double get _legacyXxl => 32;

  /// Border radius scale
  static const double radiusXs = 6;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusFull = 9999;

  /// Space reserved above the true screen bottom for the floating pill nav
  /// bar (AppShell) — since it floats over content instead of docking and
  /// reserving its own layout space, every tab page's scrollable content
  /// and any docked bottom bars/FABs need this much clearance so they don't
  /// end up hidden underneath it.
  static const double navClearance = 110;
}

/// ── Colors ──
/// Semantic color tokens. Primary is deep indigo for trust/professionalism.
/// Accent is teal for secondary actions. All colors are WCAG AA compliant.
class AppColors {
  // ── Brand ── (Emerald + Gold — single accent family, per brand palette)
  static const Color seed = Color(0xFF10B981); // Emerald 500 — primary
  static const Color seedLight = Color(0xFFA7F3D0); // Emerald 200
  static const Color seedDark = Color(0xFF064E3B); // Emerald 900
  static const Color accent = Color(0xFF064E3B); // Emerald 900 — secondary tone
  static const Color accentLight = Color(0xFFA7F3D0); // Emerald 200

  // ── Semantic ──
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successLight = Color(0xFFECFDF5); // Emerald 50
  static const Color warning = Color(0xFFFBBF24); // Gold/Amber 400
  static const Color warningLight = Color(0xFFFEF3C7); // Amber 100
  static const Color danger = Color(0xFFDC2626); // Red 600
  static const Color dangerLight = Color(0xFFFEE2E2); // Red 100
  static const Color info = Color(0xFF2563EB); // Blue 600
  static const Color infoLight = Color(0xFFDBEAFE); // Blue 100

  // ── Extended (data-viz only) ──
  // For KPI grids/charts that need more than one hue to stay scannable —
  // never used for chrome (buttons, nav, primary actions). Keep this list
  // short; the brand identity is still emerald + gold everywhere else.
  static const Color violet = Color(0xFF8B5CF6);
  static const Color rose = Color(0xFFEC4899);

  // ── Surfaces ──
  static const Color surfaceLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceDark = Color(0xFF0F172A); // Slate 900
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E293B); // Slate 800

  // ── Text ──
  static const Color textPrimary = Color(0xFF1E293B); // Slate 800
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Borders & Dividers ──
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color borderDark = Color(0xFF334155); // Slate 700

  // ── Category colors ──
  static const Map<String, Color> category = {
    'Watches': Color(0xFF6366F1),
    'Caps': Color(0xFF0EA5E9),
    'Perfumes': Color(0xFFEC4899),
    'Glasses': Color(0xFF14B8A6),
  };

  static Color forCategory(String category) {
    try {
      final catController = Get.find<CategoryController>();
      return catController.colorFor(category);
    } catch (_) {}
    return AppColors.category[category] ?? AppColors.seed;
  }
}

/// ── Elevation ──
class AppElevation {
  static const double none = 0;
  static const double sm = 1;
  static const double md = 2;
  static const double lg = 4;
  static const double xl = 8;

  /// Professional shadow: subtle, no color tint
  static List<BoxShadow> shadow([double elevation = 2]) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: elevation > 4 ? 0.12 : 0.06),
        blurRadius: elevation * 2,
        offset: Offset(0, elevation * 0.5),
      ),
    ];
  }
}

/// ── Duration ──
class AppDuration {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration page = Duration(milliseconds: 350);
}

/// ── Theme ──
class AppTheme {
  static ThemeData lightTheme = _build(Brightness.light);
  static ThemeData darkTheme = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // ── Color Scheme ──
    final colorScheme = isDark
        ? ColorScheme.fromSeed(
            seedColor: AppColors.seed,
            brightness: Brightness.dark,
            surface: AppColors.surfaceDark,
            onSurface: const Color(0xFFE2E8F0),
          )
        : ColorScheme.fromSeed(
            seedColor: AppColors.seed,
            brightness: Brightness.light,
            surface: AppColors.surfaceLight,
            onSurface: AppColors.textPrimary,
          );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark
          ? AppColors.surfaceDark
          : AppColors.surfaceLight,
    );

    return base.copyWith(
      // ── App Bar ──
      appBarTheme: AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0.5,
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        foregroundColor: isDark ? colorScheme.onSurface : AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: isDark ? colorScheme.onSurface : AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
      ),

      // ── Typography ──
      textTheme: base.textTheme.copyWith(
        displayLarge: base.textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
          height: 1.1,
        ),
        displayMedium: base.textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          height: 1.15,
        ),
        displaySmall: base.textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          height: 1.25,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          height: 1.25,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          height: 1.3,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
          height: 1.3,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
        titleSmall: base.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.35,
        ),
        labelMedium: base.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          height: 1.35,
        ),
        labelSmall: base.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
          height: 1.35,
        ),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(
            color: isDark
                ? AppColors.borderDark.withValues(alpha: 0.5)
                : AppColors.borderLight,
          ),
        ),
      ),

      // ── Inputs ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
        hintStyle: TextStyle(
          color: isDark ? AppColors.textTertiary : AppColors.textTertiary,
        ),
      ),

      // ── Buttons ──
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 48),
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // ── FAB ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),

      // ── Chips ──
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
        showCheckmark: false,
      ),

      // ── Dialogs ──
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),

      // ── ListTile ──
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),

      // ── Dividers ──
      dividerTheme: DividerThemeData(
        color: isDark
            ? AppColors.borderDark.withValues(alpha: 0.5)
            : AppColors.borderLight,
        space: 1,
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),

      // ── Bottom Sheet ──
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      ),
    );
  }
}
