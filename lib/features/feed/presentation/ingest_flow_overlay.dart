import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_translator.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/ingest_provider.dart';
import '../presentation/feed_screen.dart' show recentFeedProvider;
import 'ingest_chat_sheet.dart';
import 'knowledge_success_sheet.dart';
import 'policy_success_sheet.dart';

/// Escucha ingestProvider globalmente y muestra los sheets del flujo de
/// ingesta (progreso, chat de confirmación, éxito, error) sin importar en qué
/// pantalla/tab se haya disparado la ingesta. Debe montarse una sola vez en
/// un widget que viva durante toda la sesión (ShellScreen) — StatefulShellRoute
/// construye cada tab de forma perezosa, así que un listener dentro de
/// FeedScreen solo se activaría después de visitar el tab "Datos" al menos
/// una vez, dejando huérfanas las ingestas disparadas desde otras pantallas.
class IngestFlowOverlay extends ConsumerStatefulWidget {
  const IngestFlowOverlay({super.key});

  @override
  ConsumerState<IngestFlowOverlay> createState() => _IngestFlowOverlayState();
}

class _IngestFlowOverlayState extends ConsumerState<IngestFlowOverlay> {
  void _handleClose() {
    ref.read(ingestProvider.notifier).reset();
    ref.invalidate(recentFeedProvider);
  }

  void _showKnowledgeSuccess(String message) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => KnowledgeSuccessSheet(
        message: message,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    ).then((_) => _handleClose());
  }

  void _showIngestBottomSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (_) => const _UnifiedIngestBottomSheet(),
    ).then((_) {
      final state = ref.read(ingestProvider);
      if (state.phase == IngestPhase.knowledgeSuccess && state.knowledgeMessage != null) {
        _showKnowledgeSuccess(state.knowledgeMessage!);
      } else if (state.phase != IngestPhase.idle) {
        ref.read(ingestProvider.notifier).reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<IngestState>(ingestProvider, (prev, next) {
      if ((next.phase == IngestPhase.uploading || next.phase == IngestPhase.processing) &&
          (prev == null || prev.phase == IngestPhase.idle)) {
        _showIngestBottomSheet();
      }
      if (next.phase == IngestPhase.error &&
          prev?.phase != IngestPhase.error &&
          next.error != null) {
        if (prev?.phase == IngestPhase.idle) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.translateError(next.error)),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
    return const SizedBox.shrink();
  }
}

// ── Processing overlay ─────────────────────────────────────────────────────────

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay({required this.phase, this.statusMessageKey});

  final IngestPhase phase;
  final String? statusMessageKey;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final step1Status = switch (statusMessageKey) {
      'feedStepGettingUrl' => _StepStatus.active,
      'feedStepUploading' || 'feedStepProcessing' || null => _StepStatus.completed,
      _ => _StepStatus.pending,
    };

    final step2Status = switch (statusMessageKey) {
      'feedStepGettingUrl' => _StepStatus.pending,
      'feedStepUploading' => _StepStatus.active,
      'feedStepProcessing' || null => _StepStatus.completed,
      _ => _StepStatus.pending,
    };

    final step3Status = switch (statusMessageKey) {
      'feedStepProcessing' => _StepStatus.active,
      null => _StepStatus.completed,
      _ => _StepStatus.pending,
    };

    return Container(
      color: Colors.black.withValues(alpha: 0.34),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 48),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(99)),
              ),
              Container(
                width: 72,
                height: 72,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                        color: AmColors.accent.withValues(alpha: 0.18),
                        blurRadius: 20)
                  ],
                ),
                child: Image.asset('assets/logo/logo_t.png',
                    width: 42, height: 42),
              ),
              Text(
                l10n.feedProcessing,
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _StepRow(
                      label: l10n.feedStepGettingUrl,
                      status: step1Status,
                    ),
                    const SizedBox(height: 12),
                    _StepRow(
                      label: l10n.feedStepUploading,
                      status: step2Status,
                    ),
                    const SizedBox(height: 12),
                    _StepRow(
                      label: l10n.feedStepProcessing,
                      status: step3Status,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _StepStatus { pending, active, completed }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.status});
  final String label;
  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget leading() {
      switch (status) {
        case _StepStatus.pending:
          return Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cs.outlineVariant, width: 2),
            ),
          );
        case _StepStatus.active:
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AmColors.accent),
            ),
          );
        case _StepStatus.completed:
          return Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF34A853),
            ),
            child: const Icon(
              Icons.check,
              size: 13,
              color: Colors.white,
            ),
          );
      }
    }

    final textColor = switch (status) {
      _StepStatus.pending => cs.tertiary,
      _StepStatus.active => cs.onSurface,
      _StepStatus.completed => cs.onSurface.withValues(alpha: 0.6),
    };

    final fontWeight = status == _StepStatus.active ? FontWeight.w600 : FontWeight.w500;

    return Row(
      children: [
        leading(),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Unified Ingest Bottom Sheet ──────────────────────────────────────────────────

class _UnifiedIngestBottomSheet extends ConsumerStatefulWidget {
  const _UnifiedIngestBottomSheet();

  @override
  ConsumerState<_UnifiedIngestBottomSheet> createState() => _UnifiedIngestBottomSheetState();
}

class _UnifiedIngestBottomSheetState extends ConsumerState<_UnifiedIngestBottomSheet> {
  @override
  Widget build(BuildContext context) {
    ref.listen<IngestState>(ingestProvider, (prev, next) {
      if (next.phase == IngestPhase.idle || next.phase == IngestPhase.knowledgeSuccess) {
        Navigator.of(context).pop();
      }
    });

    final state = ref.watch(ingestProvider);

    return PopScope(
      canPop: false,
      child: state.phase == IngestPhase.idle
          ? const SizedBox.shrink()
          : _buildContent(context, state),
    );
  }

  Widget _buildContent(BuildContext context, IngestState state) {
    void handleClose() {
      ref.read(ingestProvider.notifier).reset();
    }

    switch (state.phase) {
      case IngestPhase.uploading:
      case IngestPhase.processing:
        return _ProcessingOverlay(
          phase: state.phase,
          statusMessageKey: state.statusMessageKey,
        );
      case IngestPhase.chatting:
        return IngestChatSheet(onClose: handleClose);
      case IngestPhase.success:
        return PolicySuccessSheet(onClose: handleClose);
      case IngestPhase.error:
        return _UnifiedErrorSheet(error: context.translateError(state.error ?? 'Error de procesamiento'), onClose: handleClose);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Unified Error Sheet ─────────────────────────────────────────────────────────

class _UnifiedErrorSheet extends StatelessWidget {
  const _UnifiedErrorSheet({required this.error, required this.onClose});
  final String error;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: Colors.black.withValues(alpha: 0.34),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 48),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Icon(Icons.error_outline, color: cs.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error de procesamiento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                error,
                style: TextStyle(fontSize: 14, color: cs.tertiary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: onClose,
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
