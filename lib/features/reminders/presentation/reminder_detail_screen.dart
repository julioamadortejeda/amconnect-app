import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/reminder.dart';
import '../../../core/models/reminder_type.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_reschedule_dialog.dart';
import '../../../core/widgets/am_press.dart';
import '../../../core/widgets/am_section_label.dart';
import '../../../core/widgets/am_top_bar.dart';
import '../../home/providers/home_provider.dart';
import '../providers/reminders_provider.dart';
import '../widgets/reminder_comment_bubble.dart';
import '../widgets/reminder_detail_hero.dart';
import '../widgets/reminder_detail_info_section.dart';
import '../widgets/reminder_detail_relations_section.dart';
import '../widgets/reminder_type_selection_sheet.dart';
import '../widgets/am_reminder_actions_sheet.dart';
import '../../../core/widgets/am_stagger.dart';
import '../../../l10n/app_localizations.dart';

class ReminderDetailScreen extends ConsumerStatefulWidget {
  const ReminderDetailScreen({super.key, required this.reminder});

  final Reminder reminder;

  @override
  ConsumerState<ReminderDetailScreen> createState() =>
      _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends ConsumerState<ReminderDetailScreen> {
  bool _editing = false;
  bool _saving = false;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.reminder.title);
    _descCtrl = TextEditingController(text: widget.reminder.description ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Reminder _fresh(List<Reminder> list) =>
      list.firstWhere((r) => r.id == widget.reminder.id,
          orElse: () => widget.reminder);

  void _enterEdit(Reminder r) {
    _titleCtrl.text = r.title;
    _descCtrl.text = r.description ?? '';
    setState(() => _editing = true);
  }

  Future<void> _save(Reminder r) async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    await ref.read(remindersProvider.notifier).updateDetails(
          r.id,
          title: title,
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context)!.remindersDetailSaved),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  void _showTypeSheet(BuildContext ctx, Reminder r, List<ReminderType> types,
      AppLocalizations l10n, ColorScheme cs) {
    showModalBottomSheet(
      context: ctx,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => ReminderTypeSelectionSheet(
        reminder: r,
        types: types,
      ),
    );
  }

  void _reschedule(BuildContext ctx, Reminder r) {
    showDialog(
      context: ctx,
      builder: (_) => AmRescheduleDialog(
        initialDateTime:
            r.dueDate ?? DateTime.now().add(const Duration(days: 1)),
        onConfirm: (dt) =>
            ref.read(remindersProvider.notifier).reschedule(r.id, dt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(remindersProvider).asData?.value ?? [];
    final r = _fresh(reminders);
    final types = ref.watch(reminderTypesProvider).asData?.value ?? [];
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    int aniIdx = 0;

    final trailingBar = r.cancelled
        ? const SizedBox.shrink()
        : _editing
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => setState(() => _editing = false),
                child: Text(
                  l10n.remindersConfirmCancelBtn,
                  style: TextStyle(color: cs.tertiary),
                ),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: _saving ? null : () => _save(r),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : Text(
                        l10n.remindersDetailSave,
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(width: 4),
            ],
          )
        : Padding(
            padding: const EdgeInsets.only(right: 4),
            child: AmPress(
              onTap: () => _enterEdit(r),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          );

    return Scaffold(
      appBar: AmTopBar(
        title: l10n.remindersDetailTitle,
        showBack: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: trailingBar,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AmDimens.screenH,
            AmDimens.gapM,
            AmDimens.screenH,
            40,
          ),
          children: [
            // ── HERO: Título + Descripción ──────────────────────
            AmAnimateIn(
              index: aniIdx++,
              child: ReminderDetailHero(
                reminder: r,
                editing: _editing,
                titleCtrl: _titleCtrl,
                descCtrl: _descCtrl,
                onEdit: r.cancelled ? null : () => _enterEdit(r),
              ),
            ),
            const SizedBox(height: AmDimens.gapM),

            // ── DETALLES ─────────────────────────────────────────
            AmAnimateIn(
              index: aniIdx++,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AmSectionLabel(label: l10n.remindersDetailStatus),
                  const SizedBox(height: AmDimens.gapXS),
                  ReminderDetailInfoSection(
                    reminder: r,
                    onTapType: r.cancelled || types.isEmpty
                        ? null
                        : () => _showTypeSheet(context, r, types, l10n, cs),
                    onTapStatus: r.cancelled
                        ? null
                        : () {
                            showModalBottomSheet(
                              context: context,
                              useRootNavigator: true,
                              backgroundColor: cs.surface,
                              shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              builder: (_) => AmReminderActionsSheet(
                                reminder: r,
                                showReschedule: false,
                              ),
                            );
                          },
                    onTapReschedule: r.cancelled ? null : () => _reschedule(context, r),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AmDimens.gapM),

            // ── RELACIONES ────────────────────────────────────────
            if (r.policyNumber != null || r.contactId != null) ...[
              AmAnimateIn(
                index: aniIdx++,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AmSectionLabel(label: l10n.remindersDetailRelations),
                    const SizedBox(height: AmDimens.gapXS),
                    ReminderDetailRelationsSection(
                      reminder: r,
                      onTapClient: () => context.push('/clients/${r.contactId}'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AmDimens.gapM),
            ],

            // ── COMENTARIOS ──────────────────────────────────────
            AmAnimateIn(
              index: aniIdx++,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AmSectionLabel(
                    label: r.comments.isNotEmpty
                        ? '${l10n.remindersDetailComments} (${r.comments.length})'
                        : l10n.remindersDetailComments,
                  ),
                  const SizedBox(height: AmDimens.gapXS),
                  if (r.comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        l10n.remindersDetailNoComments,
                        style: TextStyle(fontSize: 14, color: cs.tertiary),
                      ),
                    )
                  else
                    ...r.comments.map((c) => ReminderCommentBubble(comment: c)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
