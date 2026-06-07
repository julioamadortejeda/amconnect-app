import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/mock/mock_data.dart';
import 'package:amconnect/core/widgets/am_avatar.dart';
import 'package:amconnect/core/widgets/am_press.dart';

class HomeClientesRecientes extends StatelessWidget {
  const HomeClientesRecientes({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: mockClients.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final c = mockClients[i];
          return AmPress(
            onTap: () => context.push('/clientes/${c.id}'),
            child: Column(
              children: [
                AmAvatar(client: c, size: 48, radius: 16),
                const SizedBox(height: 5),
                Text(c.nombre.split(' ').first,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant)),
              ],
            ),
          );
        },
      ),
    );
  }
}
