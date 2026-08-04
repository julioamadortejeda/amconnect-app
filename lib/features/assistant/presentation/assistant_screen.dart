import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/device_timezone.dart';
import '../../../core/utils/error_translator.dart';
import '../../../core/widgets/am_press.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/chat_cards.dart';
import '../../feed/widgets/ingest_type_picker.dart';
import '../providers/assistant_provider.dart';
import '../widgets/assistant_bubble.dart';
import '../widgets/assistant_composer.dart';
import '../widgets/assistant_header.dart';
import '../widgets/assistant_voice_bar.dart';
import '../widgets/voice_output_sheet.dart';

List<String> _assistantSuggestions(AppLocalizations l10n) => [
      l10n.chatSuggestion1,
      l10n.chatSuggestion2,
      l10n.chatSuggestion3,
      l10n.chatSuggestion4,
    ];

/// Pantalla única de asistente IA — texto por default, voz (Gemini Live
/// full-duplex) inline al tocar el botón de onda. Un solo historial, sin
/// distinción visual entre turnos de texto y de voz.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key, this.initialContext, this.resumeArgs});

  final AiChatContext? initialContext;
  final AssistantResumeArgs? resumeArgs;

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _hasText = false;
  late final AssistantNotifier _notifier;
  AssistantMode? _currentMode;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(assistantProvider.notifier);
    if (widget.initialContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _notifier.resetWithContext(widget.initialContext!);
        }
      });
    } else if (widget.resumeArgs != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _notifier.resumeIngestSession(widget.resumeArgs!.sessionId, widget.resumeArgs!.messages);
        }
      });
    }
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    setState(() => _hasText = false);
    _notifier.sendText(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    // Si el usuario sale de la pantalla con la voz activa, hay que cerrar el
    // WebSocket/audio nativo explícitamente. Diferido con Future(): endVoice
    // escribe state del provider, y Riverpod prohíbe modificar providers
    // dentro de dispose (el árbol de widgets se está finalizando).
    if (_currentMode == AssistantMode.voice) {
      final notifier = _notifier; // capturado en initState — no usa ref
      Future(() => notifier.endVoice());
    }
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(assistantProvider);
    _currentMode = state.mode;
    final isVoice = state.mode == AssistantMode.voice;

    ref.listen(assistantProvider, (prev, next) {
      final messagesChanged = prev?.messages.length != next.messages.length;
      final liveChanged = prev?.liveUserText != next.liveUserText ||
          prev?.liveModelText != next.liveModelText;
      if (messagesChanged || liveChanged) _scrollToBottom();
    });

    final showSugg = !isVoice && state.messages.isEmpty && !state.isLoading;

    final trailingItems = <Widget>[];
    if (isVoice) {
      if (state.liveUserText.isNotEmpty) {
        trailingItems.add(AssistantBubble(role: 'user', text: state.liveUserText, isLive: true));
      }
      if (state.liveModelText.isNotEmpty) {
        trailingItems.add(AssistantBubble(role: 'ai', text: state.liveModelText, isLive: true));
      }
      // Card transitoria del skill en vuelo (clientes, pólizas, recordatorios…)
      // — al commitear el turno queda anclada a la burbuja del modelo y esta
      // desaparece (clearActiveWidgetMetadata en el provider).
      if (state.activeWidgetMetadata != null) {
        final card = buildChatCard(state.activeWidgetMetadata!, context);
        if (card != null) trailingItems.add(card);
      }
    } else if (state.isLoading) {
      trailingItems.add(const AssistantTypingBubble());
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && state.mode == AssistantMode.voice) {
          ref.read(assistantProvider.notifier).stopVoice();
        }
      },
      child: Scaffold(
        backgroundColor: am.bg,
        body: SafeArea(
          child: Column(
            children: [
              AssistantHeader(
                mode: state.mode,
                sessionActive: state.sessionId != null,
                activeSkill: state.activeSkill,
                onBack: () {
                  if (state.mode == AssistantMode.voice) {
                    ref.read(assistantProvider.notifier).stopVoice();
                  }
                  context.pop();
                },
                onReset: () => ref.read(assistantProvider.notifier).reset(),
              ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  if (isVoice && state.voiceStatus == VoiceStatus.modelSpeaking) {
                    ref.read(assistantProvider.notifier).interruptVoice();
                  }
                },
                child: ListView.separated(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(
                      AmDimens.screenH, 8, AmDimens.screenH, 16),
                  itemCount: state.messages.length + trailingItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    if (i < state.messages.length) {
                      final msg = state.messages[i];
                      return AssistantBubble(role: msg.role, text: msg.text, metadata: msg.metadata);
                    }
                    return trailingItems[i - state.messages.length];
                  },
                ),
              ),
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AmDimens.screenH, 0, AmDimens.screenH, 8),
                child: GestureDetector(
                  onTap: state.error == 'MIC_PERMISSION_DENIED'
                      ? () => openAppSettings()
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      Icon(Icons.error_outline_rounded,
                          color: cs.onErrorContainer, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.error == 'MIC_PERMISSION_DENIED'
                              ? '${context.translateError(state.error)} · ${l10n.voiceOpenSettingsHint}'
                              : context.translateError(state.error),
                          style: TextStyle(
                              fontSize: 13, color: cs.onErrorContainer),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            if (showSugg)
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(
                      AmDimens.screenH, 0, AmDimens.screenH, 6),
                  children: _assistantSuggestions(l10n)
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: AmPress(
                              onTap: () {
                                _ctrl.text = s;
                                _send();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: cs.surface,
                                  border:
                                      Border.all(color: cs.outlineVariant),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: AmShadows.chip,
                                ),
                                child: Text(s,
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: cs.onSurfaceVariant)),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AmDimens.screenH, 6, AmDimens.screenH, 0),
              child: isVoice
                  ? AssistantVoiceBar(
                      status: state.voiceStatus,
                      activeSkill: state.activeSkill,
                      error: state.error,
                      onClose: () => ref.read(assistantProvider.notifier).endVoice(),
                      onOutput: () => VoiceOutputSheet.show(context),
                      micLevel: ref.read(assistantProvider.notifier).micLevel,
                      modelLevel: ref.read(assistantProvider.notifier).modelLevel,
                    )
                  : AssistantComposer(
                      controller: _ctrl,
                      hasText: _hasText,
                      isLoading: state.isLoading,
                      onChanged: (v) => setState(() => _hasText = v.trim().isNotEmpty),
                      onSend: _send,
                      onAttach: () {
                        final ctx = state.activeContext ?? state.pendingContext;
                        final contactId = ctx?.type == 'contact' ? ctx?.id : null;
                        final policyId = ctx?.type == 'policy' ? ctx?.id : null;
                        final reminderId = ctx?.type == 'reminder' ? ctx?.id : null;
                        IngestTypePicker.show(
                          context,
                          contactId: contactId,
                          policyId: policyId,
                          reminderId: reminderId,
                          // Extraer una póliza nueva no aplica en el contexto
                          // de un recordatorio o póliza ya existente.
                          showPolicyExtraction: reminderId == null && policyId == null,
                        );
                      },
                      onVoiceToggle: () =>
                          ref.read(assistantProvider.notifier).startVoice(DeviceTimezone.name),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
