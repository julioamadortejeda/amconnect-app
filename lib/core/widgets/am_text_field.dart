import 'package:flutter/material.dart';

class AmTextField extends StatelessWidget {
  const AmTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: cs.outline),
      ),
      child: Row(children: [
        const SizedBox(width: 14),
        Icon(icon, color: cs.tertiary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure,
            onSubmitted: onSubmitted,
            style: TextStyle(fontSize: 15.5, color: cs.onSurface),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(color: cs.tertiary),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
        if (suffix != null) suffix!,
      ]),
    );
  }
}
