import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/models/contact.dart';
import '../../../core/widgets/am_card.dart';
import '../../../core/widgets/am_badge.dart';
import '../../../core/widgets/am_avatar.dart';
import '../../../core/widgets/am_back_bar.dart';
import '../../../core/widgets/am_segmented.dart';
import '../../../core/widgets/am_press.dart';
import '../providers/clients_provider.dart';
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
    final contactAsync = ref.watch(contactDetailProvider(widget.clientId));

    return contactAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        body: Stack(
          children: [
            const Center(child: Text('No se pudo cargar el cliente')),
            const AmBackBar(),
          ],
        ),
      ),
      data: (contact) => _buildBody(context, contact),
    );
  }

  Widget _buildBody(BuildContext context, Contact contact) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final firstName = contact.fullName.split(' ').first;

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 90),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
                child: Column(
                  children: [
                    AmAvatar(
                        inicial: contact.inicial,
                        color: contact.color,
                        size: 76,
                        radius: 24),
                    const SizedBox(height: 8),
                    Text(contact.fullName,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600,
                            color: cs.onSurface)),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (contact.occupation != null && contact.occupation!.isNotEmpty)
                          contact.occupation!,
                        if (contact.address != null && contact.address!.isNotEmpty)
                          contact.address!,
                      ].join(' · '),
                      style: TextStyle(fontSize: 13.5, color: cs.tertiary),
                    ),
                    const SizedBox(height: 6),
                    AmBadge(label: contact.desde, tone: AmBadgeTone.green),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _QuickAction(
                            icon: Icons.phone_outlined,
                            label: l10n.clientsActionCall,
                            onTap: () {}),
                        const SizedBox(width: 9),
                        _QuickAction(
                            icon: Icons.chat_bubble_outline,
                            label: l10n.clientsActionMessage,
                            onTap: () {}),
                        const SizedBox(width: 9),
                        _QuickAction(
                          icon: Icons.notifications_outlined,
                          label: l10n.clientsActionRemind,
                          onTap: () => context.push(
                              '/create-reminder?cliente=${widget.clientId}'),
                        ),
                        const SizedBox(width: 9),
                        _QuickAction(
                          icon: Icons.auto_awesome,
                          label: l10n.clientsActionAsk,
                          onTap: () => context.push('/chat'),
                          accent: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: AmDimens.gapS),
                    AmCard(
                      noPad: true,
                      child: Column(
                        children: [
                          if (contact.phone != null)
                            _ContactRow(
                                icon: Icons.phone_outlined,
                                text: contact.phone!,
                                hasBorder: contact.email != null),
                          if (contact.email != null)
                            _ContactRow(
                                icon: Icons.email_outlined,
                                text: contact.email!,
                                hasBorder: false),
                        ],
                      ),
                    ),
                    const SizedBox(height: AmDimens.gapS),
                    AmSegmented(
                      options: [
                        l10n.clientsPoliciesTab(0),
                        l10n.clientsNotesTab(0),
                      ],
                      selected: _tabIdx == 0
                          ? l10n.clientsPoliciesTab(0)
                          : l10n.clientsNotesTab(0),
                      onSelect: (v) => setState(
                          () => _tabIdx = v == l10n.clientsPoliciesTab(0) ? 0 : 1),
                    ),
                    const SizedBox(height: AmDimens.gapS),
                    if (_tabIdx == 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(l10n.clientsPoliciesTab(0),
                            style: TextStyle(color: cs.tertiary, fontSize: 13.5)),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(l10n.clientsNotesTab(0),
                            style: TextStyle(color: cs.tertiary, fontSize: 13.5)),
                      ),
                    const SizedBox(height: AmDimens.gapS),
                    AmPress(
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
                                offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_awesome,
                                color: Colors.white, size: 19),
                            const SizedBox(width: 10),
                            Text(l10n.clientsAskAbout(firstName),
                                style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
          AmBackBar(
              trailing: IconButton(
            icon: Icon(Icons.more_horiz, color: cs.onSurface),
            onPressed: () {},
          )),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow(
      {required this.icon, required this.text, required this.hasBorder});
  final IconData icon;
  final String text;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH, vertical: 13),
      decoration: hasBorder
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: cs.outlineVariant)))
          : null,
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.onPrimaryContainer),
          const SizedBox(width: 12),
          Text(text,
              style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: AmPress(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              if (accent)
                BoxShadow(
                    color: AmColors.accent.withValues(alpha: 0.3),
                    blurRadius: 12)
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent ? AmColors.accent : cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    size: 19,
                    color: accent ? Colors.white : cs.onPrimaryContainer),
              ),
              const SizedBox(height: 7),
              Text(label,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
