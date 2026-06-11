import 'package:flutter/material.dart';

class AmColors {
  static const accent = Color(0xFF007AC0);
  static const authBg = Color(0xFF1278C5);
  static const white = Colors.white;
  static const authError = Color(0xFFFFB3B3);

  // Light theme — Privé style (cool gray surfaces)
  static const bgLight = Color(0xFFF5F6F7);
  static const cardLight = Color(0xFFFFFFFF);
  static const card2Light = Color(0xFFFAFBFC);
  static const cardSunkenLight = Color(0xFFF2F3F5);
  static const inkLight = Color(0xFF181D1B);
  static const inkSoftLight = Color(0xFF4D544F);
  static const mutedLight = Color(0xFF8C9290);
  static const muted2Light = Color(0xFFBFC3C4);
  static const lineLight = Color(0xFFE5E6E8);
  static const lineSoftLight = Color(0xFFEEEFF1);
  static const greenLight = Color(0xFF0E7C42);
  static const greenWashLight = Color(0xFFEAF2EF);
  static const redLight = Color(0xFFD8453F);
  static const redWashLight = Color(0xFFF9EFEE);
  static const amberLight = Color(0xFFB9791A);
  static const amberWashLight = Color(0xFFF4EFE6);

  // Lines (dark)
  static const lineDark = Color(0xFF2A3038);
  static const lineSoftDark = Color(0xFF1E2730);

  // Accent (dark variants for containers)
  static const accentWashDark = Color(0xFF0D1F2D);
  static const accentInkDark = Color(0xFF4BAAD4);

  // Dark theme
  static const bgDark = Color(0xFF0C1116);
  static const cardDark = Color(0xFF161F29);
  static const card2Dark = Color(0xFF1B2731);
  static const cardSunkenDark = Color(0xFF11181F);
  static const inkDark = Color(0xFFEEF3F8);
  static const inkSoftDark = Color(0xFFB4C0CC);
  static const mutedDark = Color(0xFF7A8593);
  static const muted2Dark = Color(0xFF5C6775);
  static const greenDark = Color(0xFF34C77B);
  static const greenWashDark = Color(0xFF133228);
  static const redDark = Color(0xFFF2685F);
  static const redWashDark = Color(0xFF2A1010);
  static const amberDark = Color(0xFFE0A53C);
  static const amberWashDark = Color(0xFF241A06);

  // Auth screens — fixed (blue background, same in light and dark)
  static const authSubtitle = Color(0xD1FFFFFF); // white 82% opacity

  // Shared
  static const onAccent = Colors.white;
  // color-mix(in srgb, #007AC0 9%, #fff) → subtle accent wash
  static const accentWash = Color(0xFFE8F3F9);
  // color-mix(in srgb, #007AC0 15%, #fff)
  static const accentWash2 = Color(0xFFD9EBF6);
  // color-mix(in srgb, #007AC0 84%, #07140d)
  static const accentInk = Color(0xFF006AA3);

  // Source type colors
  static const srcDoc = Color(0xFFD8453F);
  static const srcWhatsApp = Color(0xFF0E7C42);
  static const srcWave = Color(0xFFB9791A);
  static const srcImage = Color(0xFF7A4FD0);
  static const srcNote = Color(0xFF007AC0);
}
