import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/contact.dart';
import '../../../core/models/policy.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_loader.dart';
import '../../../core/widgets/am_note_row.dart';
import '../../../core/widgets/am_press.dart';
import '../../../core/widgets/am_segmented.dart';
import '../../../core/widgets/am_stagger.dart';
import '../../../core/models/agent_note.dart';
import '../../feed/data/ingest_repository.dart';
import '../providers/clients_provider.dart';
import 'add_client_note_sheet.dart';
import 'client_avatar_header.dart';
import 'client_contact_info.dart';
import 'client_fiscal_info.dart';
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

  Future<void> _addNote() async {
    final content = await AddClientNoteSheet.show(context);
    if (content == null || content.isEmpty) return;
    try {
      await IngestRepository(ref.read(apiClientProvider)).ingestKnowledgeText(
        content: content,
        sourceType: 'text',
        contactId: widget.clientId,
        isClientNote: true,
      );
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.clientsErrAddNote),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final contact = widget.contact;

    // Activate Realtime — auto-disposes when this widget leaves the tree
    ref.watch(contactPoliciesRealtimeProvider(widget.clientId));
    ref.watch(contactNotesRealtimeProvider(widget.clientId));

    final policiesAsync = ref.watch(contactPoliciesProvider(widget.clientId));
    final policies = policiesAsync.asData?.value ?? <Policy>[];

    final notesAsync = ref.watch(contactNotesProvider(widget.clientId));
    final notes = notesAsync.asData?.value ?? <AgentNote>[];

    final policiesLabel = l10n.clientsPoliciesTab(policies.length);
    final notesLabel = l10n.clientsNotesTab(notes.length);

    int idx = 0;

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AmDimens.screenH,
          AmDimens.gapL,
          AmDimens.screenH,
          AmDimens.gapL,
        ),
        children: [
          AmAnimateIn(
            index: idx++,
            child: ClientAvatarHeader(contact: contact),
          ),
          const SizedBox(height: AmDimens.gapM),
          AmAnimateIn(
            index: idx++,
            child: ClientQuickActions(clientId: widget.clientId, phone: contact.phone),
          ),
          const SizedBox(height: AmDimens.gapM),
          AmAnimateIn(
            index: idx++,
            child: ClientContactInfo(contact: contact),
          ),
          const SizedBox(height: AmDimens.gapM),
          AmAnimateIn(
            index: idx++,
            child: ClientFiscalInfo(contact: contact),
          ),
          const SizedBox(height: AmDimens.gapM),
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
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _tabIdx == 0
                  ? _TabContent(
                      key: const ValueKey(0),
                      child: _buildPoliciesContent(
                          policiesAsync.isLoading, policies, cs, l10n),
                    )
                  : _TabContent(
                      key: const ValueKey(1),
                      child: _buildNotesContent(
                          notesAsync.isLoading, notes, cs, l10n),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliciesContent(
    bool loading,
    List<Policy> policies,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: AmLoader(),
      );
    }
    if (policies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Text(
                l10n.clientsNoPolicies,
                style: TextStyle(color: cs.tertiary, fontSize: 13.5),
              ),
              const SizedBox(height: AmDimens.gapM),
              AmPress(
                onTap: () => context.push('/create-policy?client=${widget.clientId}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: cs.primary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        l10n.policiesNewPolicyTitle,
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AmDimens.gapM),
          child: AmPress(
            onTap: () => context.push('/create-policy?client=${widget.clientId}'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.policiesNewPolicyTitle,
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ...policies.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: AmDimens.gapS),
              child: ClientPolicyCard(policy: p),
            )),
      ],
    );
  }

  Widget _buildNotesContent(
    bool loading,
    List<AgentNote> notes,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: AmLoader(),
      );
    }
    final addNoteButton = Padding(
      padding: const EdgeInsets.only(bottom: AmDimens.gapM),
      child: AmPress(
        onTap: _addNote,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                l10n.clientsAddNote,
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (notes.isEmpty) {
      return Column(
        children: [
          addNoteButton,
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              l10n.clientsNoNotes,
              style: TextStyle(color: cs.tertiary, fontSize: 13.5),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        addNoteButton,
        ...notes.map((n) => Padding(
              padding: const EdgeInsets.only(bottom: AmDimens.gapS),
              child: AmNoteRow(note: n),
            )),
      ],
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: child,
      );
}
