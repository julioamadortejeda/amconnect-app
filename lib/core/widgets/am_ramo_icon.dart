import 'package:flutter/material.dart';

class AmRamoIcon extends StatelessWidget {
  const AmRamoIcon({super.key, required this.ramo, this.size = 42});

  final String ramo;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (ramo) {
      'Gastos Médicos' => (const Color(0xFFD8453F), Icons.local_hospital_outlined),
      'Vida'           => (const Color(0xFF007AC0), Icons.favorite_outline),
      'Auto'           => (const Color(0xFF0E7C42), Icons.directions_car_outlined),
      _                => (const Color(0xFFB9791A), Icons.shield_outlined),
    };

    final bg = Color.alphaBlend(color.withValues(alpha: 0.14), Colors.white);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}
