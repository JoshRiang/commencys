import 'package:flutter/material.dart';

/// Commencys Apple-style design tokens.
/// iOS-grouped background, white glass cards, one red accent + status colors.
class AppColors {
  static const background = Color(0xFFF2F2F7);
  static const card = Colors.white;
  static const ink = Color(0xFF1C1C1E);
  static const secondary = Color(0xFF6B7280);
  static const tertiary = Color(0xFF9CA3AF);

  static const accent = Color(0xFFE5484D);
  static const accentDeep = Color(0xFFC81E1E);
  static const accentSoft = Color(0xFFFDECEC);

  static const success = Color(0xFF16A34A);
  static const successSoft = Color(0xFFE7F6EC);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFEF3C7);
  static const info = Color(0xFF2563EB);
  static const infoSoft = Color(0xFFE8EFFD);

  static const sosStart = Color(0xFFFF5A5A);
  static const sosEnd = Color(0xFFD61F2C);

  static Color severityFor(String name) {
    switch (name) {
      case 'critical':
        return accent;
      case 'high':
        return const Color(0xFFF97316);
      case 'medium':
        return const Color(0xFFCA8A04);
      case 'low':
      default:
        return success;
    }
  }

  static Color severitySoftFor(String name) {
    switch (name) {
      case 'critical':
        return accentSoft;
      case 'high':
        return const Color(0xFFFFEDD5);
      case 'medium':
        return const Color(0xFFFEF9C3);
      case 'low':
      default:
        return successSoft;
    }
  }
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: null, // system SF/Roboto
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
        ),
        labelStyle: const TextStyle(color: AppColors.secondary, fontSize: 13),
        hintStyle: const TextStyle(color: AppColors.tertiary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999)),
        labelStyle:
            const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 15, height: 1.45),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45),
        labelSmall: TextStyle(
            fontSize: 12, color: AppColors.secondary,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}
