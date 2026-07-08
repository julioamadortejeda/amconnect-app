import 'package:flutter/material.dart';

/// Burbuja de texto para el chat de voz turn-based (walkie-talkie) —
/// muestra la transcripción del asesor o la respuesta de la IA de este turno.
class ChatTtsBubble extends StatelessWidget {
  const ChatTtsBubble({super.key, required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF007AC0).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 15, height: 1.45, color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
