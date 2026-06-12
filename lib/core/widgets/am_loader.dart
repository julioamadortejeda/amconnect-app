import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class AmLoader extends StatefulWidget {
  const AmLoader({super.key});

  @override
  State<AmLoader> createState() => _AmLoaderState();
}

class _AmLoaderState extends State<AmLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      lowerBound: 0.85,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseCtrl,
              child: Image.asset(
                'assets/logo/logo_t.png',
                width: 64,
                height: 64,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.commonLoading,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
