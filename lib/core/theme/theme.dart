import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'am_theme.dart';
import 'app_colors.dart';

class AzulProTheme {
  static ThemeData get lightTheme {
    final base = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: base,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AmColors.accent,
        onPrimary: AmColors.onAccent,
        primaryContainer: AmColors.accentWash,
        onPrimaryContainer: AmColors.accentInk,
        secondary: AmColors.inkSoftLight,
        onSecondary: AmColors.onAccent,
        secondaryContainer: AmColors.cardSunkenLight,
        onSecondaryContainer: AmColors.inkLight,
        tertiary: AmColors.mutedLight,
        onTertiary: AmColors.onAccent,
        tertiaryContainer: AmColors.cardSunkenLight,
        onTertiaryContainer: AmColors.inkLight,
        error: AmColors.redLight,
        onError: AmColors.onAccent,
        errorContainer: AmColors.redWashLight,
        onErrorContainer: AmColors.redLight,
        surface: AmColors.cardLight,
        onSurface: AmColors.inkLight,
        onSurfaceVariant: AmColors.inkSoftLight,
        outline: AmColors.lineLight,
        outlineVariant: AmColors.lineSoftLight,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: AmColors.inkLight,
        onInverseSurface: AmColors.cardLight,
        inversePrimary: AmColors.accentWash,
      ),
      scaffoldBackgroundColor: AmColors.bgLight,
      cardColor: AmColors.cardLight,
      dividerColor: AmColors.lineLight,
      extensions: const [AmTheme.light],
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }

  static ThemeData get darkTheme {
    final base = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: base,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AmColors.accent,
        onPrimary: AmColors.onAccent,
        primaryContainer: AmColors.accentWashDark,
        onPrimaryContainer: AmColors.accentInkDark,
        secondary: AmColors.inkSoftDark,
        onSecondary: AmColors.bgDark,
        secondaryContainer: AmColors.cardSunkenDark,
        onSecondaryContainer: AmColors.inkDark,
        tertiary: AmColors.mutedDark,
        onTertiary: AmColors.bgDark,
        tertiaryContainer: AmColors.cardSunkenDark,
        onTertiaryContainer: AmColors.inkDark,
        error: AmColors.redDark,
        onError: AmColors.onAccent,
        errorContainer: AmColors.redWashDark,
        onErrorContainer: AmColors.redDark,
        surface: AmColors.cardDark,
        onSurface: AmColors.inkDark,
        onSurfaceVariant: AmColors.inkSoftDark,
        outline: AmColors.lineDark,
        outlineVariant: AmColors.lineSoftDark,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: AmColors.inkDark,
        onInverseSurface: AmColors.cardDark,
        inversePrimary: AmColors.accentWashDark,
      ),
      scaffoldBackgroundColor: AmColors.bgDark,
      cardColor: AmColors.cardDark,
      dividerColor: AmColors.lineDark,
      extensions: const [AmTheme.dark],
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
