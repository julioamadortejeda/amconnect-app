import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/commitment.dart';
import '../providers/commitments_provider.dart';
import '../theme/am_theme.dart';
import '../theme/app_dimensions.dart';
import '../utils/formatters.dart';
import '../../l10n/app_localizations.dart';
import 'am_confirm_dialog.dart';
import 'am_press.dart';

/// Una fila de "Se te va a pasar".
///
/// Dos líneas: **la acción arriba y el cliente abajo**. El asesor no escanea a
/// quién, escanea qué tiene que hacer — poner el nombre primero invertía la
/// jerarquía y además lo truncaba.
///
/// No lleva icono. Los recordatorios sí (pago, renovación, llamada… cada tipo
/// el suyo), pero los compromisos no tienen taxonomía a propósito: `label` es
/// texto libre para que un caso nuevo no pida migración. Un icono siempre igual
/// no es información, es un margen de 38px con adorno — el espacio se lo queda
/// el texto.
///
/// Lo único que varía es la urgencia, y va UNA sola vez: en la pastilla de la
/// fecha. Antes iba dos —un punto a la izquierda y el color de la fecha— y el
/// punto era el peor de los dos: 8px al borde de la tarjeta que se leían grises
/// casi siempre, codificando lo mismo que el elemento que el ojo ya mira para
/// saber cuándo toca.
class AmCommitmentRow extends ConsumerWidget {
  const AmCommitmentRow({
    super.key,
    required this.commitment,
    this.showClient = true,
    this.showQuote = false,
  });

  final Commitment commitment;

  /// False dentro de la ficha de un cliente: ahí el nombre se repetiría en cada
  /// fila, y tocarla empujaría OTRA VEZ la misma pantalla.
  final bool showClient;

  /// La cita textual de la nota. En el dashboard estorba —dice casi lo mismo
  /// que la etiqueta y cuesta un renglón por fila— pero dentro del cliente es
  /// justo la evidencia que el asesor quiere ver.
  final bool showQuote;

  static const _rowGap = 10.0;

  /// Margen invisible a los lados del círculo de la palomita. Se le resta al
  /// padding derecho de la fila para que el borde VISIBLE del botón quede
  /// alineado con el resto del contenido y no 7px metido hacia adentro.
  static const _actionInset =
      (AmDimens.listActionHit - AmDimens.listActionDim) / 2;

  Future<void> _confirmDone(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(commitmentsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    // Con confirmación a propósito: sin ella un roce accidental le borra un
    // pendiente y no se entera hasta que pierde al cliente.
    await showDialog<void>(
      context: context,
      builder: (_) => AmConfirmDialog(
        title: l10n.commitmentsDoneTitle,
        message: l10n.commitmentsDoneMessage(
            commitment.clientName ?? l10n.commitmentsTitle),
        confirmLabel: l10n.commitmentsDoneAction,
        cancelLabel: l10n.commonCancel,
        icon: Icons.check_rounded,
        iconBgColor: context.am.greenWash,
        iconFgColor: context.am.green,
        onConfirm: () async {
          await notifier.close(commitment.id);
          messenger.showSnackBar(SnackBar(
            content: Text(l10n.commitmentsClosed),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ));
        },
      ),
    );
  }

  /// Cuándo toca.
  ///
  /// Sin fecha no es una cita sino algo que envejece, y ahí importa cuánto
  /// lleva esperando.
  ///
  /// El caso de hoy dice "registrado hoy" y no "hoy" a secas: la insignia
  /// muestra a veces una fecha ("7–13 sep") y a veces una antigüedad, y "hoy"
  /// suelto se lee como vencimiento. Pasó en pruebas — se entendió como "vence
  /// hoy" en un compromiso que a propósito no tiene fecha ni alarma.
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

    // Mismo par (fondo lavado, texto sólido) que la pastilla de ReminderItem.
    // El estado tranquilo es neutro a propósito: si los tres estados llevaran
    // color, el rojo dejaría de significar algo.
    final (badgeBg, badgeFg) = switch (commitment.urgency) {
      CommitmentUrgency.overdue => (cs.errorContainer, cs.error),
      CommitmentUrgency.soon => (am.amberWash, am.amber),
      CommitmentUrgency.later => (cs.secondaryContainer, cs.onSurfaceVariant),
    };

    // Sin cliente ligado no hay a dónde ir, y dentro de la ficha iríamos a la
    // pantalla en la que ya estamos.
    final clientId = commitment.contactId;
    final canOpenClient = showClient && clientId != null;

    final secondary = showClient ? commitment.clientName : null;

    return AmPress(
      onTap: canOpenClient ? () => context.push('/clients/$clientId') : null,
      child: Padding(
        // Vertical más corto que el gapS de otras listas porque el botón de 48
        // ya aporta la altura de la fila; con gapS encima quedaba un bloque.
        // A la derecha se descuenta el margen invisible del botón.
        padding: const EdgeInsets.fromLTRB(AmDimens.screenH, AmDimens.gapXS,
            AmDimens.screenH - _actionInset, AmDimens.gapXS),
        child: Row(
          // Centrado y no `start`: la fecha y la palomita son de la fila
          // entera, no de su primer renglón. Con `start` se pegaban arriba y la
          // fila se veía chueca en cuanto la etiqueta pasaba a dos líneas.
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    capitalizeFirst(commitment.label),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                      height: 1.25,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  if (secondary != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      secondary,
                      style: TextStyle(fontSize: 12.5, color: cs.tertiary),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                  if (showQuote) ...[
                    const SizedBox(height: 3),
                    Text(
                      '“${commitment.quote}”',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: cs.tertiary,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: _rowGap),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AmDimens.listBadgePadH,
                  vertical: AmDimens.listBadgePadV),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(AmDimens.listBadgeRadius),
              ),
              child: Text(
                _timing(l10n),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: badgeFg,
                ),
              ),
            ),
            // Un check en vez del chip "¿Ya quedó?": cuatro chips verdes
            // alineados eran lo más saturado de la tarjeta siendo lo menos
            // importante. El diálogo de confirmación ya explica qué hace.
            //
            // Pero un icono suelto tampoco se leía como botón, y con la fila
            // entera siendo tocable el asesor no sabía dónde terminaba una cosa
            // y empezaba la otra. El círculo lavado lo dice sin una palabra, y
            // el área táctil llega a los 48 de Material aunque el círculo mida
            // 34 — antes eran 31 y había que atinarle.
            AmPress(
              onTap: () => _confirmDone(context, ref),
              child: SizedBox(
                width: AmDimens.listActionHit,
                height: AmDimens.listActionHit,
                child: Center(
                  child: Container(
                    width: AmDimens.listActionDim,
                    height: AmDimens.listActionDim,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: am.greenWash,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded, size: 19, color: am.green),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
