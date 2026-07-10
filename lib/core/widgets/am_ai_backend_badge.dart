import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../config/features.dart';
import '../providers/ai_backend_provider.dart';
import 'am_badge.dart';

/// Badge Free/Enterprise según el backend de IA que procesó la última
/// respuesta. Se oculta solo si el flag está apagado o aún no hay respuesta.
class AmAiBackendBadge extends ConsumerWidget {
  const AmAiBackendBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kShowAiBackendBadge) return const SizedBox.shrink();
    final backend = ref.watch(aiBackendProvider);
    if (backend == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final isEnterprise = backend == 'vertex';
    return AmBadge(
      label: isEnterprise ? l10n.chatBackendEnterprise : l10n.chatBackendFree,
      tone: isEnterprise ? AmBadgeTone.accent : AmBadgeTone.muted,
      icon: isEnterprise ? Icons.verified_outlined : null,
    );
  }
}
