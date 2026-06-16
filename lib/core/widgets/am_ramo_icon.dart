import 'package:flutter/material.dart';

class AmRamoIcon extends StatelessWidget {
  const AmRamoIcon({super.key, required this.ramo, this.size = 42});

  final String ramo;
  final double size;

  @override
  Widget build(BuildContext context) {
    final r = ramo.toLowerCase();
    final (color, icon) = switch (r) {
      _ when r.contains('médico') || r.contains('medical') || r.contains('salud') || r.contains('health') || r.contains('gmm') =>
          (const Color(0xFFD8453F), Icons.favorite_outline),
      _ when r.contains('vida') || r.contains('life') =>
          (const Color(0xFF007AC0), Icons.shield_outlined),
      _ when r.contains('auto') || r.contains('carro') || r.contains('car') || r.contains('vehicle') =>
          (const Color(0xFF0E7C42), Icons.directions_car_outlined),
      _ when r.contains('hogar') || r.contains('home') || r.contains('casa') =>
          (const Color(0xFFF5A623), Icons.home_outlined),
      _ => (const Color(0xFFB9791A), Icons.shield_outlined),
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
