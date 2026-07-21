import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/contact.dart';
import '../../../core/widgets/am_ai_ask_button.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/clients_provider.dart';

class ClientAiButton extends ConsumerWidget {
  const ClientAiButton({super.key, required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final firstName = contact.fullName.split(' ').first;
    final aiContext = ref.watch(contactAiContextProvider(contact.id));

    return AmAiAskButton(
      label: l10n.clientsAskAbout(firstName),
      aiContext: aiContext,
    );
  }
}
