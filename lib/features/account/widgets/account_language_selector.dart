import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/account_provider.dart';

class AccountLanguageSelector extends ConsumerWidget {
  const AccountLanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final current = Localizations.localeOf(context).languageCode;

    Widget label(String code, String text) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: current == code ? cs.onSurface : cs.tertiary,
            ),
          ),
        );

    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: current,
        backgroundColor: cs.secondaryContainer,
        thumbColor: cs.surface,
        children: {
          'es': label('es', l10n.languageSpanish),
          'en': label('en', l10n.languageEnglish),
        },
        onValueChanged: (code) {
          if (code != null) ref.read(agentProfileProvider.notifier).setLanguage(code);
        },
      ),
    );
  }
}
