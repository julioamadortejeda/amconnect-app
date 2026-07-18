import 'package:flutter/material.dart';

/// [AnimatedSwitcher] con el layout por defecto arreglado a la izquierda.
/// El `Stack` que arma `AnimatedSwitcher.defaultLayoutBuilder` centra sus
/// hijos (`Alignment.center`) — dentro de un `Expanded`/`Row` eso deja el
/// texto flotando en medio del espacio disponible en vez de pegado a lo que
/// esté a su izquierda (el espacio raro que se veía en el subtítulo del
/// header y en la barra de voz).
class AmFadeSwitcher extends StatelessWidget {
  const AmFadeSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      layoutBuilder: (currentChild, previousChildren) {
        final seenKeys = <Key>{};
        if (currentChild?.key != null) seenKeys.add(currentChild!.key!);
        final safePrevious = <Widget>[];
        for (final child in previousChildren) {
          final key = child.key;
          if (key == null || !seenKeys.contains(key)) {
            if (key != null) seenKeys.add(key);
            safePrevious.add(child);
          }
        }
        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            ...safePrevious,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: child,
    );
  }
}
