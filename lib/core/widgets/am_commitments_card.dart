import 'package:flutter/material.dart';
import '../models/commitment.dart';
import '../theme/app_dimensions.dart';
import 'am_card.dart';
import 'am_commitment_row.dart';

class AmCommitmentsCard extends StatelessWidget {
  const AmCommitmentsCard({
    super.key,
    required this.commitments,
    this.showClient = true,
    this.showQuote = false,
    this.maxVisible = _dashboardMax,
  });

  final List<Commitment> commitments;

  /// Cuántas filas pintar. Null las pinta todas — la pestaña de Agenda existe
  /// justo para eso, ahí el recorte del dashboard sería el bug.
  final int? maxVisible;

  /// Ver [AmCommitmentRow.showClient].
  final bool showClient;

  /// Ver [AmCommitmentRow.showQuote].
  final bool showQuote;

  /// Cuántas caben en el dashboard antes de volverse ruido. El asesor que ve 20
  /// filas deja de leerlas; el resto sale en la vista completa.
  static const _dashboardMax = 4;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final max = maxVisible;
    final visible = max == null ? commitments : commitments.take(max).toList();

    return AmCard(
      noPad: true,
      child: Column(
        children: [
          for (int i = 0; i < visible.length; i++) ...[
            if (i > 0)
              Divider(
                height: 0,
                indent: AmDimens.screenH,
                endIndent: AmDimens.screenH,
                color: cs.outlineVariant,
              ),
            AmCommitmentRow(
              commitment: visible[i],
              showClient: showClient,
              showQuote: showQuote,
            ),
          ],
        ],
      ),
    );
  }
}
