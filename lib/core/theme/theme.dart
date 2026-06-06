import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
