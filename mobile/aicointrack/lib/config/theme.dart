import 'package:flutter/material.dart';

class AppColors {
  // Common colors - updated from MVP design
  static const Color accent = Color(0xFF0052FF); // Base blue — primary CTA
  static const Color accentDim = Color(0xFF0040CC); // Base blue dim
  static const Color accentBg = Color(0x140052FF); // Base blue 8% opacity bg

  static const Color positive = Color(0xFF059669); // light mode income green
  static const Color positiveDark = Color(0xFF10B981); // dark mode income green
  static const Color purple = Color(0xFF4F46E5); // MVP indigo
  static const Color warning = Color(0xFFD97706); // MVP amber
  static const Color danger = Color(0xFFDC2626); // MVP red

  // Dark Theme
  static const Color darkBg = Color(0xFF0A0D12);
  static const Color darkSurface = Color(0xFF111620);
  static const Color darkCard = Color(0xFF161C28);
  static const Color darkBorder = Color(0xFF1E2A3A);
  static const Color darkText = Color(0xFFE8EDF5);
  static const Color darkMuted = Color(0xFF6B7A90);

  // Light Theme - Updated to match MVP "Mint Ledger Palette"
  static const Color lightBg = Color(0xFFFFFFFF); // MVP bg
  static const Color lightBg2 = Color(0xFFF4F7F5); // MVP bg2
  static const Color lightBg3 = Color(0xFFEBF5F0); // MVP bg3
  static const Color lightSurface = Color(0xFFF4F7F5); // MVP bg2
  static const Color lightCard = Color(0xFFFFFFFF); // MVP card
  static const Color lightBorder = Color(0xFFE0EDE7); // MVP border
  static const Color lightBorderMid = Color(0xFFC8DDD4); // MVP borderMid
  static const Color lightText = Color(0xFF0F1F17); // MVP text
  static const Color lightMid = Color(0xFF4A6358); // MVP mid
  static const Color lightMuted = Color(0xFF8FA89C); // MVP muted

  // MVP accent backgrounds
  static const Color greenBg = Color(0xFFE8F9F2);
  static const Color indigoBg = Color(0xFFEEF2FF);
  static const Color amberBg = Color(0xFFFFF4E6);
  static const Color redBg = Color(0xFFFEF0F0);

  // Light Theme Card Colors for better contrast
  static const Color lightCardBlue = Color(0xFFE0F2FE); // Light blue
  static const Color lightCardGold = Color(0xFFFEF3C7); // Light gold
  static const Color lightCardGreen = Color(0xFFDCFCE7); // Light green
  static const Color lightCardPurple = Color(0xFFE9D5FF); // Light purple
  static const Color lightCardBlack = Color(0xFFF3F4F6); // Light gray/black
  static const Color lightCardWhite = Color(0xFFFFFFFF); // Pure white

  // Light Theme Card Text Colors
  static const Color cardBlueText = Color(0xFF0369A1); // Dark blue
  static const Color cardGoldText = Color(0xFF92400E); // Dark gold
  static const Color cardGreenText = Color(0xFF065F46); // Dark green
  static const Color cardPurpleText = Color(0xFF6B21A8); // Dark purple
  static const Color cardBlackText = Color(0xFF111827); // Almost black
}

class AppTheme {
  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.accent,
    scaffoldBackgroundColor: AppColors.darkBg,
    cardColor: AppColors.darkCard,
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.purple,
      surface: AppColors.darkSurface,
      error: AppColors.danger,
      background: AppColors.darkBg,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkText,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      iconTheme: IconThemeData(color: AppColors.darkText),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: AppColors.darkText,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.02,
      ),
      displayMedium: TextStyle(
        color: AppColors.darkText,
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: TextStyle(
        color: AppColors.darkText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        color: AppColors.darkText,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: AppColors.darkText,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: AppColors.darkText,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: AppColors.darkMuted,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: AppColors.darkMuted,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.accent, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
  );

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.accent,
    scaffoldBackgroundColor: AppColors.lightBg,
    cardColor: AppColors.lightCard,
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: AppColors.accent,
      secondary: AppColors.purple,
      surface: AppColors.lightSurface,
      error: AppColors.danger,
      background: AppColors.lightBg,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightCard,
      foregroundColor: AppColors.lightText,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      iconTheme: IconThemeData(color: AppColors.lightText),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: AppColors.lightText,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.02,
      ),
      displayMedium: TextStyle(
        color: AppColors.lightText,
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: TextStyle(
        color: AppColors.lightText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        color: AppColors.lightText,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: AppColors.lightText,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: AppColors.lightText,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: AppColors.lightMuted,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: AppColors.lightMuted,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightBg2,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.accent, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
  );
}
