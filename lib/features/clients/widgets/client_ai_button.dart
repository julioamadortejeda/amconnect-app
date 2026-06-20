import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/contact.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_press.dart';
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AmDimens.screenH,
          AmDimens.gapS,
          AmDimens.screenH,
          AmDimens.gapM,
        ),
        child: AmPress(
          onTap: () => context.push('/chat', extra: aiContext),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AmDimens.gapM),
            decoration: BoxDecoration(
              color: AmColors.accent,
              borderRadius: BorderRadius.circular(AmDimens.cardRadius),
              boxShadow: [
                BoxShadow(
                  color: AmColors.accent.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo/logo.png',
                  color: AmColors.onAccent,
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: AmDimens.gapXS),
                Text(
                  l10n.clientsAskAbout(firstName),
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    color: AmColors.onAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
