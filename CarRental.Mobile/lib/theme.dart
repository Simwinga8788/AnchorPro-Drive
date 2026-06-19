// ─── AnchorPro Drive Design Tokens ─────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand
  static const blue       = Color(0xFF1A56DB);
  static const blue2      = Color(0xFF0A3FBF);
  static const blueLight  = Color(0xFF3B82F6);
  static const cyan       = Color(0xFF06B6D4);

  // Backgrounds
  static const bg         = Color(0xFFFFFFFF);
  static const bg2        = Color(0xFFF5F7FA);
  static const bg3        = Color(0xFFEEF2F7);
  static const bgDark     = Color(0xFF0A0F1E);
  static const bgDark2    = Color(0xFF111827);
  static const navy       = Color(0xFF1E293B);

  // Text
  static const text1      = Color(0xFF0A0F1E);
  static const text2      = Color(0xFF4A5568);
  static const text3      = Color(0xFF8896A8);

  // Status
  static const green      = Color(0xFF10B981);
  static const red        = Color(0xFFEF4444);
  static const amber      = Color(0xFFF59E0B);
  static const gold       = Color(0xFFFBBF24);

  // Borders
  static const border     = Color(0xFFE2E8F0);
  static const border2    = Color(0xFFCBD5E1);

  // Gradient
  static const gradientColors = [blue, cyan];
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: gradientColors,
  );
  static const gradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgDark, navy],
  );
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: AppColors.blue,
      secondary: AppColors.cyan,
      surface: AppColors.bg,
      error: AppColors.red,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.text1,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text1,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.text1,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text1,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.text2,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.text2,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.text3,
      ),
      labelLarge: GoogleFonts.spaceGrotesk(
        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text1,
      ),
    ),
    scaffoldBackgroundColor: AppColors.bg2,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text1,
      ),
      iconTheme: const IconThemeData(color: AppColors.text1),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.blue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.text3),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.bg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bg,
      selectedItemColor: AppColors.blue,
      unselectedItemColor: AppColors.text3,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
