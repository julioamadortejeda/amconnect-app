import 'package:flutter/material.dart';

abstract final class AmAnims {
  /// Duración global de las transiciones entre pantallas (300ms)
  static const transitionDuration = Duration(milliseconds: 100);

  /// Desplazamiento horizontal en píxeles para transiciones push/pop (34px)
  static const transitionOffset = 34.0;

  /// Curva para transiciones push/pop (easeOutCubic)
  static const transitionCurve = Curves.easeOutCubic;

  /// Curva para transiciones fade/crossfade (ease)
  static const fadeCurve = Curves.ease;

  /// Duración de la animación de entrada de los elementos (stagger) (350ms)
  static const staggerDuration = Duration(milliseconds: 350);

  /// Retraso entre elementos consecutivos en cascada (staggerDelay) (40ms)
  static const staggerDelay = Duration(milliseconds: 40);
}
