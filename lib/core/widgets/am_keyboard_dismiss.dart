import 'package:flutter/material.dart';

/// Envuelve una pantalla con formulario para que un tap en cualquier zona
/// vacía (fuera de un campo de texto) cierre el teclado — los taps sobre
/// botones/filas internas siguen funcionando normal, solo se agrega el
/// unfocus además de su propio onTap.
class AmKeyboardDismiss extends StatelessWidget {
  const AmKeyboardDismiss({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: child,
    );
  }
}
