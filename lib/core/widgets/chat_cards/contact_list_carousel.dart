import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../am_press.dart';
import '../../utils/formatters.dart';
import '../../../l10n/app_localizations.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  CONTACT LIST CAROUSEL
// ═══════════════════════════════════════════════════════════════════════════════

class ContactListCarousel extends StatelessWidget {
  const ContactListCarousel({super.key, required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final list = data['contacts'] as List? ?? [];

    // Sin filas no hay tarjeta: el encabezado solo, flotando sobre nada, se lee
    // como un error de la app. El backend ya no manda la metadata cuando la
    // búsqueda viene vacía; esto cubre a cualquier otra skill que lo olvide.
    if (list.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AmDimens.cardPad),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        boxShadow: const [
          BoxShadow(
            color: AmColors.shadowSoft,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_outlined, color: cs.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.chatCardContactListTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AmDimens.gapS),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length > 5 ? 5 : list.length,
            itemBuilder: (context, index) {
              final map = list[index] as Map<String, dynamic>? ?? {};
              final id = map['id'] as String? ?? '';
              final fullName = map['fullName'] as String? ?? '';
              final phone = map['phone'] as String?;
              final initials = getInitials(fullName);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AmPress(
                  onTap: () => context.push('/clients/$id?fromChat=true'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AmDimens.radiusM),
                      border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: cs.secondaryContainer,
                          child: Text(
                            initials,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSecondaryContainer),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (phone != null && phone.isNotEmpty)
                                Text(
                                  phone,
                                  style: TextStyle(fontSize: 11, color: cs.tertiary),
                                ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 18, color: cs.tertiary),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
