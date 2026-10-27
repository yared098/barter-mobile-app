import 'package:flutter/material.dart';

/// Strict green + white palette.
/// All surfaces are white; all accents are shades of green.
/// No blues, no oranges, no purples. Body text is a very dark green.
class AppColors {
  AppColors._();

  // ─────────────────────────────────────────────
  // CORE BRAND
  // ─────────────────────────────────────────────
  static const Color primary = Color(0xFF00A86B);
  static const Color primaryDark = Color(0xFF007A4D);
  static const Color primaryLight = Color(0xFFE8F5EE);
  static const Color primaryMid = Color(0xFFB8E5CC);

  // ─────────────────────────────────────────────
  // NEUTRALS
  // ─────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF0B3D2E);
  static const Color textMuted = Color(0xFF5A7A6B);
  static const Color textSubtle = Color(0xFF9BB0A5);
  static const Color border = Color(0xFFD4E8DD);
  static const Color divider = Color(0xFFEBF3EF);

  // ─────────────────────────────────────────────
  // SEMANTIC
  // ─────────────────────────────────────────────
  static const Color success = primary;
  static const Color error = Color(0xFFB00020);
  static const Color warning = Color(0xFF8A9B4D);
  static const Color info = primaryMid;

  // ─────────────────────────────────────────────
  // SURFACES
  // ─────────────────────────────────────────────
  static const Color scaffold = white;
  static const Color card = white;
  static const Color surface = primaryLight;
  static const Color overlay = Color(0x66000000);

  // ─────────────────────────────────────────────
  // OPACITY HELPERS
  // ─────────────────────────────────────────────
  static Color get primaryShadow => primary.withValues(alpha: 0.15);
  static Color get primaryFaint => primary.withValues(alpha: 0.05);
  static Color get textDivider => text.withValues(alpha: 0.06);

  // ─────────────────────────────────────────────
  // GRADIENTS
  // ─────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, primaryDark],
  );

  static const LinearGradient primaryGradientHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryDark, primary],
  );
}

/// Global Material theme — wires AppColors into Material 3.
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.text,
      secondary: AppColors.primaryDark,
      onSecondary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.text,
      surfaceContainerHighest: AppColors.primaryLight,
      error: AppColors.error,
      onError: AppColors.white,
      outline: AppColors.border,
    ),

    scaffoldBackgroundColor: AppColors.white,

    // ─── AppBar ───
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: AppColors.text),
    ),

    // ─── Buttons ───
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
        disabledForegroundColor: AppColors.white.withValues(alpha: 0.8),
        minimumSize: const Size.fromHeight(54),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 2,
      shape: StadiumBorder(),
    ),

    // ─── Inputs ───
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: AppColors.textSubtle),
      labelStyle: const TextStyle(color: AppColors.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
    ),

    // ─── Cards ───
    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
    ),

    // ─── Chips ───
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryLight,
      selectedColor: AppColors.primary,
      labelStyle: const TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      secondaryLabelStyle: const TextStyle(
        color: AppColors.white,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),

    // ─── Divider ───
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),

    // ─── Progress ───
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.primaryLight,
    ),

    // ─── Text ───
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
      ),
      displayMedium: TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineLarge: TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
      titleMedium: TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      bodyLarge: TextStyle(color: AppColors.text, fontSize: 16),
      bodyMedium: TextStyle(color: AppColors.text, fontSize: 14),
      bodySmall: TextStyle(color: AppColors.textMuted, fontSize: 12),
      labelLarge: TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      labelSmall: TextStyle(color: AppColors.textMuted, fontSize: 11),
    ),

    // ─── Snackbar ───
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.text,
      contentTextStyle: const TextStyle(color: AppColors.white),
      actionTextColor: AppColors.primaryMid,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // ─── Dialog ───
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    // ─── Bottom Sheet ───
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    // ─── Splash / touch feedback ───
    splashColor: AppColors.primary.withValues(alpha: 0.08),
    highlightColor: AppColors.primary.withValues(alpha: 0.04),
  );
}
