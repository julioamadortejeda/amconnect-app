import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/contact.dart';
import '../../../core/models/policy.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_loader.dart';
import '../../../core/widgets/am_press.dart';
import '../../../core/widgets/am_segmented.dart';
import '../../../core/widgets/am_stagger.dart';
import '../providers/clients_provider.dart';
import 'client_avatar_header.dart';
import 'client_contact_info.dart';
import 'client_note_row.dart';
import 'client_policy_card.dart';
import 'client_quick_actions.dart';
import '../../../l10n/app_localizations.dart';

class ClientDetailBody extends ConsumerStatefulWidget {
  const ClientDetailBody({
    super.key,
    required this.contact,
    required this.clientId,
  });

  final Contact contact;
  final String clientId;

  @override
  ConsumerState<ClientDetailBody> createState() => _ClientDetailBodyState();
}

class _ClientDetailBodyState extends ConsumerState<ClientDetailBody> {
  int _tabIdx = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final contact = widget.contact;
    final firstName = contact.fullName.split(' ').first;

    final policiesAsync = ref.watch(contactPoliciesProvider(widget.clientId));
    final policies = policiesAsync.asData?.value ?? <Policy>[];

    final notesAsync = ref.watch(contactNotesProvider(widget.clientId));
    final notes = notesAsync.asData?.value ?? <AgentNote>[];

    final hasContact =
        contact.phone?.isNotEmpty == true || contact.email?.isNotEmpty == true;

    final policiesLabel = l10n.clientsPoliciesTab(policies.length);
    final notesLabel = l10n.clientsNotesTab(notes.length);

    int idx = 0;

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AmDimens.screenH, AmDimens.gapL, AmDimens.screenH, AmDimens.detailScrollBottomPad),
        children: [
          AmAnimateIn(
            index: idx++,
            child: ClientAvatarHeader(contact: contact),
          ),
          const SizedBox(height: AmDimens.gapM),
          AmAnimateIn(
            index: idx++,
            child: ClientQuickActions(clientId: widget.clientId),
          ),
          const SizedBox(height: AmDimens.gapM),
          if (hasContact) ...[
            AmAnimateIn(
              index: idx++,
              child: ClientContactInfo(contact: contact),
            ),
            const SizedBox(height: AmDimens.gapM),
          ],
          AmAnimateIn(
            index: idx++,
            child: AmSegmented(
              options: [policiesLabel, notesLabel],
              selected: _tabIdx == 0 ? policiesLabel : notesLabel,
              onSelect: (v) =>
                  setState(() => _tabIdx = v == policiesLabel ? 0 : 1),
            ),
          ),
          const SizedBox(height: AmDimens.gapS),
          if (_tabIdx == 0) ...[
            if (policiesAsync.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: AmLoader(),
              )
            else if (policies.isEmpty)
              AmAnimateIn(
                index: idx++,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l10n.clientsNoPolicies,
                      style: TextStyle(color: cs.tertiary, fontSize: 13.5),
                    ),
                  ),
                ),
              )
            else
              ...policies.map((p) => AmAnimateIn(
                    index: idx++,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AmDimens.gapS),
                      child: ClientPolicyCard(policy: p),
                    ),
                  )),
          ] else ...[
            if (notesAsync.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: AmLoader(),
              )
            else if (notes.isEmpty)
              AmAnimateIn(
                index: idx++,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l10n.clientsNoNotes,
                      style: TextStyle(color: cs.tertiary, fontSize: 13.5),
                    ),
                  ),
                ),
              )
            else
              ...notes.map((n) => AmAnimateIn(
                    index: idx++,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AmDimens.gapS),
                      child: ClientNoteRow(note: n),
                    ),
                  )),
          ],
          const SizedBox(height: AmDimens.gapM),
          AmAnimateIn(
            index: idx++,
            child: AmPress(
              onTap: () => context.push('/chat'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AmColors.accent,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: AmColors.accent.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo/logo_t.png',
                      color: Colors.white,
                      width: 19,
                      height: 19,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.clientsAskAbout(firstName),
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
