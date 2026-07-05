import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/reminder_type.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/catalog_l10n.dart';
import '../providers/reminders_provider.dart';
import 'deleted_reminders_view.dart';
import 'reminder_filter_chip.dart';
import 'reminder_item.dart';
import '../../../core/widgets/am_stagger.dart';
import '../../../l10n/app_localizations.dart';

const _typeOrder = [
  'PAYMENT', 'RENEWAL', 'CANCELLATION',
  'FOLLOW_UP', 'CALL', 'APPOINTMENT', 'ANNIVERSARY', 'OTHER',
];

int _typePriority(ReminderType t) {
  final i = _typeOrder.indexOf(t.code);
  return i == -1 ? _typeOrder.length : i;
}

class ReminderListView extends ConsumerWidget {
  const ReminderListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final ui = ref.watch(remindersUiProvider);
    final reminders = ref.watch(filteredRemindersProvider);
    final typesAsync = ref.watch(reminderTypesProvider);

    return Column(
      children: [
        AmAnimateIn(
          index: 0,
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ReminderFilterChip(
                    label: l10n.remindersFilterAll,
                    active: ui.filter == 'todos',
                    onTap: () =>
                        ref.read(remindersUiProvider.notifier).setFilter('todos'),
                  ),
                ),
                ...typesAsync.maybeWhen(
                  data: (types) => (List.of(types)
                        ..sort((a, b) => _typePriority(a).compareTo(_typePriority(b))))
                      .map((t) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ReminderFilterChip(
                          label: l10n.reminderType(t.code),
                          active: ui.filter == t.code,
                          onTap: () => ref
                              .read(remindersUiProvider.notifier)
                              .setFilter(t.code),
                        ),
                      )),
                  orElse: () => [],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ReminderFilterChip(
                    label: l10n.remindersFilterDeleted,
                    active: ui.filter == 'eliminados',
                    danger: true,
                    onTap: () => ref
                        .read(remindersUiProvider.notifier)
                        .setFilter('eliminados'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (ui.filter == 'eliminados') ...[
          const SizedBox(height: AmDimens.gapXS),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: cs.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.remindersDeletedWarning,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: cs.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AmDimens.gapS),
        Expanded(
          child: reminders.isEmpty
              ? Center(
                  child: Text(
                    l10n.remindersEmpty,
                    style: TextStyle(fontSize: 14, color: cs.tertiary),
                  ),
                )
              : ui.filter == 'eliminados'
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: AmDimens.scrollBottomPad),
                      child: const DeletedRemindersView(),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // ListView (no-shrinkWrap) siempre llena el alto disponible,
                          // incluso con pocos items — a diferencia del Column anterior
                          // que se encogía al contenido. Estimamos si el contenido cabe
                          // sin scroll para decidir shrinkWrap (encoge a contenido, cae
                          // sobre Align en vez de estirar la card) vs. lista normal
                          // (llena y virtualiza de verdad — necesario para no repetir
                          // el jank de layout con listas grandes). Estimación conservadora
                          // hacia arriba: preferimos virtualizar de más a arriesgar overflow.
                          const estimatedRowHeight = 80.0;
                          final fitsWithoutScroll =
                              reminders.length * estimatedRowHeight <= constraints.maxHeight;

                          return Align(
                            alignment: Alignment.topCenter,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AmDimens.cardRadius),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x0D141E1A), blurRadius: 2, offset: Offset(0, 1)),
                                  BoxShadow(color: Color(0x0A141E1A), blurRadius: 10, offset: Offset(0, 3)),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AmDimens.cardRadius),
                                child: ListView.separated(
                                  // El padding inferior solo tiene sentido cuando hay scroll
                                  // real (despeja la barra de tabs) — con shrinkWrap:true se
                                  // suma al tamaño de la card, dejando espacio en blanco extra
                                  // después del último item.
                                  padding: EdgeInsets.only(
                                    bottom: fitsWithoutScroll ? 0 : AmDimens.scrollBottomPad,
                                  ),
                                  shrinkWrap: fitsWithoutScroll,
                                  physics: fitsWithoutScroll
                                      ? const NeverScrollableScrollPhysics()
                                      : null,
                                  itemCount: reminders.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 0,
                                    indent: AmDimens.screenH,
                                    endIndent: AmDimens.screenH,
                                    color: cs.outlineVariant,
                                  ),
                                  // index acotado: el delay de entrada de AmAnimateIn crece
                                  // con el índice (30ms + 40ms*index) — sin límite, un item
                                  // que entra al viewport por scroll tras construirse de forma
                                  // perezosa (lejos del inicio) tardaría segundos en aparecer.
                                  itemBuilder: (_, i) => AmAnimateIn(
                                    index: (i + 1).clamp(0, 10),
                                    child: ReminderItem(reminder: reminders[i]),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
