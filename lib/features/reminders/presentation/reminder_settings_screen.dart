import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/catalog.dart';
import '../../../core/models/reminder_setting.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/error_translator.dart';
import '../../../core/widgets/am_loader.dart';
import '../../../core/widgets/am_select_sheet.dart';
import '../../../core/widgets/am_top_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../clients/providers/catalog_provider.dart';
import '../providers/reminder_settings_provider.dart';
import '../widgets/reminder_setting_card.dart';

/// Opciones de anticipación. `null` significa apagar ese aviso.
const _kAdvanceOptions = <int?>[0, 7, 15, 30, 45, 60, null];

/// Centinela para la opción "quitar excepción" dentro del mismo selector.
const _kRemoveOption = -1;

class ReminderSettingsScreen extends ConsumerWidget {
  const ReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(reminderSettingsProvider);
    // Se observa aquí para que los ramos ya estén cargados cuando el asesor
    // toque "Agregar excepción" — si no, la primera vez parecería no tener.
    ref.watch(branchesProvider);

    return Scaffold(
      appBar: AmTopBar(
        title: l10n.reminderSettingsTitle,
        subtitle: l10n.reminderSettingsSubtitle,
        showBack: true,
        actions: const [SizedBox(width: AmDimens.screenH)],
      ),
      body: SafeArea(
        top: false,
        child: settings.when(
          loading: () => const AmLoader(),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AmDimens.screenH),
              child: Text(
                context.translateError(
                  error is ApiException ? (error.errorCode ?? error.message) : error.toString(),
                ),
                style: TextStyle(color: cs.tertiary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (items) => ListView(
            padding: const EdgeInsets.fromLTRB(
                AmDimens.screenH, AmDimens.gapM, AmDimens.screenH, AmDimens.scrollBottomPad),
            children: [
              Text(
                l10n.reminderSettingsIntro,
                style: TextStyle(fontSize: 13.5, height: 1.4, color: cs.tertiary),
              ),
              const SizedBox(height: AmDimens.gapS),
              Text(
                l10n.reminderSettingsHint,
                style: TextStyle(fontSize: 12.5, height: 1.4, color: cs.tertiary),
              ),
              const SizedBox(height: AmDimens.gapL),
              for (final setting in items) ...[
                ReminderSettingCard(
                  setting: setting,
                  onToggle: (value) => _save(ref, setting.typeCode, isActive: value),
                  onChangeDays: () => _pickAdvance(
                    context,
                    ref,
                    typeCode: setting.typeCode,
                    current: setting.daysBefore,
                  ),
                  onChangeOverrideDays: (override) => _pickAdvance(
                    context,
                    ref,
                    typeCode: setting.typeCode,
                    branchId: override.branchId,
                    current: override.isActive ? override.daysBefore : null,
                  ),
                  onAddException: () => _pickBranch(context, ref, setting),
                ),
                const SizedBox(height: AmDimens.gapM),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _save(
    WidgetRef ref,
    String typeCode, {
    String? branchId,
    int? daysBefore,
    bool? isActive,
  }) {
    ref.read(reminderSettingsProvider.notifier).save(
          typeCode: typeCode,
          branchId: branchId,
          daysBefore: daysBefore,
          isActive: isActive,
        );
  }

  void _pickAdvance(
    BuildContext context,
    WidgetRef ref, {
    required String typeCode,
    String? branchId,
    required int? current,
  }) {
    // Al editar una excepción se ofrece quitarla ahí mismo: es donde el asesor
    // ya está buscando, en vez de esconderlo en un gesto que nadie descubre.
    final isOverride = branchId != null;
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final sheetL10n = AppLocalizations.of(ctx)!;
        return AmSelectSheet<int?>(
          title: sheetL10n.reminderSettingsPickDays,
          items: [..._kAdvanceOptions, if (isOverride) _kRemoveOption],
          itemLabel: (days) => switch (days) {
            _kRemoveOption => sheetL10n.reminderSettingsRemoveException,
            null => sheetL10n.reminderSettingsOff,
            _ => reminderAdvanceLabel(sheetL10n, days),
          },
          itemFilter: (days, query) => reminderAdvanceLabel(l10n, days ?? 0)
              .toLowerCase()
              .contains(query.toLowerCase()),
          itemId: (days) => days?.toString() ?? 'off',
          itemIsDestructive: (days) => days == _kRemoveOption,
          selectedId: current?.toString() ?? 'off',
          onSelect: (days) {
            if (days == _kRemoveOption) {
              ref.read(reminderSettingsProvider.notifier).removeOverride(
                    typeCode: typeCode,
                    branchId: branchId!,
                  );
              return;
            }
            _save(
              ref,
              typeCode,
              branchId: branchId,
              daysBefore: days,
              // "Sin avisos" apaga; elegir un número lo vuelve a prender.
              isActive: days != null,
            );
          },
        );
      },
    );
  }

  void _pickBranch(BuildContext context, WidgetRef ref, ReminderSetting setting) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final available = ref.read(availableBranchesForSettingProvider(setting.typeCode));

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reminderSettingsNoBranches)),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AmSelectSheet<Branch>(
        title: AppLocalizations.of(ctx)!.reminderSettingsPickBranch,
        items: available,
        itemLabel: (b) => b.name,
        itemFilter: (b, q) => b.name.toLowerCase().contains(q.toLowerCase()),
        itemId: (b) => b.id,
        onSelect: (branch) {
          if (branch == null) return;
          // La excepción nace con la misma anticipación que el default; de ahí
          // el asesor la ajusta tocándola.
          _save(ref, setting.typeCode,
              branchId: branch.id, daysBefore: setting.daysBefore, isActive: true);
        },
      ),
    );
  }
}
