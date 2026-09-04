import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Las dos mitades de una pantalla principal: Portafolio (Clientes / Pólizas) y
/// Agenda (Recordatorios / Compromisos).
///
/// Vivía escrito a mano dentro de `clients_screen.dart`. Al necesitarlo también
/// en Agenda se extrajo tal cual —mismos tamaños, mismos pesos— en vez de
/// resolverlo con [AmSegmented]: ese otro está construido sobre `TabBar`, se ve
/// distinto, y usarlo aquí habría dejado la app con dos selectores diferentes
/// para el mismo gesto.
///
/// [AmSegmented] se queda para lo que ya lo usa (las pestañas dentro de la ficha
/// de un cliente). Este es el de nivel de pantalla.
class AmSlidingTabs extends StatelessWidget {
  const AmSlidingTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  // Medidas del control, antes repetidas en cada pestaña de Portafolio.
  static const _labelSize = 13.0;
  static const _padH = 14.0;
  static const _padV = 5.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<int>(
        groupValue: selected,
        children: {
          for (int i = 0; i < labels.length; i++)
            i: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: _padH, vertical: _padV),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: _labelSize,
                  fontWeight: FontWeight.w600,
                  color: i == selected ? cs.onSurface : cs.tertiary,
                ),
              ),
            ),
        },
        onValueChanged: (val) {
          if (val != null) onSelect(val);
        },
      ),
    );
  }
}
