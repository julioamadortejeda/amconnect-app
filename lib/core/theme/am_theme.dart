import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ThemeExtension for colors that don't map to ColorScheme slots:
/// bg, card2, muted2, green/wash, amber/wash.
@immutable
class AmTheme extends ThemeExtension<AmTheme> {
  const AmTheme({
    required this.bg,
    required this.card2,
    required this.muted2,
    required this.green,
    required this.greenWash,
    required this.amber,
    required this.amberWash,
  });

  final Color bg;
  final Color card2;
  final Color muted2;
  final Color green;
  final Color greenWash;
  final Color amber;
  final Color amberWash;

  static const light = AmTheme(
    bg: AmColors.bgLight,
    card2: AmColors.card2Light,
    muted2: AmColors.muted2Light,
    green: AmColors.greenLight,
    greenWash: AmColors.greenWashLight,
    amber: AmColors.amberLight,
    amberWash: AmColors.amberWashLight,
  );

  static const dark = AmTheme(
    bg: AmColors.bgDark,
    card2: AmColors.card2Dark,
    muted2: AmColors.muted2Dark,
    green: AmColors.greenDark,
    greenWash: AmColors.greenWashDark,
    amber: AmColors.amberDark,
    amberWash: AmColors.amberWashDark,
  );

  @override
  AmTheme copyWith({
    Color? bg,
    Color? card2,
    Color? muted2,
    Color? green,
    Color? greenWash,
    Color? amber,
    Color? amberWash,
  }) {
    return AmTheme(
      bg: bg ?? this.bg,
      card2: card2 ?? this.card2,
      muted2: muted2 ?? this.muted2,
      green: green ?? this.green,
      greenWash: greenWash ?? this.greenWash,
      amber: amber ?? this.amber,
      amberWash: amberWash ?? this.amberWash,
    );
  }

  @override
  AmTheme lerp(AmTheme other, double t) {
    return AmTheme(
      bg: Color.lerp(bg, other.bg, t)!,
      card2: Color.lerp(card2, other.card2, t)!,
      muted2: Color.lerp(muted2, other.muted2, t)!,
      green: Color.lerp(green, other.green, t)!,
      greenWash: Color.lerp(greenWash, other.greenWash, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amberWash: Color.lerp(amberWash, other.amberWash, t)!,
    );
  }
}

extension AmThemeExt on BuildContext {
  AmTheme get am => Theme.of(this).extension<AmTheme>()!;
}
