import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta clara
  static const Color background    = Color(0xFFF5EDE3);
  static const Color primary       = Color(0xFFC1622A);
  static const Color cardNormal    = Color(0xFFFAF0E6);
  static const Color cardBorder    = Color(0xFFE8D5C4);
  static const Color textPrimary   = Color(0xFF2D1B0E);
  static const Color textSecondary = Color(0xFF7A5C44);
  static const Color white         = Colors.white;

  // Paleta escura
  static const Color backgroundDark    = Color(0xFF1A110A);
  static const Color cardDark          = Color(0xFF2A1A0F);
  static const Color cardBorderDark    = Color(0xFF3D2515);
  static const Color textPrimaryDark   = Color(0xFFF0E0D0);
  static const Color textSecondaryDark = Color(0xFFB08878);

  static ThemeData get light {
    final base = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary:          primary,
        onPrimary:        white,
        surface:          background,
        onSurface:        textPrimary,
        secondaryContainer: cardNormal,
      ),
      scaffoldBackgroundColor: background,
      textTheme: base.copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
        headlineLarge: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
        titleLarge: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15, color: textPrimary),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, color: textSecondary),
        labelMedium: GoogleFonts.inter(
          fontSize: 12, color: textSecondary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardNormal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: white,
        shape: CircleBorder(),
      ),
      dividerTheme: DividerThemeData(
        color: cardBorder,
        thickness: 1,
      ),
    );
  }

  static ThemeData get dark {
    final base = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary:            primary,
        onPrimary:          white,
        surface:            backgroundDark,
        onSurface:          textPrimaryDark,
        secondaryContainer: cardDark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      textTheme: base.copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32, fontWeight: FontWeight.bold, color: textPrimaryDark),
        headlineLarge: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.bold, color: textPrimaryDark),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.bold, color: textPrimaryDark),
        titleLarge: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600, color: textPrimaryDark),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: textPrimaryDark),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15, color: textPrimaryDark),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, color: textSecondaryDark),
        labelMedium: GoogleFonts.inter(
          fontSize: 12, color: textSecondaryDark),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardBorderDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimaryDark),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.bold, color: textPrimaryDark),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardDark,
        selectedItemColor: primary,
        unselectedItemColor: textSecondaryDark,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: white,
        shape: const CircleBorder(),
      ),
      dividerTheme: DividerThemeData(
        color: cardBorderDark,
        thickness: 1,
      ),
    );
  }
}
