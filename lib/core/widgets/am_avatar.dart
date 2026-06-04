import 'package:flutter/material.dart';
import 'package:amconnect/core/mock/mock_data.dart';

class AmAvatar extends StatelessWidget {
  const AmAvatar({super.key, required this.client, this.size = 44, this.radius = 14});

  final MockClient client;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = client.color;
    final bg = Color.alphaBlend(color.withValues(alpha: 0.16), Colors.white);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(
        client.inicial,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.02,
        ),
      ),
    );
  }
}
