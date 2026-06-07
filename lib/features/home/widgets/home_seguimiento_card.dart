import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/theme/am_theme.dart';
import 'package:amconnect/core/mock/mock_data.dart';
import 'package:amconnect/core/widgets/am_avatar.dart';
import 'package:amconnect/core/widgets/am_card.dart';
import 'package:amconnect/core/widgets/am_press.dart';

class HomeSeguimientoCard extends StatelessWidget {
  const HomeSeguimientoCard({super.key, required this.client});
  final MockClient client;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final task = client.notas.isNotEmpty
        ? client.notas.first.t
        : 'Pendiente de seguimiento';

    return AmPress(
      onTap: () => context.push('/clientes/${client.id}'),
      child: AmCard(
        child: Row(
          children: [
            AmAvatar(client: client, size: 46, radius: 15),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task,
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500,
                          color: cs.onSurface),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(client.nombre,
                            style: TextStyle(fontSize: 12.5, color: cs.tertiary),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: am.amberWash,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${client.diasSinContacto}d sin respuesta',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: am.amber)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: am.muted2, size: 18),
          ],
        ),
      ),
    );
  }
}
