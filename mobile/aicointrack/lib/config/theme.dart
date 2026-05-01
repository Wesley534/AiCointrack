import 'package:flutter/material.dart';

class AppColors {
  // Shared palette from the provided design files.
  static const Color accent = Color(0xFF0052FF);
  static const Color accentDim = Color(0xFF003EC7);
  static const Color accentBg = Color(0x140052FF);
  static const Color positive = Color(0xFF006C49);
  static const Color positiveDark = Color(0xFF44DFA3);
  static const Color purple = Color(0xFF57677E);
  static const Color warning = Color(0xFFE7A23B);
  static const Color danger = Color(0xFFBA1A1A);

  // Light tokens.
  static const Color lightBg = Color(0xFFFAF8FF);
  static const Color lightBg2 = Color(0xFFF2F3FF);
  static const Color lightBg3 = Color(0xFFEAEDFF);
  static const Color lightSurface = Color(0xFFFAF8FF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFC3C5D9);
  static const Color lightBorderMid = Color(0xFFDAE2FD);
  static const Color lightText = Color(0xFF131B2E);
  static const Color lightMid = Color(0xFF434656);
  static const Color lightMuted = Color(0xFF737688);
  static const Color greenBg = Color(0xFF6CF8BB);
  static const Color indigoBg = Color(0xFFDDE1FF);
  static const Color amberBg = Color(0xFFD3E4FE);
  static const Color redBg = Color(0xFFFFDAD6);

  // Preserved aliases used elsewhere in the app.
  static const Color lightCardBlue = Color(0xFFDDE1FF);
  static const Color lightCardGold = Color(0xFFFFF0D6);
  static const Color lightCardGreen = Color(0xFFD9FCEB);
  static const Color lightCardPurple = Color(0xFFD3E4FE);
  static const Color lightCardBlack = Color(0xFFF2F3FF);
  static const Color lightCardWhite = Color(0xFFFFFFFF);
  static const Color cardBlueText = Color(0xFF003EC7);
  static const Color cardGoldText = Color(0xFF8B5E00);
  static const Color cardGreenText = Color(0xFF006C49);
  static const Color cardPurpleText = Color(0xFF3F4F65);
  static const Color cardBlackText = Color(0xFF131B2E);

  // Dark tokens from the dark design.
  static const Color darkBg = Color(0xFF0B1326);
  static const Color darkSurface = Color(0xFF131B2E);
  static const Color darkCard = Color(0xFF171F33);
  static const Color darkBorder = Color(0xFF434656);
  static const Color darkText = Color(0xFFDAE2FD);
  static const Color darkMuted = Color(0xFF8D90A2);
  static const Color darkTint = Color(0xFFB7C4FF);
  static const Color darkSecondary = Color(0xFF44DFA3);
}

class AppTheme {
  static ThemeData lightTheme = _buildTheme(brightness: Brightness.light);
  static ThemeData darkTheme = _buildTheme(brightness: Brightness.dark);

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.accent,
      onPrimary: Colors.white,
      secondary: isDark ? AppColors.darkSecondary : AppColors.positive,
      onSecondary: isDark ? AppColors.darkBg : Colors.white,
      error: isDark ? const Color(0xFFFFB4AB) : AppColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
      primaryContainer: AppColors.accent,
      onPrimaryContainer: Colors.white,
      secondaryContainer: isDark ? const Color(0xFF00C087) : AppColors.greenBg,
      onSecondaryContainer: isDark ? const Color(0xFF00472F) : AppColors.positive,
      tertiary: AppColors.purple,
      onTertiary: Colors.white,
      tertiaryContainer: isDark ? const Color(0xFFCC0048) : AppColors.amberBg,
      onTertiaryContainer: isDark ? const Color(0xFFFFDDDF) : AppColors.purple,
      outline: border,
      outlineVariant: isDark ? const Color(0xFF2D3449) : AppColors.lightBorderMid,
      surfaceContainerHighest: isDark ? const Color(0xFF2D3449) : AppColors.lightBg3,
      onSurfaceVariant: muted,
      scrim: Colors.black54,
      shadow: Colors.black26,
      inverseSurface: isDark ? AppColors.darkText : AppColors.darkSurface,
      onInverseSurface: isDark ? AppColors.darkSurface : AppColors.lightBg,
      inversePrimary: isDark ? AppColors.accent : AppColors.darkTint,
    );

    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      primaryColor: AppColors.accent,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      colorScheme: colorScheme,
      cardColor: card,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: card.withValues(alpha: isDark ? 0.82 : 0.72),
        foregroundColor: text,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        iconTheme: IconThemeData(color: text),
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: text,
          fontSize: 44,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
          height: 1.05,
        ),
        displayMedium: TextStyle(
          color: text,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          height: 1.1,
        ),
        headlineMedium: TextStyle(
          color: text,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          height: 1.2,
        ),
        headlineSmall: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: text,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: text,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: muted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          color: muted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
        labelLarge: TextStyle(
          color: text,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: border.withValues(alpha: 0.9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.45),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        selectedColor: AppColors.accent,
        secondarySelectedColor: AppColors.accent,
        disabledColor: border.withValues(alpha: 0.35),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        labelStyle: TextStyle(color: text, fontWeight: FontWeight.w600),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightText,
        contentTextStyle: TextStyle(color: isDark ? AppColors.darkText : Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: border.withValues(alpha: 0.75),
        space: 1,
        thickness: 1,
      ),
    );
  }
}

class AppDecorations {
  static BoxDecoration pageBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? AppColors.darkBg : AppColors.lightBg,
      gradient: RadialGradient(
        center: Alignment.topLeft,
        radius: 1.15,
        colors: isDark
            ? [
                AppColors.accent.withValues(alpha: 0.12),
                AppColors.darkBg,
                AppColors.darkBg,
              ]
            : [
                AppColors.accent.withValues(alpha: 0.08),
                AppColors.greenBg.withValues(alpha: 0.08),
                AppColors.lightBg,
              ],
      ),
    );
  }

  static BoxDecoration glassCard(BuildContext context, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: color ??
          (isDark
              ? AppColors.darkCard.withValues(alpha: 0.74)
              : Colors.white.withValues(alpha: 0.72)),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: scheme.outline.withValues(alpha: isDark ? 0.38 : 0.55),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }
}
