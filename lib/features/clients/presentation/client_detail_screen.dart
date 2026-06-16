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
import '../../../core/widgets/am_top_bar.dart';
import '../../../core/widgets/am_stagger.dart';
import '../providers/clients_provider.dart';
import '../widgets/client_avatar_header.dart';
import '../widgets/client_contact_info.dart';
import '../widgets/client_policy_card.dart';
import '../widgets/client_quick_actions.dart';
import '../../../l10n/app_localizations.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  const ClientDetailScreen({super.key, required this.clientId});

  final String clientId;

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  int _tabIdx = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final contactAsync = ref.watch(contactDetailProvider(widget.clientId));

    return Scaffold(
      appBar: AmTopBar(
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
      ),
      body: contactAsync.when(
        loading: () => const AmLoader(),
        error: (_, __) => Center(
          child: Text(l10n.clientsError,
              style: TextStyle(color: cs.tertiary)),
        ),
        data: (contact) => _Body(
          contact: contact,
          clientId: widget.clientId,
          tabIdx: _tabIdx,
          onTabChange: (i) => setState(() => _tabIdx = i),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.contact,
    required this.clientId,
    required this.tabIdx,
    required this.onTabChange,
  });

  final Contact contact;
  final String clientId;
  final int tabIdx;
  final ValueChanged<int> onTabChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final firstName = contact.fullName.split(' ').first;

    final policiesAsync = ref.watch(contactPoliciesProvider(clientId));
    final policies = policiesAsync.asData?.value ?? <Policy>[];

    final notesAsync = ref.watch(contactNotesProvider(clientId));
    final notes = notesAsync.asData?.value ?? <AgentNote>[];

    final hasContact = contact.phone?.isNotEmpty == true ||
        contact.email?.isNotEmpty == true;

    final policiesLabel = l10n.clientsPoliciesTab(policies.length);
    final notesLabel = l10n.clientsNotesTab(notes.length);

    int animationIndex = 0;

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AmDimens.screenH, AmDimens.gapL, AmDimens.screenH, 40),
        children: [
          // ── Avatar + nombre ──────────────────────────────────
          AmAnimateIn(
            index: animationIndex++,
            child: ClientAvatarHeader(contact: contact),
          ),
          const SizedBox(height: AmDimens.gapM),

          // ── Acciones rápidas ─────────────────────────────────
          AmAnimateIn(
            index: animationIndex++,
            child: ClientQuickActions(clientId: clientId),
          ),
          const SizedBox(height: AmDimens.gapM),

          // ── Info de contacto ─────────────────────────────────
          if (hasContact) ...[
            AmAnimateIn(
              index: animationIndex++,
              child: ClientContactInfo(contact: contact),
            ),
            const SizedBox(height: AmDimens.gapM),
          ],

          // ── Pólizas / Notas ───────────────────────────────────
          AmAnimateIn(
            index: animationIndex++,
            child: AmSegmented(
              options: [policiesLabel, notesLabel],
              selected: tabIdx == 0 ? policiesLabel : notesLabel,
              onSelect: (v) => onTabChange(v == policiesLabel ? 0 : 1),
            ),
          ),
          const SizedBox(height: AmDimens.gapS),

          // ── Tab content ───────────────────────────────────────
          if (tabIdx == 0) ...[
            if (policiesAsync.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: AmLoader(),
              )
            else if (policies.isEmpty)
              AmAnimateIn(
                index: animationIndex++,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(l10n.clientsNoPolicies,
                        style: TextStyle(color: cs.tertiary, fontSize: 13.5)),
                  ),
                ),
              )
            else
              ...policies.map((p) => AmAnimateIn(
                    index: animationIndex++,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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
                index: animationIndex++,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(l10n.clientsNoNotes,
                        style: TextStyle(color: cs.tertiary, fontSize: 13.5)),
                  ),
                ),
              )
            else
              ...notes.map((n) => AmAnimateIn(
                    index: animationIndex++,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _NoteRow(note: n),
                    ),
                  )),
          ],

          const SizedBox(height: AmDimens.gapM),

          // ── Botón Preguntar al AI ─────────────────────────────
          AmAnimateIn(
            index: animationIndex++,
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

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note});

  final AgentNote note;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (color, icon) = switch (note.sourceType) {
      'pdf' || 'document' => (const Color(0xFFD8453F), Icons.article_outlined),
      'audio' => (const Color(0xFFB9791A), Icons.volume_up_outlined),
      'image' => (const Color(0xFF007AC0), Icons.image_outlined),
      'text' || _ => (const Color(0xFF0E7C42), Icons.chat_bubble_outline),
    };

    final bg = Color.alphaBlend(color.withOpacity(0.1), Colors.white);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AmDimens.cardPad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D141E1A),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x0A141E1A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _noteSubtitle(note),
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.tertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _noteSubtitle(AgentNote note) {
    final label = switch (note.sourceType) {
      'pdf' || 'document' => 'PDF cuestionario médico',
      'audio' => 'Nota de voz',
      'image' => 'Imagen de póliza',
      'text' || _ => 'WhatsApp',
    };
    final date = _fmtNoteDate(note.createdAt);
    return date.isNotEmpty ? '$label · $date' : label;
  }

  String _fmtNoteDate(String s) {
    final dt = DateTime.tryParse(s);
    if (dt == null) return '';
    const months = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}
