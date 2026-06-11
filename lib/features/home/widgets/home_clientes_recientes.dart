import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/widgets/am_avatar.dart';
import 'package:amconnect/core/widgets/am_press.dart';
import 'package:amconnect/features/clients/providers/clients_provider.dart';

class HomeClientesRecientes extends ConsumerWidget {
  const HomeClientesRecientes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final contacts = ref.watch(clientsProvider).asData?.value ?? [];

    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: contacts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final c = contacts[i];
          return AmPress(
            onTap: () => context.push('/clientes/${c.id}'),
            child: Column(
              children: [
                AmAvatar(inicial: c.inicial, color: c.color, size: 48, radius: 16),
                const SizedBox(height: 5),
                Text(c.fullName.split(' ').first,
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
