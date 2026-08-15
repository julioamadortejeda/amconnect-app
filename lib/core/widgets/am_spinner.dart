import 'package:flutter/material.dart';

/// Spinner pequeño e inline para botones, filas y chips donde [AmLoader]
/// (logo + texto centrado) no encaja. Tamaño, grosor y color parametrizables;
/// por defecto usa el color primario del tema.
class AmSpinner extends StatelessWidget {
  const AmSpinner({
    super.key,
    this.size = 20,
    this.strokeWidth = 2,
    this.color,
  });

  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
