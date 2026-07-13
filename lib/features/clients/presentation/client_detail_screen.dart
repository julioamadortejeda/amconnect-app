import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/contact.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_loader.dart';
import '../../../core/widgets/am_press.dart';
import '../../../core/widgets/am_top_bar.dart';
import '../providers/clients_provider.dart';
import '../widgets/client_ai_button.dart';
import '../widgets/client_detail_body.dart';
import '../../../l10n/app_localizations.dart';

class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({
    super.key,
    required this.clientId,
    this.fromChat = false,
  });

  final String clientId;
  final bool fromChat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final cached = ref
        .watch(clientsProvider)
        .asData
        ?.value
        .where((c) => c.id == clientId)
        .firstOrNull;

    PreferredSizeWidget buildAppBar(Contact? contact) => AmTopBar(
      //title: l10n.clientsTitle,
      showBack: true,
      actions: [
        AmPress(
          onTap: contact == null
              ? null
              : () => context.push('/create-client', extra: contact),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(AmDimens.cardRadius / 2),
            ),
            child: Icon(Icons.edit_outlined, size: 18, color: cs.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: AmDimens.screenH),
      ],
    );

    if (cached != null) {
      final appBar = buildAppBar(cached);
      return Scaffold(
        appBar: appBar,
        bottomNavigationBar: fromChat ? null : ClientAiButton(contact: cached),
        body: ClientDetailBody(contact: cached, clientId: clientId),
      );
    }

    final contactAsync = ref.watch(contactDetailProvider(clientId));
    return Scaffold(
      appBar: buildAppBar(contactAsync.asData?.value),
      bottomNavigationBar: !fromChat && contactAsync.asData?.value != null
          ? ClientAiButton(contact: contactAsync.asData!.value)
          : null,
      body: contactAsync.when(
        loading: () => const AmLoader(),
        error: (_, __) => Center(
          child: Text(l10n.clientsError, style: TextStyle(color: cs.tertiary)),
        ),
        data: (contact) =>
            ClientDetailBody(contact: contact, clientId: clientId),
      ),
    );
  }
}
