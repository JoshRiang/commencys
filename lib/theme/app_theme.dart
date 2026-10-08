import 'package:flutter/material.dart';

// Token visual bersama untuk layar konsumen Commencys.
// File ini hanya mengatur tampilan dan tidak memuat aturan laporan atau akses.
class AppColors {
  static const background = Color(0xFFF5F5F2);
  static const surface = Colors.white;
  static const ink = Color(0xFF202522);
  static const secondary = Color(0xFF606963);
  static const line = Color(0xFFE1E5E1);
  static const accent = Color(0xFFB42318);
  static const info = Color(0xFF315B7D);
  static const infoSoft = Color(0xFFE7EFF5);
}

class AppTheme {
  // Gunakan tema Material 3 ringkas agar semua layar berbagi warna dan bidang yang sama.
  // Perubahan tema tidak menambah tindakan, alur, atau status produk.
  static ThemeData light() {
    final colors = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.accent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.line),
        ),
      ),
    );
  }
}
