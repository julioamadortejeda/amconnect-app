import 'package:flutter/material.dart';
import '../../../core/widgets/am_press.dart';
import '../../../l10n/app_localizations.dart';

class LoginEmailBtn extends StatelessWidget {
  const LoginEmailBtn({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AmPress(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF004F8C),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.email_outlined, size: 20, color: Colors.white),
          const SizedBox(width: 10),
          Text(l10n.loginEnterEmail,
              style: const TextStyle(
                  fontSize: 15.5, fontWeight: FontWeight.w600, color: Colors.white)),
        ]),
      ),
    );
  }
}
