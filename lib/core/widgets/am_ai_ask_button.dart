import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/ai_chat_context.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import 'am_press.dart';

/// Botón sticky de fondo que navega al chat IA con un [AiChatContext]
/// precargado (ej. "Preguntar sobre Juan", "Preguntar sobre este recordatorio").
/// Usar como `bottomNavigationBar` en pantallas de detalle.
class AmAiAskButton extends StatelessWidget {
  const AmAiAskButton({super.key, required this.label, required this.aiContext});

  final String label;
  final AiChatContext aiContext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AmDimens.screenH,
          AmDimens.gapS,
          AmDimens.screenH,
          AmDimens.gapM,
        ),
        child: AmPress(
          onTap: () => GoRouter.of(context).push('/chat', extra: aiContext),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AmDimens.gapM),
            decoration: BoxDecoration(
              color: AmColors.accent,
              borderRadius: BorderRadius.circular(AmDimens.cardRadius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo/logo.png',
                  color: AmColors.onAccent,
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: AmDimens.gapXS),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    color: AmColors.onAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
