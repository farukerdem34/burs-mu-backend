import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF094CB2);
  static const Color tertiaryGold = Color(0xFF6D5E00);
  static const Color surfaceContainerLowest = Color(0xFFF8F9FC);
  static const Color surfaceDim = Color(0xFFE8EAF0);

  static const double smRadius = 8;
  static const double mdRadius = 12;
  static const double lgRadius = 16;

  static LinearGradient primaryGradient = const LinearGradient(
    colors: [primaryBlue, Color(0xFF3068CC)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static TextStyle _notoSerif({
    double? size,
    FontWeight? weight,
    double? height,
    Color? color,
  }) {
    return GoogleFonts.notoSerif(
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
    );
  }

  static TextStyle _inter({
    double? size,
    FontWeight? weight,
    double? height,
    Color? color,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
    );
  }

  static TextStyle _publicSans({
    double? size,
    FontWeight? weight,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.publicSans(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: primaryBlue,
      tertiary: tertiaryGold,
      surface: surfaceContainerLowest,
      surfaceDim: surfaceDim,
      surfaceContainerLow: const Color(0xFFF0F2F7),
      surfaceContainer: const Color(0xFFEBEDF3),
      surfaceContainerHigh: const Color(0xFFE3E5EC),
      surfaceContainerHighest: const Color(0xFFDBDDE5),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onSurface: const Color(0xFF1A1C20),
      onSurfaceVariant: const Color(0xFF464950),
      outline: const Color(0xFF767985),
      outlineVariant: const Color(0xFFC4C6D0),
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: TextTheme(
        displayLarge: _notoSerif(size: 32, weight: FontWeight.w700, height: 1.2),
        displayMedium: _notoSerif(size: 28, weight: FontWeight.w700, height: 1.25),
        displaySmall: _notoSerif(size: 24, weight: FontWeight.w600, height: 1.3),
        headlineLarge: _notoSerif(size: 22, weight: FontWeight.w600, height: 1.3),
        headlineMedium: _notoSerif(size: 20, weight: FontWeight.w600, height: 1.35),
        headlineSmall: _notoSerif(size: 18, weight: FontWeight.w600, height: 1.4),
        titleLarge: _inter(size: 18, weight: FontWeight.w600, height: 1.4),
        titleMedium: _inter(size: 16, weight: FontWeight.w600, height: 1.45),
        titleSmall: _inter(size: 14, weight: FontWeight.w600, height: 1.5),
        bodyLarge: _inter(size: 16, weight: FontWeight.w400, height: 1.6),
        bodyMedium: _inter(size: 14, weight: FontWeight.w400, height: 1.6),
        bodySmall: _inter(size: 12, weight: FontWeight.w400, height: 1.5),
        labelLarge: _publicSans(size: 14, weight: FontWeight.w500, letterSpacing: 0.5),
        labelMedium: _publicSans(size: 12, weight: FontWeight.w500, letterSpacing: 0.5),
        labelSmall: _publicSans(size: 11, weight: FontWeight.w500, letterSpacing: 0.5),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: _inter(size: 18, weight: FontWeight.w600, color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(mdRadius),
        ),
        color: colorScheme.surfaceContainer,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(smRadius),
          borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(38)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(smRadius),
          borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(38)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(smRadius),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(smRadius),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(smRadius),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: _inter(size: 14, color: colorScheme.onSurfaceVariant),
        hintStyle: _inter(size: 14, color: colorScheme.outline),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(smRadius),
          ),
          textStyle: _inter(size: 16, weight: FontWeight.w600, color: Colors.white),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(smRadius),
          ),
          side: BorderSide(color: colorScheme.outlineVariant),
          textStyle: _inter(size: 16, weight: FontWeight.w500, color: primaryBlue),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: _inter(size: 14, weight: FontWeight.w500),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(smRadius),
            borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(38)),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withAlpha(25),
        thickness: 0.5,
      ),
      scaffoldBackgroundColor: colorScheme.surface,
    );
  }
}
