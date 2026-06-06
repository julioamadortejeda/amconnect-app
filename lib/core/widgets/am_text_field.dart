import 'package:flutter/material.dart';
import 'package:amconnect/core/theme/app_colors.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: AmColors.cardSunkenLight,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AmColors.lineLight),
      ),
      child: Row(children: [
        const SizedBox(width: 14),
        Icon(icon, color: AmColors.mutedLight, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure,
            onSubmitted: onSubmitted,
            style: const TextStyle(fontSize: 15.5, color: AmColors.inkLight),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(color: AmColors.mutedLight),
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
