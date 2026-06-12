import 'package:flutter/material.dart';
import '../../../core/widgets/am_press.dart';
import '../../../l10n/app_localizations.dart';

class LoginGuestBtn extends StatelessWidget {
  const LoginGuestBtn({super.key, this.onTap});

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
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.person_outline_rounded, size: 20, color: Colors.white),
          const SizedBox(width: 10),
          Text(l10n.loginGuest,
              style: const TextStyle(
                  fontSize: 15.5, fontWeight: FontWeight.w600, color: Colors.white)),
        ]),
      ),
    );
  }
}
