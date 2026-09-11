import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/commitment.dart';
import '../providers/commitments_provider.dart';
import '../theme/am_theme.dart';
import '../utils/formatters.dart';
import '../../l10n/app_localizations.dart';
import 'am_confirm_dialog.dart';
import 'am_sheet.dart';

/// El detalle de un compromiso, completo y sin recortar.
///
/// Existe porque el asesor reportó que en la fila "no se alcanza a leer": ahí
/// la etiqueta va a dos líneas, la cita a dos y el cliente a una, todas con
/// puntos suspensivos, y no había ninguna otra pantalla donde ver el resto —
/// los compromisos no tienen ficha propia como los recordatorios.
///
/// Se abre al TOCAR la fila, que antes empujaba la ficha del cliente. Ese viaje
/// no se pierde: es uno de los mosaicos de abajo.
///
/// Sigue el mismo lenguaje que `AmReminderActionsSheet` —manija, título y
/// subtítulo centrados, acciones en mosaicos— para que las dos mitades de la
/// agenda se sientan la misma app.
Future<void> showCommitmentSheet(
  BuildContext context,
  Commitment commitment, {
  bool showClient = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _CommitmentSheet(
      commitment: commitment,
      showClient: showClient,
    ),
  );
}

class _CommitmentSheet extends ConsumerWidget {
  const _CommitmentSheet({required this.commitment, required this.showClient});

  final Commitment commitment;
  final bool showClient;

  /// Misma regla que la fila: sin fecha no es una cita sino algo que envejece,
  /// y ahí importa cuánto lleva esperando.
  String _timing(AppLocalizations l10n) {
    final from = commitment.dueFrom;
    final to = commitment.dueTo;
    if (to != null) {
      if (from != null && from != to) return fmtDateRange(from, to);
      return fmtSmartDate(to, l10n);
    }
    final created = commitment.createdAt;
    if (created == null) return l10n.commitmentsNoDate;
    final days = DateTime.now().difference(created).inDays;
    return days <= 0 ? l10n.commitmentsAgeToday : l10n.commitmentsAgeDays(days);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;
    final clientId = commitment.contactId;
    final puedeAbrirCliente = showClient && clientId != null;

    // Igual que en el sheet de recordatorios: el notifier se toma ANTES de
    // cualquier pop, para usarlo seguro dentro del diálogo.
    final notifier = ref.read(commitmentsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final colorUrgencia = switch (commitment.urgency) {
      CommitmentUrgency.overdue => cs.error,
      CommitmentUrgency.soon => am.amber,
      CommitmentUrgency.later => cs.tertiary,
    };

    void alCerrar() {
      showDialog<void>(
        context: context,
        builder: (_) => AmConfirmDialog(
          title: l10n.commitmentsDoneTitle,
          message: l10n.commitmentsDoneMessage(
              commitment.clientName ?? l10n.commitmentsTitle),
          confirmLabel: l10n.commitmentsDoneAction,
          cancelLabel: l10n.commonCancel,
          icon: Icons.check_rounded,
          iconBgColor: am.greenWash,
          iconFgColor: am.green,
          onConfirm: () async {
            await notifier.close(commitment.id);
            navigator.pop();
            messenger.showSnackBar(SnackBar(
              content: Text(l10n.commitmentsClosed),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ));
          },
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // `titleMaxLines: null` a propósito: que la etiqueta se lea
            // completa es la razón por la que esta hoja existe.
            AmSheetHeader(
              title: commitment.label,
              titleMaxLines: null,
              subtitle: puedeAbrirCliente && commitment.clientName != null
                  ? '${commitment.clientName} · ${_timing(l10n)}'
                  : _timing(l10n),
              subtitleColor: colorUrgencia,
            ),
            if (commitment.quote.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              // La cita NO es tarjeta: no se toca, y con relleno y borde se
              // leía como un botón que no hace nada. Es la evidencia que el
              // asesor relee días después —cuando ya no se acuerda de si lo
              // dijo así— y como texto se lee mejor. La raya al margen es lo
              // único que necesita para decir "esto es una cita".
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: cs.outlineVariant, width: 2),
                  ),
                ),
                child: Text(
                  commitment.quote,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                if (puedeAbrirCliente) ...[
                  AmSheetTile(
                    icon: Icons.person_outline_rounded,
                    label: l10n.commitmentsViewClient,
                    onTap: () {
                      navigator.pop();
                      context.push('/clients/$clientId');
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                AmSheetTile(
                  icon: Icons.check_rounded,
                  color: am.green,
                  label: l10n.commitmentsDoneAction,
                  onTap: alCerrar,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
