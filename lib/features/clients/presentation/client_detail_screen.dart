import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_loader.dart';
import '../../../core/widgets/am_press.dart';
import '../../../core/widgets/am_top_bar.dart';
import '../providers/clients_provider.dart';
import '../widgets/client_detail_body.dart';
import '../../../l10n/app_localizations.dart';

class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final appBar = AmTopBar(
      title: l10n.clientsTitle,
      showBack: true,
      actions: [
        AmPress(
          onTap: () {},
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.more_horiz, size: 20, color: cs.onSurfaceVariant),
          ),
        ),
        SizedBox(width: AmDimens.screenH),
      ],
    );

    // Usa el contacto ya cargado en memoria — navegación instantánea
    final cached = ref.watch(clientsProvider).asData?.value
        .where((c) => c.id == clientId)
        .firstOrNull;

    if (cached != null) {
      return Scaffold(
        appBar: appBar,
        body: ClientDetailBody(contact: cached, clientId: clientId),
      );
    }

    // Fallback para deep links (antes de que cargue el listado)
    final contactAsync = ref.watch(contactDetailProvider(clientId));
    return Scaffold(
      appBar: appBar,
      body: contactAsync.when(
        loading: () => const AmLoader(),
        error: (_, __) => Center(
          child: Text(l10n.clientsError,
              style: TextStyle(color: cs.tertiary)),
        ),
        data: (contact) =>
            ClientDetailBody(contact: contact, clientId: clientId),
      ),
    );
  }
}
